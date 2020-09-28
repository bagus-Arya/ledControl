import 'package:flutter/material.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:ledapps/routing_contsants.dart';
import 'package:ledapps/view/MainPage.dart';
import 'default.dart';

Route<dynamic> generateRoute(RouteSettings settings){
  switch (settings.name) {
    case IndexRoute:
      return MaterialPageRoute(builder: (context) => Indexpage());
    case ColorRoute:
      return MaterialPageRoute(builder: (context) => CircleColorPicker());
    default:
      return MaterialPageRoute(builder: (context) => DefaultsP());
  }
}