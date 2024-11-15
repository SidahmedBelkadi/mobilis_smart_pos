import 'package:equatable/equatable.dart';

class PasswordAge extends Equatable {
  final int years;
  final int months;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  const PasswordAge({
    required this.years,
    required this.months,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  @override
  List<Object?> get props => [years, months, days, hours, minutes, seconds];

  @override
  String toString() {
    return 'PasswordAge(years: $years, months: $months, days: $days, hours: $hours, minutes: $minutes, seconds: $seconds)';
  }

  Map<String, dynamic> toMap() {
    return {
      'years': years,
      'months': months,
      'days': days,
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
    };
  }

  factory PasswordAge.fromMap(Map<String, dynamic> map) {
    return PasswordAge(
      years: map['years'] ?? 0,
      months: map['months'] ?? 0,
      days: map['days'] ?? 0,
      hours: map['hours'] ?? 0,
      minutes: map['minutes'] ?? 0,
      seconds: map['seconds'] ?? 0,
    );
  }
}
