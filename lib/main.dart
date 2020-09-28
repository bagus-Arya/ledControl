import 'package:flutter/material.dart';
import 'package:ledapps/routing_contsants.dart';
import 'router.dart' as router;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LED Control',
      onGenerateRoute: router.generateRoute,
      initialRoute: IndexRoute, //first appearence 
    );
  }
}