import 'package:equatable/equatable.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kronk/constants/enums.dart';

@HiveType(typeId: 1, adapterName: 'UserAdapter')
class UserModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime createdAt;
  @HiveField(2)
  final DateTime updatedAt;
  @HiveField(3)
  final String? name;
  @HiveField(4)
  final String username;
  @HiveField(5)
  final String email;
  @HiveField(8)
  final String? avatarUrl;
  @HiveField(9)
  final String? bannerUrl;
  @HiveField(10)
  final String? bannerColor;
  @HiveField(11)
  final DateTime? birthdate;
  @HiveField(12)
  final String? bio;
  @HiveField(13)
  final String? country;
  @HiveField(14)
  final String? city;
  @HiveField(15)
  final UserRole role;
  @HiveField(16)
  final UserStatus status;
  @HiveField(17)
  final FollowPolicy followPolicy;
  @HiveField(18)
  final int followersCount;
  @HiveField(19)
  final int followingsCount;

  const UserModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bannerUrl,
    this.bannerColor,
    this.birthdate,
    this.bio,
    required this.country,
    required this.city,
    required this.role,
    required this.status,
    required this.followPolicy,
    required this.followersCount,
    required this.followingsCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch((double.tryParse(json['created_at'].toString()) ?? 0 * 1000).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((double.tryParse(json['updated_at'].toString()) ?? 0 * 1000).toInt()),
      name: json['name'],
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      bannerUrl: json['banner_url'],
      bannerColor: json['banner_color'],
      birthdate: json['birthdate'] != null ? DateTime.fromMillisecondsSinceEpoch((double.tryParse(json['birthdate'].toString()) ?? 0 * 1000).toInt()) : null,
      bio: json['bio'],
      country: json['country'],
      city: json['city'],
      role: UserRole.values.byName(json['role']),
      status: UserStatus.values.byName(json['status']),
      followPolicy: FollowPolicy.values.byName(json['follow_policy']),
      followersCount: json['followers_count'],
      followingsCount: json['followings_count'],
    );
  }

  UserModel copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? username,
    String? email,
    dynamic avatarUrl,
    dynamic bannerUrl,
    dynamic bannerColor,
    dynamic birthdate,
    dynamic bio,
    dynamic country,
    dynamic city,
    UserRole? role,
    UserStatus? status,
    FollowPolicy? followPolicy,
    int? followersCount,
    int? followingsCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bannerColor: bannerColor ?? this.bannerColor,
      birthdate: birthdate ?? this.birthdate,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      city: city ?? this.city,
      role: role ?? this.role,
      status: status ?? this.status,
      followPolicy: followPolicy ?? this.followPolicy,
      followersCount: followersCount ?? this.followersCount,
      followingsCount: followingsCount ?? this.followersCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'name': name,
    'username': username,
    'email': email,
    'avatar_url': avatarUrl,
    'banner_url': bannerUrl,
    'banner_color': bannerColor,
    'birthdate': birthdate,
    'bio': bio,
    'country': country,
    'city': city,
    'role': role,
    'status': status,
    'follow_policy': followPolicy,
  };

  @override
  List<Object?> get props => [id, createdAt, updatedAt, name, username, email, avatarUrl, bannerUrl, bannerColor, birthdate, bio, country, city, role, status, followPolicy];
}

class UpdateProfileRequest {
  final String name;
  final String username;
  final String email;
  final String password;
  final String birthdate;
  final String bio;
  final String country;
  final String city;
  final String followPolicy;

  UpdateProfileRequest({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.birthdate,
    required this.bio,
    required this.country,
    required this.city,
    required this.followPolicy,
  });

  Map<String, dynamic> toJson() => {
    // 'first_name': firstName.toJson(),
    // 'last_name': lastName.toJson(),
    // 'username': username.toJson(),
    // 'email': email.toJson(),
    // 'phone_number': phoneNumber.toJson(),
    // 'password': password.toJson(),
    // 'birthdate': birthdate.toJson(),
    // 'bio': bio.toJson(),
    // 'country': country.toJson(),
    // 'city': city.toJson(),
    // 'follow_policy': followPolicy.toJson(),
  };
}

class UserSearchModel {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String username;
  final String email;
  final String password;
  final String role;
  final String status;
  final String followPolicy;
  final int followersCount;
  final int followingsCount;
  final bool isFollowing;

  UserSearchModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.status,
    required this.followPolicy,
    required this.followersCount,
    required this.followingsCount,
    required this.isFollowing,
  });

  factory UserSearchModel.fromJson(Map<String, dynamic> json) {
    return UserSearchModel(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      followPolicy: json['follow_policy'] as String,
      followersCount: int.parse(json['followers_count'].toString()),
      followingsCount: int.parse(json['followings_count'].toString()),
      isFollowing: json['is_following'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'status': status,
      'follow_policy': followPolicy,
      'followers_count': followersCount.toString(),
      'followings_count': followingsCount.toString(),
      'is_following': isFollowing,
    };
  }

  UserSearchModel copyWith({
    String? id,
    String? createdAt,
    String? updatedAt,
    String? username,
    String? email,
    String? password,
    String? role,
    String? status,
    String? followPolicy,
    int? followersCount,
    int? followingsCount,
    bool? isFollowing,
  }) {
    return UserSearchModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      status: status ?? this.status,
      followPolicy: followPolicy ?? this.followPolicy,
      followersCount: followersCount ?? this.followersCount,
      followingsCount: followingsCount ?? this.followingsCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
