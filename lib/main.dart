
import 'package:flutter/foundation.dart';

//時間になったらバックグラウンドで音楽を鳴らすため
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

//時間になったらローカル通知を出すため
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//音楽を慣らす
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
//MethodChannel
import 'package:flutter/services.dart';
//BehaviorSubject
import 'package:rxdart/subjects.dart';
//ローカル通知の時間をセットするため
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
//kzWeb?
import 'package:flutter/material.dart';

//Linux?
import 'dart:io';

//アラーム用のID
const int alarmID = 123456789;
//鳴らしたい秒数
const int alramSecond = 5;

//通知のための初期化
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
String? selectedNotificationPayload;

final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String?> selectNotificationSubject =
BehaviorSubject<String?>();
const MethodChannel platform =
MethodChannel('dexterx.dev/flutter_local_notifications_example');

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });
  final int id;
  final String? title;
  final String? body;
  final String? payload;
}
Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}
Future<void> main() async{
  //アラームのための初期化
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();

  //タイムゾーン初期化
  await _configureLocalTimeZone();

  //通知のための初期化

  final NotificationAppLaunchDetails? notificationAppLaunchDetails = !kIsWeb &&
      Platform.isLinux
      ? null
      : await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    selectedNotificationPayload = notificationAppLaunchDetails!.payload;
  }
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String? payload) async {
        if (payload != null) {
          debugPrint('notification payload: $payload');
        }
        selectedNotificationPayload = payload;
        selectNotificationSubject.add(payload);
      });

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo BackGround Play Sound Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'BackGround Play Sound Demo'),
    );
  }
}
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @pragma('vm:entry-point')
  static Future<void> callSoundStart() async {
    //音楽再生
    FlutterRingtonePlayer.playRingtone(looping: true);
  }
  //アラーム・通知セット
  Future<void> setBackgroundAlarm() async {
    //アラームセット
    await AndroidAlarmManager.oneShot(
     const Duration(seconds: alramSecond),
      alarmID,
      callSoundStart,
      alarmClock: true,
      allowWhileIdle: true,
      exact: true,
      wakeup: true,
    );
    //通知セット
    await flutterLocalNotificationsPlugin.zonedSchedule(
        alarmID,
        '通知テストタイトル',
        '通知テスト本文',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: alramSecond)),
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'full screen channel id', 'full screen channel name',
                channelDescription: 'full screen channel description',
                priority: Priority.high,
                playSound:false,
                importance: Importance.high,
                fullScreenIntent: true)),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime);
  }
  //アラーム・通知を止める
   stopBackgroundArlam() async {
     //アラームを止める
     await AndroidAlarmManager.oneShot(
         const Duration(seconds: 0), alarmID, stopSound,
         exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);
     //通知を止める
     await flutterLocalNotificationsPlugin.cancel(alarmID);
   }
  @pragma('vm:entry-point')
  static stopSound() async {
    FlutterRingtonePlayer.stop();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("バックグラウンド再生"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed:() async {
                setBackgroundAlarm();
              },
              child: const Text("5秒後に音楽再生"),
            ),
            ElevatedButton(
              onPressed:() async {
                stopBackgroundArlam();
              },
              child: const Text("音楽停止"),
            ),
          ],
        ),
      ),
  );
  }
}
