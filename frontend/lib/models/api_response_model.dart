class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJson(json['data']) : null,
      errors: json['errors'],
    );
  }

  factory ApiResponse.fromJsonList(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    final data = json['data'];
    final list = data is List ? data.map((e) => fromJson(e)).toList() : null;
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: list as T?,
      errors: json['errors'],
    );
  }
}