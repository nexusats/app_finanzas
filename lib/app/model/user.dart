class User {
  final int? id;
  final String? username;
  final String? firstname;
  final String? lastname;
  final String email;
  final String password;
  final String? address;
  final String? city;
  final String? country;
  final String? postal;
  final String? about;
  final DateTime? emailVerifiedAt;

  User({
    this.id,
    this.username,
    this.firstname,
    this.lastname,
    required this.email,
    required this.password,
    this.address,
    this.city,
    this.country,
    this.postal,
    this.about,
    this.emailVerifiedAt,
  });

  /// **Factory constructor para convertir un JSON a un objeto User**
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email'],
      password: json['password'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      postal: json['postal'],
      about: json['about'],
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
    );
  }

  /// **Método para convertir un objeto User a JSON**
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'password': password,
      'address': address,
      'city': city,
      'country': country,
      'postal': postal,
      'about': about,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
    };
  }
}
