class OpenAIConfig {
  static const String apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static bool get hasApiKey => apiKey.trim().isNotEmpty;
}