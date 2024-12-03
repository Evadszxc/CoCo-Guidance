class Profile {
  final String userId;
  final String name;
  final String? profession;

  Profile({
    required this.userId,
    required this.name,
    this.profession,
  });

// Extract firstname and lastname as getters from the name field
  String get firstname => name.split(' ').first;
  String get lastname => name.split(' ').last;

// Factory constructor for student profiles
  factory Profile.fromStudentMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['user_id'],
      name: '${map['firstname']} ${map['lastname']}',
    );
  }

// Factory constructor for guidance counselor profiles
  factory Profile.fromGuidanceMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['user_id'],
      name: '${map['firstname']} ${map['lastname']}',
      profession: map['profession'],
    );
  }
}




// The getter 'firstname' isn't defined for the type 'Profile'.
// Try importing the library that defines 'firstname', correcting the name to the name of an existing getter, or defining a getter or field named 'firstname'.dartundefined_getter

// The getter 'lastname' isn't defined for the type 'Profile'.
// Try importing the library that defines 'lastname', correcting the name to the name of an existing getter, or defining a getter or field named 'lastname'.dartundefined_getter

// The getter 'profession' isn't defined for the type 'Profile'.
// Try importing the library that defines 'profession', correcting the name to the name of an existing getter, or defining a getter or field named 'profession'.dartundefined_getter