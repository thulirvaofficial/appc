class CategoryModel {
  final dynamic id;
  final String name;
  final String displayName;
  final String? description;
  final String? image;
  final String? emoji;
  final int itemCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.image,
    this.emoji,
    this.itemCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? json['display_name'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      emoji: json['emoji'] ?? '🥛',
      itemCount: json['itemCount'] ?? json['item_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'description': description,
      'image': image,
      'emoji': emoji,
      'itemCount': itemCount,
    };
  }
}

