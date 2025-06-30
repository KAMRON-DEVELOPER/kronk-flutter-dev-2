import 'package:flutter/material.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/constants/kronk_icon.dart';

extension ValidatorExtension on String {
  String? get isValidUsername {
    final nameRegExp = RegExp(r'^[A-Za-z][A-Za-z0-9_]{4,19}$');
    if (isEmpty) {
      return null;
    } else if (!nameRegExp.hasMatch(this)) {
      return 'Username is incorrect';
    }
    return null;
  }

  String? get isValidPassword {
    final passwordRegExp = RegExp(r'^(?!.*(?:012|123|234|345|456|567|678|789|890))(?=.*[A-Za-z0-9]).{6,20}$');
    if (isEmpty) {
      return null;
    } else if (!passwordRegExp.hasMatch(this)) {
      return 'Password is incorrect';
    }
    return null;
  }

  String? get isValidEmail {
    final regex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+$');
    if (isEmpty) {
      return null;
    } else if (!regex.hasMatch(this)) {
      return 'Email is incorrect. Please enter a valid email address.';
    }
    return null;
  }

  String? get isValidCode {
    if (isEmpty) {
      return 'Please, fill the code field';
    } else if (length < 4) {
      return 'Too short. The code should contain 4 digits.';
    } else if (length > 4) {
      return 'Too long. The code should contain 4 digits.';
    } else {
      return null;
    }
  }
}

extension ImageExtension on num {
  int cacheSize(BuildContext context) {
    return (this * MediaQuery.of(context).devicePixelRatio).round();
  }

  double doubleCacheSize(BuildContext context) {
    return (this * MediaQuery.of(context).devicePixelRatio).floorToDouble();
  }
}

extension ColorExtention on String {
  Color fromHex() {
    final buffer = StringBuffer();
    if (length == 6 || length == 7) buffer.write('ff');
    buffer.write(replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

extension VerifyTypeExtension on String {
  bool get isEmail {
    final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(this);
  }
}

extension FeedVisibilityExtension on FeedVisibility {
  String get value {
    switch (this) {
      case FeedVisibility.public:
        return 'public';
      case FeedVisibility.followers:
        return 'followers';
      case FeedVisibility.private:
        return 'private';
      case FeedVisibility.archived:
        return 'archived';
    }
  }
}

extension FollowPolicyExtension on FollowPolicy {
  String get value {
    switch (this) {
      case FollowPolicy.autoAccept:
        return 'auto_accept';
      case FollowPolicy.manualApproval:
        return 'manual_approval';
    }
  }

  set some(String str) {}
}

extension FollowStatusExtension on FollowStatus {
  String get value {
    switch (this) {
      case FollowStatus.pending:
        return 'pending';
      case FollowStatus.accepted:
        return 'accepted';
      case FollowStatus.declined:
        return 'declined';
    }
  }
}

extension ReportReasonExtension on ReportReason {
  String get value {
    switch (this) {
      case ReportReason.intellectualProperty:
        return 'intellectual_property';
      case ReportReason.spam:
        return 'spam';
      case ReportReason.inappropriate:
        return 'inappropriate';
      case ReportReason.misinformation:
        return 'misinformation';
      case ReportReason.harassment:
        return 'harassment';
      case ReportReason.hateSpeech:
        return 'hate_speech';
      case ReportReason.violence:
        return 'violence';
      case ReportReason.other:
        return 'other';
    }
  }
}

extension ProcessStatusExtension on ProcessStatus {
  String get value {
    switch (this) {
      case ProcessStatus.pending:
        return 'pending';
      case ProcessStatus.processed:
        return 'processed';
      case ProcessStatus.failed:
        return 'failed';
    }
  }
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.regular:
        return 'regular';
    }
  }
}

extension UserStatusExtension on UserStatus {
  String get value {
    switch (this) {
      case UserStatus.active:
        return 'active';
      case UserStatus.inactive:
        return 'inactive';
    }
  }
}

extension WeekdayExtension on int {
  String get weekdayName {
    List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[this - 1];
  }
}

extension MonthExtension on int {
  String get monthName {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[this - 1];
  }
}

extension CountNormalizer on int {
  String get normalize {
    final bool isWithinRange100 = compareTo(100) == 0 || compareTo(100) < 0;
    final bool isWithinRange1k = compareTo(1000) == 0 || compareTo(1000) < 0;
    return isWithinRange100 ? toString() : (isWithinRange1k ? '+${this ~/ 1000}k' : '+${this ~/ 10000}k');
  }
}

extension TitleCaseWithSpaces on String {
  String toTitleCaseWithSpaces() {
    return split('_').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }
}

extension CamelCaseConversion on String {
  String toSnakeCase() {
    return replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (match) => '${match.group(1)}_${match.group(2)}').toLowerCase();
  }
}

extension IconColorExtension on IconData {
  Color get appropriateColor {
    if (this == KronkIcon.repeat6) return Colors.green;
    if (this == KronkIcon.heartOutline) return Colors.redAccent;
    if (this == KronkIcon.bookmarkOutline5) return Colors.orangeAccent;
    return Colors.deepPurpleAccent;
  }
}
