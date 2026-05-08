import 'package:ads_frontend/views/advertiser/home.dart';
import 'package:ads_frontend/views/agency/home.dart';
import 'package:ads_frontend/views/driver/home.dart';
import 'package:ads_frontend/views/login/SignupView.dart';
import 'package:ads_frontend/views/login/loginview.dart';
import 'package:ads_frontend/views/login/splashview.dart';
import 'package:flutter/material.dart';

import 'theme/apptheme.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moving Ads',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      initialRoute: '/',
      routes: {
        '/': (context) => const Splashview(),
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignupView(),
        '/advertiserDashboard': (context) => const AdvertiserHomeScreen(),
         '/driverDashboard': (context) => const DriverHomeScreen(),
        '/agencyDashboard':(context)=> const AgencyHomeScreen(),
      },
    );
  }
}

