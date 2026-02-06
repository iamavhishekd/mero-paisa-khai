import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:paisa_khai/hive/hive_service.dart';
import 'package:paisa_khai/models/transaction.dart';
import 'package:paisa_khai/router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:universal_platform/universal_platform.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    // Default to local, but robustness is key
    // var localLocation = tz.getLocation('Asia/Kathmandu');
    // tz.setLocalLocation(localLocation);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        await appRouter.push('/daily-report');
      },
    );
  }

  Future<void> requestPermissions() async {
    // Android 13+ Notifications & Android 14+ Exact Alarms
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();

      // For Android 13+, check and request exact alarm permission if needed
      final bool isGranted = await Permission.scheduleExactAlarm.isGranted;
      if (!isGranted) {
        try {
          await androidPlugin.requestExactAlarmsPermission();
        } catch (e) {
          print('Error requesting exact alarms permission: $e');
        }
      }
    }

    // iOS Permissions
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // macOS Permissions
    final macosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macosPlugin != null) {
      await macosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async {
    return await _notificationsPlugin.getNotificationAppLaunchDetails();
  }

  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    await _notificationsPlugin
        .cancelAll(); // Clear previous schedules to avoid duplication

    // Schedule for the provided time
    await _scheduleNotification(hour, minute);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Checks if any transaction occurred today.
  bool _hasTransactionToday() {
    final now = DateTime.now();
    final transactions = HiveService.transactionsBoxInstance.values.toList();

    return transactions.any(
      (t) =>
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day,
    );
  }

  double _getTodaySpending() {
    final now = DateTime.now();
    final transactions = HiveService.transactionsBoxInstance.values.toList();

    return transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> _scheduleNotification(int hour, int minute) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // We schedule a daily notification.
    // However, since we want DYNAMIC content (based on *actual* spending that day),
    // a simple repeating notification won't work perfectly for "You spent $X today" unless we use background tasks to update it.
    // simpler sturdy approach:
    // The notification itself asks "How was your spending?"
    // OR we schedule it every time the app opens/pauses to check "today's status".
    //
    // BUT the user asked for: "send notification at the end of the day telling about the todays spending OR if they didnt add anything today remind them"
    // To do this *exactly* locally without a background server fetch is tricky because the content depends on the state *at 8 PM*.
    //
    // Workaround for fully local dynamic content:
    // We can't easily change the *title/body* of a scheduled notification dynamically in the background without WorkManager (Android) or Background Fetch (iOS).
    //
    // Best Approximations:
    // 1. Generic Reminder: "Check your spending for today! Record any missed expenses."
    // 2. Background Fetch: Updates the scheduled notification periodically. (Complex and battery intensive)
    //
    // Given "fully local" instruction usually implies simplicity first:
    // I will implement a generic recurring daily reminder.
    // BUT! Since I am an advanced agent, I'll add a check:
    // When the user *adds a transaction*, I will canceling and *re-scheduling* today's notification
    // to update its content to "You've spent $X today" if it hasn't fired yet.

    // Base Notification details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'daily_spending_reminder',
          'Daily Spending Reminder',
          channelDescription: 'Reminds you to record daily expenses',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Since we can't execute logic *at* the time of notification delivery deeply in BG without plugins,
    // We will schedule a standard reminder.
    //
    // However, I will expose a method `updateDailyNotificationContent` that the App calls whenever a transaction is added.

    // For standard reminders, inexact is battery-friendly and doesn't require special permissions.
    // We check if we have permission for exact, otherwise fallback to inexact.
    bool canScheduleExact = false;
    if (UniversalPlatform.isAndroid) {
      canScheduleExact = await Permission.scheduleExactAlarm.isGranted;
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id: 0,
        title: 'Daily Spending Check',
        body: 'Don\'t forget to record your expenses for today!',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Final fallback to inexact if permission check was somehow inaccurate
      await _notificationsPlugin.zonedSchedule(
        id: 0,
        title: 'Daily Spending Check',
        body: 'Don\'t forget to record your expenses for today!',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Call this whenever a transaction is added/updated to refine the message for *today*
  Future<void> updateDailyNotificationContent() async {
    final box = HiveService.settingsBoxInstance;
    final enabled =
        box.get('notifications_enabled', defaultValue: true) as bool;

    if (!enabled) return;

    final hour = box.get('notification_hour', defaultValue: 20) as int;
    final minute = box.get('notification_minute', defaultValue: 0) as int;

    // 1. Cancel today's generic schedule (ID 0)
    await _notificationsPlugin.cancel(id: 0);

    // 2. Determine content
    final hasTx = _hasTransactionToday();
    String title = 'Daily Spending Check';
    String body = 'Don\'t forget to record your expenses for today!';

    if (hasTx) {
      final spent = _getTodaySpending();
      title = 'Daily Summary';
      body = 'You spent \$${spent.toStringAsFixed(2)} today. Keep it up!';
    }

    // 3. Re-schedule for TODAY's preferred time (or tomorrow if passed)
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If preferred time passed, this update is for tomorrow.
    if (now.isAfter(scheduledDate)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      // Reset to generic for tomorrow
      title = 'Daily Spending Check';
      body = 'Don\'t forget to record your expenses for today!';
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_spending_reminder',
          'Daily Spending Reminder',
          channelDescription: 'Reminds you to record daily expenses',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Same fallback logic here
    bool canScheduleExact = false;
    if (UniversalPlatform.isAndroid) {
      canScheduleExact = await Permission.scheduleExactAlarm.isGranted;
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id: 0,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      await _notificationsPlugin.zonedSchedule(
        id: 0,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
