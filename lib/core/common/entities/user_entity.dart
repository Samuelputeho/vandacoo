class UserEntity {
  final String name;
  final String propic;
  final String bio;
  final String email;
  final String id;
  final String accountType;
  final String gender;
  final String age;
  final bool hasSeenIntroVideo;
  final List<UserEntity> followers;
  final List<UserEntity> following;
  final String status;

  static final UserEntity empty = UserEntity(
    name: '',
    bio: '',
    email: '',
    id: '',
    accountType: '',
    gender: '',
    age: '',
    propic: '',
    hasSeenIntroVideo: false,
    followers: const [],
    following: const [],
    status: '',
  );

  UserEntity({
    required this.name,
    this.propic = '',
    required this.bio,
    required this.email,
    required this.id,
    this.hasSeenIntroVideo = false,
    required this.accountType,
    required this.gender,
    required this.age,
    this.followers = const [],
    this.following = const [],
    this.status = 'active',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'bio': bio,
        'propic': propic,
        'hasSeenIntroVideo': hasSeenIntroVideo,
        'accountType': accountType,
        'gender': gender,
        'age': age,
        'status': status,
        'followers': followers.map((user) => user.toJson()).toList(),
        'following': following.map((user) => user.toJson()).toList(),
      };
}

// Example JSON representation of a UserEntity:
// {
//   "id": "123",
//   "name": "John Doe", 
//   "email": "john@example.com",
//   "bio": "Software developer",
//   "propic": "https://example.com/profile.jpg",
//   "hasSeenIntroVideo": true,
//   "accountType": "personal",
//   "gender": "male", 
//   "age": "25",
//   "followers": [
//     {
//       "id": "456",
//       "name": "Jane Smith",
//       // ... other follower fields
//     }
//   ],
//   "following": [
//     {
//       "id": "789", 
//       "name": "Bob Wilson",
//       // ... other following fields
//     }
//   ]
// }