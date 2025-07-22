class Category {
  final String id;
  final String name;
  final String? color;

  Category({required this.id, required this.name, this.color});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        color: json['color'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
      };
} 