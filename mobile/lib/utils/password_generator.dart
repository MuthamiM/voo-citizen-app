import 'dart:math';

/// Generates cryptographically secure strong passwords
class PasswordGenerator {
  static const String _uppercase = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const String _lowercase = 'abcdefghjkmnpqrstuvwxyz';
  static const String _numbers = '23456789';
  static const String _special = '@#\$%&*!';

  /// Generates a strong password with specified length (default 12)
  /// Ensures at least one uppercase, lowercase, number, and special character
  static String generate({int length = 12}) {
    final random = Random.secure();
    final allChars = _uppercase + _lowercase + _numbers + _special;
    
    // Ensure we have at least one of each required type
    final password = <String>[
      _uppercase[random.nextInt(_uppercase.length)],
      _lowercase[random.nextInt(_lowercase.length)],
      _numbers[random.nextInt(_numbers.length)],
      _special[random.nextInt(_special.length)],
    ];
    
    // Fill the rest randomly
    for (int i = 4; i < length; i++) {
      password.add(allChars[random.nextInt(allChars.length)]);
    }
    
    // Shuffle to randomize position
    password.shuffle(random);
    
    return password.join();
  }
}
