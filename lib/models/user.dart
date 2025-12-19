class User {
  final String email;
  final String name;
  final int childrenCount;
  final List<Map<String, String>>? children;

  User({
    required this.email,
    required this.name,
    this.childrenCount = 0,
    this.children,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'childrenCount': childrenCount,
      'children': children,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      name: json['name'],
      childrenCount: json['childrenCount'] ?? 0,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList(),
    );
  }
}