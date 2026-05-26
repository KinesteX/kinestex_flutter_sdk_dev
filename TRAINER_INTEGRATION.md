# AI Trainer Integration (Flutter)

This document describes how to integrate the **AI Personal Trainer** experience using `kinestex_sdk_flutter`. It covers the trainer-specific view, the messages the SDK emits, pre-filling user data, and how to wire up the workout reminder.

## Requirements

- `kinestex_sdk_flutter` **≥ 1.4.7** — adds `createTrainerChatView`, the post-workout check-in, the pre-workout readiness assessment, and the `trainer_schedule_next_workout` reminder event.
- The SDK already installed and camera permission granted in your app. Only trainer-specific concerns are covered below — follow the install steps in [README.md](README.md) first.

## Launching the Trainer

Initialize once at app start, then mount the trainer view with `KinesteXAIFramework.createTrainerChatView`:

```dart
import 'package:flutter/material.dart';
import 'package:kinestex_sdk_flutter/kinestex_sdk.dart';

// Once at app start (e.g. in main()):
await KinesteXAIFramework.initialize(
  apiKey: '<YOUR_API_KEY>',
  companyName: '<YOUR_COMPANY>',
  userId: '<USER_ID>',
);

// Then in your widget tree:
final showKinesteX = ValueNotifier<bool>(true);
final isLoading = ValueNotifier<bool>(false);

KinesteXAIFramework.createTrainerChatView(
  style: IStyle(style: 'dark'),
  isShowKinestex: showKinesteX,
  isLoading: isLoading,
  onMessageReceived: handleWebViewMessage,
);
```

That's the entire mount. The trainer flow (profile setup → readiness assessment → workout → check-in → schedule next session) is handled inside the SDK.

## Pre-filling user data

The trainer asks a sequence of profile questions on first use — age, weight, height, gender, fitness goals, equipment, injuries, etc. You can **skip the basic demographic questions** by passing a `UserDetails` object via the `user:` parameter. The trainer picks them up as the starting profile and only prompts for what's still missing.

The `UserDetails` constructor on this SDK requires **all five fields** to be set — there's no partial form. Pass the full object when you know all of them; otherwise omit `user:` entirely and let the trainer ask for everything.

Fields on `UserDetails`:

| Field | Type | Unit / Allowed values | Notes |
| --- | --- | --- | --- |
| `age` | `int` | years | The user's age. |
| `height` | `double` | **cm** | The trainer UI lets users switch to imperial after. |
| `weight` | `double` | **kg** | Same — imperial conversion happens in the UI. |
| `gender` | `Gender` | `Gender.Male` or `Gender.Female` | |
| `lifestyle` | `Lifestyle` | `Sedentary`, `SlightlyActive`, `Active`, `VeryActive` | Activity level — pick the closest match. |

Example:

```dart
final user = UserDetails(
  age: 32,
  height: 178,            // cm
  weight: 76,              // kg
  gender: Gender.Male,
  lifestyle: Lifestyle.Active,
);

KinesteXAIFramework.createTrainerChatView(
  user: user,
  style: IStyle(style: 'dark'),
  isShowKinestex: showKinesteX,
  isLoading: isLoading,
  onMessageReceived: handleWebViewMessage,
);
```

If you don't have all values, omit `user:` — the trainer will ask. Don't fabricate placeholder values like `0` or `Gender.Unknown`; those will be fed into the profile as-is.

## Handling messages

The trainer emits messages through the `onMessageReceived` callback as typed `WebViewMessage` subclasses. Handle the standard SDK events as you already do, then add the trainer-specific case.

`trainer_schedule_next_workout` is not yet a typed subclass — it arrives as a `CustomType`, so check the `type` field on `message.data`:

```dart
void handleWebViewMessage(WebViewMessage message) {
  if (message is ExitKinestex) {
    // User exited the trainer screen via the back button.
    showKinesteX.value = false;
    return;
  }

  if (message is ErrorOccurred) {
    debugPrint('KinesteX error: ${message.data}');
    return;
  }

  if (message is CustomType) {
    final type = message.data['type'] as String?;

    if (type == 'workout_exit_request') {
      // User exited a workout that was launched from the trainer.
      return;
    }

    if (type == 'trainer_schedule_next_workout') {
      // User picked a date/time for their next session.
      // data: { type, scheduledFor: "YYYY-MM-DDTHH:MM" }
      final scheduledFor = message.data['scheduledFor'] as String?;
      if (scheduledFor != null) {
        scheduleNextWorkoutReminder(scheduledFor);
      }
      return;
    }
  }
}
```

## Reminder integration: `trainer_schedule_next_workout`

After the user finishes a workout, the trainer asks them to pick a date/time for their next session. When the AI generates the next plan, the SDK fires:

```json
{
  "type": "trainer_schedule_next_workout",
  "scheduledFor": "2026-04-29T14:30"
}
```

### Payload semantics

- `scheduledFor` is `YYYY-MM-DDTHH:MM` with **no timezone** — interpret it as the device's local time. In Dart, `DateTime.parse("2026-04-29T14:30")` parses this as local time when no `Z` or offset is present, which is what you want.
- The event is **additive**. Existing integrations that don't listen for it continue to work; users just won't get a reminder.
- It is **not** sent if the user skips scheduling, or if the AI fails to generate the next plan.

### What you must implement

The SDK does **not** schedule the reminder for you. It only tells you when the user wants to be reminded. **It is the host app's responsibility to deliver the reminder.** You have two valid approaches — pick whichever fits your stack:

### Option A — Local scheduled notifications (recommended for most apps)

A local notification scheduled on the device. No backend required, works offline, fires even if the app has been force-quit (the OS persists the schedule).

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4
```

One-time setup at app start:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notifications = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  tz.initializeTimeZones();

  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
}
```

Schedule (or replace) the reminder when the event fires:

```dart
const trainerReminderId = 1001; // stable per-user identifier

Future<void> scheduleNextWorkoutReminder(String scheduledFor) async {
  final date = DateTime.tryParse(scheduledFor);
  if (date == null || date.difference(DateTime.now()).inSeconds < 5) return;

  // Request permission (no-op on Android < 13 / iOS already-granted).
  final iosGranted = await notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true) ??
      true;
  final androidGranted = await notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission() ??
      true;
  if (!iosGranted || !androidGranted) return;

  // Replace any previously scheduled trainer reminder so re-schedules don't stack.
  await notifications.cancel(trainerReminderId);

  await notifications.zonedSchedule(
    trainerReminderId,
    'Time for your workout',
    'Your AI Trainer has your next session ready. Tap to start.',
    tz.TZDateTime.from(date, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'trainer_reminders',
        'Trainer reminders',
        channelDescription: 'Reminders for your next AI Trainer session',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
```

Tapping the notification opens the app automatically — no extra wiring needed. To detect that the app was launched from the reminder (e.g. to navigate to the trainer screen), check `notifications.getNotificationAppLaunchDetails()` at startup and inspect the payload / id.

For exact-time delivery on Android 12+, your app needs the `SCHEDULE_EXACT_ALARM` (or `USE_EXACT_ALARM`) permission in `AndroidManifest.xml`. See the `flutter_local_notifications` README for the exact entries.

### Option B — Server-side push notifications

Send the `scheduledFor` value to your backend and schedule a push for that time using your existing push infrastructure (APNs / FCM via `firebase_messaging`, OneSignal, etc.). Useful if:

- The user has multiple devices and you want the reminder on whichever device they pick up.
- You want server-side reliability (e.g. retry, analytics) instead of trusting the device clock.
- You already deliver other notifications via push.

In this case, your `trainer_schedule_next_workout` handler simply POSTs `{ userId, scheduledFor }` to your backend, which converts `scheduledFor` to UTC (treating it as local time in the user's timezone — store the user's timezone alongside the schedule) and queues a push for that moment.

### Behavior to match either way

Whichever approach you choose, the host app should:

- **Replace the previous reminder** when a new `trainer_schedule_next_workout` arrives. Use a stable identifier (e.g. `1001` per user) and cancel/replace the existing one. Otherwise re-scheduling will stack reminders.
- **Skip past timestamps.** If `scheduledFor` is already in the past (rare, but possible if the user takes a long time to confirm), don't schedule. Some platforms (iOS) silently drop near-past triggers.
- **Request notification permission ahead of time.** Ideally on first launch, so the prompt doesn't appear on top of the trainer UI.

## Quick checklist

- [ ] `kinestex_sdk_flutter` ≥ 1.4.7 installed.
- [ ] `KinesteXAIFramework.initialize(...)` called once at app start.
- [ ] Mount via `KinesteXAIFramework.createTrainerChatView(...)`.
- [ ] Pass a fully populated `UserDetails` (age, height in cm, weight in kg, gender, lifestyle) when known; otherwise omit `user:`.
- [ ] Handle `trainer_schedule_next_workout` in your `onMessageReceived` (via `CustomType`) and schedule a reminder (local or push).
- [ ] Use a stable identifier so re-schedules replace the previous reminder.
- [ ] Notification permission requested early.
