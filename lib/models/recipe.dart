class Recipe {
  final String id;
  final String name;
  final String category;
  final String description;
  final String emoji;
  final String imageUrl;
  final String youtubeUrl;
  final int time;
  final int servings;
  final List<String> ingredients;
  final List<String> steps;
  final bool featured;
  final bool published;

  const Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.emoji,
    required this.imageUrl,
    required this.youtubeUrl,
    required this.time,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.featured,
    required this.published,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'أطباق تقليدية',
      description: json['description']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '🍽️',
      imageUrl: json['image_url']?.toString() ?? '',
      youtubeUrl: json['youtube_url']?.toString() ?? '',
      time: int.tryParse(json['time']?.toString() ?? '') ?? 30,
      servings: int.tryParse(json['servings']?.toString() ?? '') ?? 4,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      featured: json['featured'] == true,
      published: json['published'] == true,
    );
  }
}
