/**
 * AI chat for MediTrack — free providers first:
 * 1) Groq (https://console.groq.com) — free tier, fast
 * 2) Google Gemini (https://aistudio.google.com/apikey) — free tier
 * 3) OpenAI (optional paid)
 * 4) Offline template answers
 */
const https = require("https");
const medicineKnowledge = require("../data/medicine_knowledge");

const SYSTEM_PROMPT = `You are MediTrack Assistant, a helpful health companion for a medicine reminder app.
You give general educational information about medicines, adherence, and healthy habits.
You are NOT a doctor. Always remind users to consult a licensed clinician for personal medical decisions.
Keep answers concise (under 180 words), clear, and practical.
If asked about a specific drug, mention typical uses, common side effects, and timing in general terms only.`;

function env(name) {
  return (process.env[name] || "").trim().replace(/^["']|["']$/g, "");
}

function offlineAnswer(message) {
  const m = (message || "").toLowerCase();

  if (m.includes("side effect")) {
    const hit = medicineKnowledge.find(
      (e) =>
        m.includes(e.name.toLowerCase()) ||
        (e.aliases || []).some((a) => m.includes(a.toLowerCase()))
    );
    if (hit) {
      return `${hit.name} — common side effects (general info): ${hit.sideEffects}\n\nThis is not personal medical advice. Talk to your doctor or pharmacist if side effects worry you.`;
    }
    return "Side effects vary by medicine and dose. Check the package leaflet and ask your pharmacist. Seek urgent care for severe allergy symptoms (swelling, trouble breathing).";
  }

  if (m.includes("when") && (m.includes("take") || m.includes("timing"))) {
    return "Timing depends on the drug: some need an empty stomach (e.g. many thyroid meds), some with food (e.g. many NSAIDs or metformin). Follow your prescription label. MediTrack reminders help you stick to the schedule your clinician set.";
  }

  if (m.includes("miss") || m.includes("forgot")) {
    return "If you miss a dose, take it when you remember unless it is almost time for the next dose — then skip the missed one. Do not double up unless your doctor said so. Use MediTrack to mark Taken / Skipped so your adherence history stays accurate.";
  }

  if (m.includes("food") || m.includes("meal") || m.includes("empty stomach")) {
    return "Some medicines absorb better on an empty stomach; others should be taken with food to reduce stomach upset. Your label or pharmacist will say which. When unsure, ask before changing how you take a dose.";
  }

  if (m.includes("water") || m.includes("alcohol")) {
    return "Most tablets should be swallowed with a full glass of water. Alcohol can interact with many drugs (e.g. paracetamol, sedating antihistamines, some antibiotics) — ask your pharmacist for your specific list.";
  }

  if (m.includes("stock") || m.includes("refill") || m.includes("run out")) {
    return "Check the stock count on each medicine in MediTrack. When it is low, refill before you run out so doses are not missed. Align refills with your reminder schedule.";
  }

  if (m.includes("hello") || m.includes("hi ") || m === "hi") {
    return "Hi! I am MediTrack Assistant. Ask about dose timing, missed doses, side effects in general, or pick a quick question below. I am not a substitute for your doctor.";
  }

  const hit = medicineKnowledge.find(
    (e) =>
      m.includes(e.name.toLowerCase()) ||
      (e.aliases || []).some((a) => m.includes(a.toLowerCase()))
  );
  if (hit) {
    return `${hit.name}\n• Uses: ${hit.uses}\n• When to take: ${hit.whenToTake}\n• Side effects: ${hit.sideEffects}\n\nEducational only — confirm with your clinician.`;
  }

  return "I can help with general questions about reminders, missed doses, and medicine labels. For diagnosis or changing treatment, please contact your doctor or pharmacist. Try a template question below or name a medicine.";
}

function httpsJson({ hostname, path, method = "GET", headers = {}, body }) {
  return new Promise((resolve) => {
    const payload = body ? (typeof body === "string" ? body : JSON.stringify(body)) : null;
    const req = https.request(
      {
        hostname,
        path,
        method,
        headers: {
          ...(payload
            ? {
                "Content-Type": "application/json",
                "Content-Length": Buffer.byteLength(payload),
              }
            : {}),
          ...headers,
        },
        timeout: 30000,
      },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          let json = {};
          try {
            json = JSON.parse(data || "{}");
          } catch {
            json = { raw: data };
          }
          resolve({ status: res.statusCode || 0, json, raw: data });
        });
      }
    );
    req.on("error", (e) => resolve({ status: 0, json: { error: e.message }, raw: "" }));
    req.on("timeout", () => {
      req.destroy();
      resolve({ status: 0, json: { error: "timeout" }, raw: "" });
    });
    if (payload) req.write(payload);
    req.end();
  });
}

/** Groq — OpenAI-compatible, free tier: https://console.groq.com/keys */
async function chatGroq(messages) {
  const key = env("GROQ_API_KEY");
  if (!key) return { ok: false, reason: "missing_key" };

  // Try current free-tier models in order (IDs change over time)
  const models = [
    env("GROQ_MODEL"),
    "llama-3.3-70b-versatile",
    "llama-3.1-8b-instant",
    "openai/gpt-oss-20b",
    "qwen/qwen3.8-27b",
    "qwen/qwen3.6-27b",
    "groq/compound-mini",
    "groq/compound",
  ].filter(Boolean);
  // unique preserve order
  const seen = new Set();
  const modelList = models.filter((m) => (seen.has(m) ? false : (seen.add(m), true)));

  let lastFail = null;
  for (const model of modelList) {
    const { status, json } = await httpsJson({
      hostname: "api.groq.com",
      path: "/openai/v1/chat/completions",
      method: "POST",
      headers: { Authorization: `Bearer ${key}` },
      body: {
        model,
        messages,
        temperature: 0.4,
        max_tokens: 500,
      },
    });

    if (status >= 400) {
      const detail = json.error?.message || json.message || `HTTP ${status}`;
      console.error(`[AI] Groq model ${model}:`, status, detail);
      lastFail = { ok: false, reason: "api_error", detail, provider: "groq" };
      // try next model on 404 / model not found
      if (status === 404 || /does not exist|not found|not available/i.test(detail)) {
        continue;
      }
      // rate limit / auth — don't spam other models
      if (status === 401 || status === 403 || status === 429) {
        return lastFail;
      }
      continue;
    }
    const text = json.choices?.[0]?.message?.content;
    if (text && String(text).trim()) {
      console.log(`[AI] Groq success with model ${model}`);
      return { ok: true, text: String(text).trim(), provider: "groq", model };
    }
    lastFail = { ok: false, reason: "empty_response", provider: "groq" };
  }
  return lastFail || { ok: false, reason: "no_model", provider: "groq" };
}

/** Google Gemini free: https://aistudio.google.com/apikey */
async function chatGemini(messages) {
  const key = env("GEMINI_API_KEY") || env("GOOGLE_API_KEY");
  if (!key) return { ok: false, reason: "missing_key" };

  const models = [
    env("GEMINI_MODEL"),
    "gemini-2.5-flash",
    "gemini-3.6-flash",
    "gemini-3.7-flash",
    "gemini-2.0-flash",
    "gemini-flash-latest",
    "gemini-1.5-flash",
  ].filter(Boolean);
  const seen = new Set();
  const modelList = models.filter((m) => (seen.has(m) ? false : (seen.add(m), true)));

  // Flatten chat history for Gemini generateContent
  const contents = [];
  let systemText = "";
  for (const m of messages) {
    if (m.role === "system") {
      systemText += (systemText ? "\n" : "") + m.content;
      continue;
    }
    contents.push({
      role: m.role === "assistant" ? "model" : "user",
      parts: [{ text: m.content }],
    });
  }
  if (contents.length && contents[0].role !== "user") {
    contents.unshift({ role: "user", parts: [{ text: "Hello" }] });
  }

  let lastFail = null;
  for (const model of modelList) {
    const path = `/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(key)}`;
    const body = {
      contents,
      generationConfig: { temperature: 0.4, maxOutputTokens: 500 },
    };
    if (systemText) {
      body.systemInstruction = { parts: [{ text: systemText }] };
    }

    const { status, json } = await httpsJson({
      hostname: "generativelanguage.googleapis.com",
      path,
      method: "POST",
      body,
    });

    if (status >= 400) {
      const detail =
        json.error?.message || json.message || JSON.stringify(json).slice(0, 200);
      console.error(`[AI] Gemini model ${model}:`, status, detail);
      lastFail = { ok: false, reason: "api_error", detail, provider: "gemini" };
      if (status === 404 || /no longer available|not found|not supported/i.test(detail)) {
        continue;
      }
      if (status === 401 || status === 403 || status === 429) {
        return lastFail;
      }
      continue;
    }

    const text =
      json.candidates?.[0]?.content?.parts?.map((p) => p.text).filter(Boolean).join("") ||
      "";
    if (text.trim()) {
      console.log(`[AI] Gemini success with model ${model}`);
      return { ok: true, text: text.trim(), provider: "gemini", model };
    }
    lastFail = {
      ok: false,
      reason: "empty_response",
      provider: "gemini",
      detail: "No text in response",
    };
  }
  return lastFail || { ok: false, reason: "no_model", provider: "gemini" };
}

/** OpenAI optional */
async function chatOpenAI(messages) {
  const key = env("OPENAI_API_KEY") || env("OPEN_AI_API_KEY");
  if (!key) return { ok: false, reason: "missing_key" };

  const model = env("OPENAI_MODEL") || "gpt-4o-mini";
  const { status, json } = await httpsJson({
    hostname: "api.openai.com",
    path: "/v1/chat/completions",
    method: "POST",
    headers: { Authorization: `Bearer ${key}` },
    body: {
      model,
      messages,
      temperature: 0.4,
      max_tokens: 500,
    },
  });

  if (status >= 400) {
    const detail = json.error?.message || json.message || `HTTP ${status}`;
    console.error("[AI] OpenAI error:", status, detail);
    return { ok: false, reason: "api_error", detail, provider: "openai" };
  }
  const text = json.choices?.[0]?.message?.content;
  if (text && String(text).trim()) {
    return { ok: true, text: String(text).trim(), provider: "openai" };
  }
  return { ok: false, reason: "empty_response", provider: "openai" };
}

function activeProviders() {
  const list = [];
  if (env("GROQ_API_KEY")) list.push("groq");
  if (env("GEMINI_API_KEY") || env("GOOGLE_API_KEY")) list.push("gemini");
  if (env("OPENAI_API_KEY") || env("OPEN_AI_API_KEY")) list.push("openai");
  return list;
}

async function chat({ message, history = [] }) {
  const userMsg = (message || "").trim();
  if (!userMsg) {
    return { reply: "Please type a question or choose a template.", source: "local" };
  }

  const messages = [
    { role: "system", content: SYSTEM_PROMPT },
    ...history
      .filter((h) => h && (h.role === "user" || h.role === "assistant") && h.content)
      .slice(-8)
      .map((h) => ({ role: h.role, content: String(h.content).slice(0, 1000) })),
    { role: "user", content: userMsg.slice(0, 1500) },
  ];

  const providers = activeProviders();
  console.log("[AI] Active providers:", providers.length ? providers.join(", ") : "(none — offline)");

  const attempts = [];
  // Prefer free providers first
  if (env("GROQ_API_KEY")) attempts.push(chatGroq);
  if (env("GEMINI_API_KEY") || env("GOOGLE_API_KEY")) attempts.push(chatGemini);
  if (env("OPENAI_API_KEY") || env("OPEN_AI_API_KEY")) attempts.push(chatOpenAI);

  let lastFail = null;
  for (const fn of attempts) {
    const result = await fn(messages);
    if (result.ok) {
      console.log(`[AI] Reply from ${result.provider}`);
      return { reply: result.text, source: result.provider };
    }
    lastFail = result;
  }

  const offline = offlineAnswer(userMsg);
  if (lastFail && lastFail.reason !== "missing_key") {
    return {
      reply: offline,
      source: "local_fallback",
      warning: lastFail.detail || `AI unavailable (${lastFail.reason}). Offline answer shown.`,
    };
  }

  return {
    reply: offline,
    source: "local",
    warning:
      providers.length === 0
        ? "No free AI key set. Add GROQ_API_KEY or GEMINI_API_KEY in backend/.env"
        : undefined,
  };
}

const TEMPLATES = [
  "What should I do if I miss a dose?",
  "When should I take medicine with food?",
  "What are common side effects of Metformin?",
  "How can I improve adherence?",
  "Is it safe to take medicine with alcohol?",
  "How do I know when to refill stock?",
];

function getOpenAiKey() {
  // kept for status endpoint compatibility — true if any live provider is configured
  return activeProviders().length > 0 ? "configured" : "";
}

function getAiStatus() {
  return {
    providers: activeProviders(),
    aiEnabled: activeProviders().length > 0,
    preferred: activeProviders()[0] || "local",
    hint:
      activeProviders().length > 0
        ? `Using: ${activeProviders().join(", ")}`
        : "Set GROQ_API_KEY (free) or GEMINI_API_KEY (free) in backend/.env and restart.",
  };
}

module.exports = { chat, TEMPLATES, getOpenAiKey, getAiStatus, activeProviders };
