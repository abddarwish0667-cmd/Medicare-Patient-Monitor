class OpenAIConfig {
  static const String apiKey =
      String.fromEnvironment('OPENAI_API_KEY');

  static bool get hasApiKey =>
      apiKey.trim().isNotEmpty;
}