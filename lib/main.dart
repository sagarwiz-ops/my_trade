import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/Utils/Constants.dart';
import 'package:my_trade/MyNetwork.dart';
import 'package:my_trade/CreateProfile.dart';
import 'package:my_trade/Auth/Login.dart';

import 'BLOC/DataBloc.dart';
import 'Home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();


  FirebaseDatabase.instance.setLoggingEnabled(true);
  bool isLoggedIn = false;

  if(await Constants.checkIfTheCurrentUserExists()){
    var phoneNumber  = FirebaseAuth.instance.currentUser!.phoneNumber;
    isLoggedIn = await MyFirebase.checkIfTheUserIsValidated(phoneNumber!);
  }

  runApp(MyApp(isLoggedIn));
}

class MyApp extends StatelessWidget {
final isLoggedIn;
  MyApp(this.isLoggedIn);


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DataBloc(),
      child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            // This is the theme of your application.
            primarySwatch: Colors.blue,

            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.lightGray),
            useMaterial3: true,
          ),
          home: isLoggedIn ? Home() : Login()
      ),
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

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
