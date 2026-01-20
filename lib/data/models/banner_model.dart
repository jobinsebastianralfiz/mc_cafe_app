/// Banner Model
///
/// Represents a promotional banner from the API.
/// Based on actual API response structure.
class Banner {
  final int id;
  final String title;
  final String? subtitle;
  final String image;
  final String? buttonText;
  final String? buttonLink;

  const Banner({
    required this.id,
    required this.title,
    this.subtitle,
    required this.image,
    this.buttonText,
    this.buttonLink,
  });

  /// Create Banner from JSON
  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      image: json['image'] as String? ?? '',
      buttonText: json['button_text'] as String?,
      buttonLink: json['button_link'] as String?,
    );
  }

  /// Convert Banner to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image': image,
      'button_text': buttonText,
      'button_link': buttonLink,
    };
  }

  /// Check if banner has a button
  bool get hasButton => buttonText != null && buttonText!.isNotEmpty;

  /// Check if banner has a link
  bool get hasLink => buttonLink != null && buttonLink!.isNotEmpty;

  @override
  String toString() => 'Banner(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Banner && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
