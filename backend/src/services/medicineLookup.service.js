/**
 * External medicine lookup: RxNorm (NLM) + OpenFDA labels, with local knowledge fallback.
 */
const https = require("https");
const medicineKnowledge = require("../data/medicine_knowledge");

function fetchJson(url, timeoutMs = 10000) {
  return new Promise((resolve, reject) => {
    const req = https.get(
      url,
      {
        headers: {
          Accept: "application/json",
          "User-Agent": "MediTrack/1.0 (medicine-reminder-app)",
        },
        timeout: timeoutMs,
      },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          try {
            resolve({ status: res.statusCode, body: JSON.parse(data || "{}") });
          } catch (e) {
            reject(e);
          }
        });
      }
    );
    req.on("error", reject);
    req.on("timeout", () => {
      req.destroy();
      reject(new Error("Request timed out"));
    });
  });
}

function scoreLocal(entry, q) {
  const query = q.toLowerCase().trim();
  const name = entry.name.toLowerCase();
  if (name === query) return 100;
  if (name.startsWith(query)) return 90;
  if (name.includes(query)) return 70;
  for (const a of entry.aliases || []) {
    const al = a.toLowerCase();
    if (al === query) return 95;
    if (al.startsWith(query)) return 85;
    if (al.includes(query) || query.includes(al)) return 60;
  }
  return 0;
}

async function rxNormSuggest(q) {
  const url = `https://rxnav.nlm.nih.gov/REST/approximateTerm.json?term=${encodeURIComponent(
    q
  )}&maxEntries=10`;
  const { body } = await fetchJson(url);
  const candidates = body?.approximateGroup?.candidate || [];
  const names = [];
  const seen = new Set();
  for (const c of candidates) {
    const name = (c.name || "").trim();
    if (!name) continue;
    const key = name.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    names.push({
      name,
      rxcui: c.rxcui,
      dosage: "",
      form: "tablet",
      frequency: "Once a day",
      source: "rxnorm",
    });
  }
  return names.slice(0, 8);
}

async function openFdaSuggest(q) {
  const search = `openfda.brand_name:${q}+OR+openfda.generic_name:${q}`;
  const url = `https://api.fda.gov/drug/label.json?search=${encodeURIComponent(
    search
  )}&limit=8`;
  try {
    const { status, body } = await fetchJson(url);
    if (status !== 200 || !body.results) return [];
    const out = [];
    const seen = new Set();
    for (const r of body.results) {
      const brand = r.openfda?.brand_name?.[0];
      const generic = r.openfda?.generic_name?.[0];
      const name = brand || generic;
      if (!name) continue;
      const key = name.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      const form = (r.openfda?.product_type?.[0] || "tablet").toLowerCase();
      out.push({
        name,
        dosage: "",
        form: form.includes("inject")
          ? "injection"
          : form.includes("liquid")
            ? "syrup"
            : "tablet",
        frequency: "Once a day",
        source: "openfda",
      });
    }
    return out;
  } catch {
    return [];
  }
}

function localSuggest(q) {
  return medicineKnowledge
    .map((entry) => ({ entry, score: scoreLocal(entry, q) }))
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 8)
    .map(({ entry }) => ({
      name: entry.name,
      dosage: entry.dosage,
      form: entry.form,
      frequency: entry.frequency,
      source: "local",
    }));
}

/**
 * Merge external + local suggestions, prefer unique names.
 */
async function suggestMedicines(q) {
  const query = (q || "").trim();
  if (query.length < 1) return [];

  const [rx, fda, local] = await Promise.all([
    rxNormSuggest(query).catch(() => []),
    openFdaSuggest(query).catch(() => []),
    Promise.resolve(localSuggest(query)),
  ]);

  const merged = [];
  const seen = new Set();
  // Local first (has richer dosage defaults), then external
  for (const item of [...local, ...rx, ...fda]) {
    const key = item.name.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    merged.push(item);
    if (merged.length >= 10) break;
  }
  return merged;
}

function pickOpenFdaField(arr) {
  if (!Array.isArray(arr) || !arr.length) return "";
  const text = String(arr[0]);
  // Cap length for mobile UI
  return text.length > 600 ? text.slice(0, 600) + "…" : text;
}

async function openFdaInfo(name) {
  // Try exact brand, then generic, then loose contains
  const q = name.replace(/"/g, "").trim();
  const attempts = [
    `openfda.brand_name:"${q}"`,
    `openfda.generic_name:"${q}"`,
    `openfda.brand_name:${q}+OR+openfda.generic_name:${q}`,
  ];
  let body = null;
  for (const search of attempts) {
    const url = `https://api.fda.gov/drug/label.json?search=${encodeURIComponent(search)}&limit=1`;
    try {
      const res = await fetchJson(url);
      if (res.status === 200 && res.body?.results?.length) {
        body = res.body;
        break;
      }
    } catch (e) {
      console.warn("OpenFDA attempt failed:", e.message);
    }
  }
  if (!body) return null;
  // shim to keep rest of function working
  const status = 200;

  if (!body.results?.length) return null;
  const r = body.results[0];
  const brand = r.openfda?.brand_name?.[0];
  const generic = r.openfda?.generic_name?.[0];
  const displayName = brand || generic || name;
  const route = r.openfda?.route?.[0] || "";
  const formRaw = (r.openfda?.product_type?.[0] || "tablet").toLowerCase();
  let form = "tablet";
  if (formRaw.includes("inject")) form = "injection";
  else if (route.toLowerCase().includes("oral") && formRaw.includes("liquid"))
    form = "syrup";
  else if (formRaw.includes("capsule")) form = "capsule";

  const uses =
    pickOpenFdaField(r.indications_and_usage) ||
    pickOpenFdaField(r.purpose) ||
    "";
  const sideEffects =
    pickOpenFdaField(r.adverse_reactions) ||
    pickOpenFdaField(r.warnings) ||
    pickOpenFdaField(r.warnings_and_cautions) ||
    "";
  const whenToTake =
    pickOpenFdaField(r.dosage_and_administration) ||
    "Follow your prescription or package label for timing with meals.";
  const precautions =
    pickOpenFdaField(r.precautions) ||
    pickOpenFdaField(r.contraindications) ||
    "";
  const instructions = pickOpenFdaField(r.dosage_and_administration) || "";

  return {
    name: displayName,
    found: true,
    dosage: "",
    form,
    frequency: "Once a day",
    times: [{ hour: 9, minute: 0 }],
    uses: uses || "See package label or ask your pharmacist.",
    sideEffects: sideEffects || "See warnings on the package label.",
    whenToTake,
    instructions: instructions.slice(0, 300),
    precautions: precautions || "This is not a substitute for medical advice.",
    source: "openfda",
  };
}

function localInfo(name) {
  const scored = medicineKnowledge
    .map((entry) => ({ entry, score: scoreLocal(entry, name) }))
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score);
  if (!scored.length) return null;
  const entry = scored[0].entry;
  return {
    name: entry.name,
    found: true,
    dosage: entry.dosage,
    form: entry.form,
    frequency: entry.frequency,
    times: entry.times,
    uses: entry.uses,
    sideEffects: entry.sideEffects,
    whenToTake: entry.whenToTake,
    instructions: entry.instructions,
    precautions: entry.precautions,
    source: "local",
  };
}

async function getMedicineInfo(name) {
  const q = (name || "").trim();
  if (!q) return null;

  const local = localInfo(q);
  const topScore = medicineKnowledge
    .map((e) => scoreLocal(e, q))
    .sort((a, b) => b - a)[0] || 0;

  // Exact local name match → rich structured defaults
  const exactLocal =
    local &&
    local.name &&
    local.name.toLowerCase() === q.toLowerCase();

  // Always try OpenFDA for brand names / external suggestions
  let fda = null;
  try {
    fda = await openFdaInfo(q);
  } catch (e) {
    console.warn("OpenFDA info failed:", e.message);
  }

  if (fda) {
    // Keep the name the user selected (e.g. Tylenol) when FDA returns a brand
    if (!fda.name) fda.name = q;
    // Fill dosage/schedule gaps from local knowledge when related
    if (local) {
      if (!fda.dosage && local.dosage) fda.dosage = local.dosage;
      if (local.frequency) fda.frequency = local.frequency;
      if (local.times) fda.times = local.times;
      if (!fda.instructions && local.instructions) {
        fda.instructions = local.instructions;
      }
    }
    fda.found = true;
    return fda;
  }

  // Strong local match only if OpenFDA had nothing
  if (local && (exactLocal || topScore >= 85)) {
    return local;
  }
  if (local) return local;

  return {
    name: q,
    found: false,
    dosage: "",
    form: "tablet",
    frequency: "Once a day",
    times: [{ hour: 9, minute: 0 }],
    uses: "No detailed label found online. Confirm uses with your doctor or pharmacist.",
    sideEffects: "Unknown for this entry. Read the package leaflet.",
    whenToTake: "Follow your prescription label for timing with meals.",
    instructions: "",
    precautions: "This app does not replace medical advice.",
    source: "none",
  };
}

module.exports = {
  suggestMedicines,
  getMedicineInfo,
};
