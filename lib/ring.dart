import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:medicine_tracker/language/language.dart';

class ExampleAlarmRingScreen extends StatelessWidget {
  const ExampleAlarmRingScreen({required this.alarmSettings, super.key});

  final AlarmSettings alarmSettings;

  void stopAlarm(AlarmSettings alarmSettings) {
    // Alarm.stop(widget.alarmSettings!.id).then((res) {
    //   if (res) Navigator.pop(context, {'alarmId': null, 'success': true});
    // });
    DateTime newdDateTime = alarmSettings.dateTime.add(const Duration(days: 1));
    final newalarmSettings = AlarmSettings(
      id: alarmSettings.id,
      dateTime: newdDateTime,
      loopAudio: alarmSettings.loopAudio,
      vibrate: alarmSettings.vibrate,
      volume: alarmSettings.volume,
      assetAudioPath: alarmSettings.assetAudioPath,
      notificationTitle: alarmSettings.notificationTitle,
      notificationBody: alarmSettings.notificationBody,
      enableNotificationOnKill: alarmSettings.enableNotificationOnKill,
    );
    Alarm.stop(alarmSettings.id).then((bool result) {
      return Alarm.set(alarmSettings: newalarmSettings);
    });

    // Alarm.set(alarmSettings: newalarmSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              alarmSettings.notificationBody,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text('🔔', style: TextStyle(fontSize: 50)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                RawMaterialButton(
                  onPressed: () {
                    stopAlarm(alarmSettings);
                    Navigator.pop(context);
                  },
                  child: Text(
                    Languages.of(context)!.stop,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
