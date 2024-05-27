import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medicine_tracker/classes_handler.dart';
import 'package:medicine_tracker/handler.dart';
import 'package:medicine_tracker/language/language.dart';
import 'package:medicine_tracker/localization/delegation.dart';
import 'package:medicine_tracker/localization/constant.dart';
import 'package:flutter/material.dart';
import 'package:medicine_tracker/medicine.dart';
import 'splash_screen.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  @override
  Widget build(BuildContext context) {
    List<Personal>? personals = [];
    String name = "";
    String personCase = "";
    String age = "";
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: Languages.of(context)!.name,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: (value) {
                name = value;
              },
            ),
            SizedBox(height: 16.0),
            TextFormField(
              decoration: InputDecoration(
                labelText: Languages.of(context)!.age,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                age = value;
              },
            ),
            SizedBox(height: 16.0),
            TextFormField(
              decoration: InputDecoration(
                labelText: Languages.of(context)!.personalCase,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              onChanged: (value) {
                personCase = value;
              },
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () async {
                Personal personal = Personal(
                  name: name,
                  age: age,
                  personCase: personCase,
                );

                personals.add(personal);
                await savePersonal(personals);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MedicineTablePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                textStyle: TextStyle(fontSize: 18.0),
              ),
              child: Text(Languages.of(context)!.proceedToApp),
            ),
          ],
        ),
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
