class UserEntity {
  final String id;
  final String email;
  final String? name;
  final String? token;
  final bool isEmailVerified;
  final bool isKycVerified;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.token,
    this.isEmailVerified = false,
    this.isKycVerified = false,
  });
}
