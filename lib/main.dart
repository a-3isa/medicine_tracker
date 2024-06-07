import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import the date_symbol_data_local library
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medicine_tracker/handler.dart';
import 'package:medicine_tracker/language/language.dart';
import 'package:medicine_tracker/localization/delegation.dart';
import 'package:medicine_tracker/localization/constant.dart';
import 'package:flutter/material.dart';
import 'package:medicine_tracker/model/language_model.dart';
import 'package:medicine_tracker/personal_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background/flutter_background.dart';



void main() async {
  
  await initializeDateFormatting('ar'); // Initialize Arabic locale data
  WidgetsFlutterBinding.ensureInitialized();
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Background Service",
    notificationText: "Your app is running in the background",
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(name: 'background_icon', defType: 'drawable'),
  );

  bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
  if (success) {
    await FlutterBackground.enableBackgroundExecution();
  }
  
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Alarm.init();
  runApp(const MedicineTableApp());
}


class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  _LanguageSelectionPageState createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  bool _isFirstTime = false;
  // bool _languageSelected = false;

  @override
  void initState() {
    super.initState();
    if (Alarm.android) {
      checkAndroidNotificationPermission();
      checkAndroidScheduleExactAlarmPermission();
    }

    _checkFirstTime();
  }
  Future<void> checkAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      alarmPrint('Requesting notification permission...');
      final res = await Permission.notification.request();
      alarmPrint(
        'Notification permission ${res.isGranted ? '' : 'not '}granted',
      );
    }
  }

  Future<void> checkAndroidExternalStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isDenied) {
      alarmPrint('Requesting external storage permission...');
      final res = await Permission.storage.request();
      alarmPrint(
        'External storage permission ${res.isGranted ? '' : 'not'} granted',
      );
    }
  }

  Future<void> checkAndroidScheduleExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    alarmPrint('Schedule exact alarm permission: $status.');
    if (status.isDenied) {
      alarmPrint('Requesting schedule exact alarm permission...');
      final res = await Permission.scheduleExactAlarm.request();
      alarmPrint(
        'Schedule exact alarm permission ${res.isGranted ? '' : 'not'} granted',
      );
    }
  }

  Future<void> _checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstTime = prefs.getBool('isFirstTime');
    if (isFirstTime == null || isFirstTime) {
      setState(() {
        _isFirstTime = true;
      });
    }
  }

  Future<void> _setLanguageChosen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    setState(() {
      _isFirstTime = false;
    });
  }

  // void selectLanguage(BuildContext context, String languageCode) {
  //   setState(() {
  //     _languageSelected = true;
  //   });
  // }

  Widget _createLanguageDropDown() {
    return DropdownButton<LanguageModel>(
      iconSize: 30,
      hint: Text(Languages.of(context)!.selectLanguage),
      onChanged: (LanguageModel? language) {
        changeLanguage(context, language!.languageCode);
        // selectLanguage(context, language.languageCode);
      },
      items: LanguageModel.languageList()
          .map<DropdownMenuItem<LanguageModel>>(
            (e) => DropdownMenuItem<LanguageModel>(
              value: e,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text(
                    e.country,
                    style: const TextStyle(fontSize: 30),
                  ),
                  Text(e.languageName),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isFirstTime
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _createLanguageDropDown(),
                  // if (_languageSelected)
                    ElevatedButton(
                      onPressed: () async {
                        await _setLanguageChosen();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PersonalInfoPage(),
                          ),
                        );
                      },
                      child: Text(Languages.of(context)!.proceedToApp),
                    ),
                ],
              )
            : const MedicineTablePage(),
      ),
    );
  }
}

class MedicineTableApp extends StatefulWidget {
  const MedicineTableApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    var state = context.findAncestorStateOfType<_MedicineTableAppState>();
    state!.setLocale(newLocale);
  }

  @override
  State<MedicineTableApp> createState() => _MedicineTableAppState();
}

class _MedicineTableAppState extends State<MedicineTableApp> {
  Locale? _locale;

  

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void didChangeDependencies() async {
    getLocale().then((locale) {
      setState(() {
        _locale = locale;
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      title: 'Multi Language',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      home: const SplashScreen(),
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode &&
              supportedLocale.countryCode == locale?.countryCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
    );
  }
}
