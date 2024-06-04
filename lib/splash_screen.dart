import 'package:flutter/material.dart';
import 'package:medicine_tracker/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isAnimate = true;
  bool isClicked = false;

  final width = 50;

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 1), (() {
      setState(() {
        isAnimate = false;
      });
    }));

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: ((context) =>  const LanguageSelectionPage())));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 150),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedPadding(
                  padding: EdgeInsets.only(top: isAnimate ? 40 : 0),
                  duration:const  Duration(seconds: 1),
                  curve: Curves.easeInOutCubicEmphasized,
                  child: AnimatedOpacity(
                    opacity: isAnimate ? 0 : 1,
                    duration:const Duration(seconds: 1),
                    curve: Curves.easeInCubic,
                    child:const CircleAvatar(
                      backgroundColor: Colors.transparent,
                      radius: 100,
                      foregroundImage: AssetImage('assets/1.png'),
                    ),
                  ),
                ),
               const SizedBox(
                  height: 30,
                ),
                AnimatedPadding(
                  padding: EdgeInsets.only(top: isAnimate ? 40 : 0),
                  duration:const Duration(seconds: 1),
                  curve: Curves.easeInOutCubicEmphasized,
                  child: AnimatedOpacity(
                    opacity: isAnimate ? 0 : 1,
                    duration:const Duration(seconds: 1),
                    curve: Curves.easeInCubic,
                    child: const Text(
                      "Medicine Tracker",
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 40,
                          letterSpacing: 1.3,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

