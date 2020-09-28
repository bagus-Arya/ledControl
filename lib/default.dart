import 'package:flutter/material.dart';
import 'package:ledapps/routing_contsants.dart';

void main() {
  runApp(new MaterialApp(
    title: "LED Control",
  ));
}

class DefaultsP extends StatelessWidget {

@override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: new AppBar(
         backgroundColor: Color.fromRGBO(36, 116, 255, 1.0),
        leading: new IconButton(
          icon: Icon(Icons.arrow_back_ios),
          color: Colors.white,
          onPressed: (){
            Navigator.pushNamed(
              context, IndexRoute
            );
          },
        ),
      ),
      body:Center(
        child: Text("404 FORBIDEN"),
      ) 
    ); 
  }
}