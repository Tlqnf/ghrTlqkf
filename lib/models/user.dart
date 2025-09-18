class User {
  final int id;
  final String email;
  final String username;
  final String profileDescription;
  final String profilePic;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.profileDescription,
    required this.profilePic,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      profileDescription: json['profile_description'],
      profilePic: json['profile_pic'],
    );
  }
}
