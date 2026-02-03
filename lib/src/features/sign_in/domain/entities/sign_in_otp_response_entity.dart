import 'package:equatable/equatable.dart';

class SignInOTPResponseEntity extends Equatable {
  final String accessToken;
  final String refreshToken;
  final int? userId;
  final int? employeeId;
  final String? msisdn;
  final String? pdvCode;
  final bool? userIsConsent;
  final bool? firstLogin;
  final String? passwordAge; // ISO string (UTC)
  final String? businessName;
  final String? passwordValidityMonths;

  const SignInOTPResponseEntity({
    required this.accessToken,
    required this.refreshToken,
    this.userIsConsent,
    this.firstLogin,
    this.userId,
    this.employeeId,
    this.msisdn,
    this.pdvCode,
    this.passwordAge,
    this.businessName,
    this.passwordValidityMonths = "6",
  });

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        userIsConsent,
        firstLogin,
        userId,
        employeeId,
        msisdn,
        pdvCode,
        passwordAge,
        businessName,
        passwordValidityMonths,
      ];

  factory SignInOTPResponseEntity.fromMap(Map<String, dynamic> map) {
    return SignInOTPResponseEntity(
      accessToken: map['accessToken'] ?? '',
      refreshToken: map['refreshToken'] ?? '',
      userIsConsent: map['userIsConsent'],
      firstLogin: map['first_login'],
      userId: map['userId'],
      employeeId: map['employee'],
      msisdn: map['msisdn'],
      pdvCode: map['pdvCode'],
      passwordAge: map['password_age'],
      passwordValidityMonths: map['password_delay'],
      businessName: map['businessName'],
    );
  }

  // ---------------------------------------------------------------------------
  // Date Helpers
  // ---------------------------------------------------------------------------

  /// Safely adds months to a date (handles month overflow & day clamping)
  DateTime _addMonths(DateTime date, int months) {
    final newMonth = date.month + months;
    final year = date.year + ((newMonth - 1) ~/ 12);
    final month = ((newMonth - 1) % 12) + 1;

    final lastDayOfTargetMonth = DateTime.utc(year, month + 1, 0).day;

    final day = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

    return DateTime.utc(year, month, day);
  }

  // ---------------------------------------------------------------------------
  // Password Expiration Logic
  // ---------------------------------------------------------------------------

  /// Last password change date (UTC)
  DateTime? get lastPasswordChange {
    if (passwordAge == null) return null;
    return DateTime.parse(passwordAge!).toUtc();
  }

  /// Password expiration date (UTC, safe)
  DateTime? get passwordExpirationDate {
    final last = lastPasswordChange;
    if (last == null) return null;

    final months = int.tryParse(passwordValidityMonths ?? '6') ?? 6;
    return _addMonths(last, months);
  }

  /// Days remaining until expiration (date-only, UTC-safe)
  int? get daysUntilExpiration {
    final expiry = passwordExpirationDate;
    if (expiry == null) return null;

    final now = DateTime.now().toUtc();

    final today = DateTime.utc(now.year, now.month, now.day);
    final expiryDateOnly = DateTime.utc(expiry.year, expiry.month, expiry.day);

    return expiryDateOnly.difference(today).inDays;
  }

  // ---------------------------------------------------------------------------
  // Alerts Logic
  // ---------------------------------------------------------------------------

  /// Exactly 15 days before expiration (dismissible toast)
  bool get shouldShow15DaysAlert {
    final days = daysUntilExpiration;
    if (days == null) return false;
    return days == 15;
  }

  /// Password expired (AFTER expiration day)
  bool get isPasswordExpired {
    final days = daysUntilExpiration;
    if (days == null) return false;
    return days < 0;
  }

  /// Inside last week window (7 → 1 days)
  bool get isInLastWeek {
    final days = daysUntilExpiration;
    if (days == null) return false;
    return days <= 7 && days >= 1;
  }

  /// Persistent warning (non-dismissable)
  bool get shouldShowPersistentWarning {
    return isInLastWeek || isPasswordExpired;
  }

  // ---------------------------------------------------------------------------
  // Last Week Range Logic
  // ---------------------------------------------------------------------------

  /// Start date of last week (7 days before expiration)
  DateTime? get lastWeekStartDate {
    final expiry = passwordExpirationDate;
    if (expiry == null) return null;

    return expiry.subtract(const Duration(days: 7));
  }

  /// Are we currently in the last week before expiration?
  bool get isInLastWeekRange {
    final start = lastWeekStartDate;
    final expiry = passwordExpirationDate;
    if (start == null || expiry == null) return false;

    final today = DateTime.now().toUtc();

    /// Inclusive start, exclusive expiry
    return !today.isBefore(start) && today.isBefore(expiry);
  }

  /// Days left until expiration (stable, UTC)
  int? get daysLeftInLastWeek {
    final expiry = passwordExpirationDate;
    if (expiry == null) return null;

    return expiry.difference(DateTime.now().toUtc()).inDays;
  }
}
