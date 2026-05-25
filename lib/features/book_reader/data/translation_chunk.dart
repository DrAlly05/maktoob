class TranslationChunk {
  final String id;
  final String originalText;
  final String translatedText;
  final String timestamp;

  TranslationChunk({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
  });

  factory TranslationChunk.fromJson(Map<String, dynamic> json) {
    return TranslationChunk(
      id: json['id'] as String,
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'timestamp': timestamp,
    };
  }
}
