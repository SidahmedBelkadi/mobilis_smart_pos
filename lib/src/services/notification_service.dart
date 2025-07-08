import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final onClickNotification = BehaviorSubject<String>();

  // on tap on any notification
  static void onNotificationTap(NotificationResponse notificationResponse) {
    onClickNotification.add(notificationResponse.payload!);
  }

  // initialize the local notifications
  static Future init() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Get the current time zone from the device
    String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Continue with the rest of your initialization code...
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) {},
    );
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux);

    // request notification permissions
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
        .requestNotificationsPermission();

    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );
  }

  static Future showVersionUpdateNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
        2,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1)),
        const NotificationDetails(
            android: AndroidNotificationDetails('app_version_update', 'App Version update',
                channelDescription: 'Notifier to update the app',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker')),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload);
  }

  static tz.TZDateTime calculateExpiryDate(Map<String, dynamic> passwordAge) {
    final now = tz.TZDateTime.now(tz.local);

    // Extract the age components from the response
    int years = passwordAge['years'];
    int months = passwordAge['months'];
    int days = passwordAge['days'];
    int hours = passwordAge['hours'];
    int minutes = passwordAge['minutes'];
    int seconds = passwordAge['seconds'];

    // Calculate the last password change date by subtracting the age components from 'now'
    final lastPasswordChange = now.subtract(Duration(
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    ));

    // Adjust the last password change for years and months
    final lastPasswordChangeAdjusted = tz.TZDateTime(
      tz.local,
      lastPasswordChange.year - years,
      lastPasswordChange.month - months,
      lastPasswordChange.day,
      lastPasswordChange.hour,
      lastPasswordChange.minute,
      lastPasswordChange.second,
    );

    final expiryDate = lastPasswordChangeAdjusted.add(const Duration(days: 180));
    debugPrint("################### Expiry Date: $expiryDate");
    return expiryDate;
  }

  static tz.TZDateTime calculateNotificationDate(tz.TZDateTime expiryDate) {
    debugPrint(
        "################### Notification : ${expiryDate.subtract(const Duration(days: 15))}");

    return expiryDate.subtract(const Duration(days: 15));
  }

  static Future<void> schedulePasswordExpiryNotification(
      DateTime notificationDate, String title, String body) async {
    // Check if the notificationDate is in the future
    if (notificationDate.isBefore(DateTime.now())) {
      return; // Exit early if the date is not in the future
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.from(notificationDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'password_change_channel',
          'Password Change Reminder',
          channelDescription: 'Reminder to change your password',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'Password change reminder',
    );
  }

  // close all the notifications available
  static Future cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
