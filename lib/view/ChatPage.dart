import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;
  
  const ChatPage({this.server});
  
  @override
  _ChatPage createState() => new _ChatPage();
}

class _ChatPage extends State<ChatPage> {
  // color picker
  Color _currentColor = const Color(0xFF4286f4);
  String pinNum = "";
  String color = "";
  var myInt = "";  
  static final clientID = 0;
  static final maxMessageLength = 4096 - 3;
  BluetoothConnection connection;
  
  String _messageBuffer = '';

  bool isConnecting = true;
  bool button8 = false; //(-)/(+) anoda atau katoda
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        }
        else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white10,
      appBar: AppBar(
        title: (
          isConnecting ? Text('Connecting to ' + widget.server.name + '...') :
          isConnected ? Text('Connected with ' + widget.server.name) :
          Text('Disconnected from ' + widget.server.name)
        )
      ),
      body: Center(
          child: isConnecting ? Text('Wait until connected...',
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                fontFamily: "Roboto"
            ),
          ) :
          isConnected ? Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // isi widget disini
                    CircleColorPicker(
                      initialColor: _currentColor,
                      onChanged: (value) {
                        setState(() {
                            _currentColor = value;
                            myInt = colorToString(_currentColor);
                            print("To String: $myInt");
                            print("My Color: $_currentColor");
                            _sendMessage(myInt);
                            return myInt;
                        });
                      },
                      colorCodeBuilder: (context, color){
                        return Text(
                          '#${color.value.toRadixString(16).substring(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        );
                      },
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(50, 50, 50, 10),
                  child: Row(
                    children: <Widget>[
                      Text("Pin 8",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            fontFamily: "Roboto",
                            color: _currentColor
                        ),
                      ),
                      ButtonTheme(
                        minWidth: 100,
                        height: 50,
                        child: RaisedButton(
                            color: button8 ? Colors.red : Colors.green,
                            child: button8 ? Text("Turn Off") :Text("Turn On"),
                            onPressed: () => button8 ? _sendMessage('8 off') : _sendMessage('8 on')
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: Colors.black,
                  thickness: 3,
                ),
              ]
          ): Text('Got disconnected',
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                fontFamily: "Roboto"
            ),)

      )
    );
  } 

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      }
      else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        }
        else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);

    if (~index != 0) {
      setState(() {
        String receivedData = _messageBuffer + dataString.substring(0, index);
        receivedData = receivedData.trim();
        // send data string to 
        // if (receivedData.substring(0, 5) == 'myInt') {
        //   setState(() {
        //     myInt = colorToString(_currentColor);
        //     print("My Color: $myInt");
        //     myInt = receivedData.substring(5, receivedData.length);
        //     return myInt;
        //   });
        // }
        // send data on
        if (receivedData == "8 on"){
          button8 = true;
        }
        if (receivedData == "8 off"){
          button8 = false;
        }
        _messageBuffer = dataString.substring(index);
      });
    }
    else {
      _messageBuffer = (
        backspacesCounter > 0 
          ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter) 
          : _messageBuffer
        + dataString
      );
    }
  }
  
  // method change color
  // _onColorChanged(value) {
  //     setState(() {
  //       _currentColor = value;
  //       myInt = colorToString(_currentColor);
  //       print("To String: $myInt");
  //       print("My Color: $_currentColor");
  //       return myInt;
  //     });
  // }
  // color to string
  String colorToString(Color c){
    String colorString = c.toString();
    String valueString = colorString.substring(10, colorString.length - 1);
    return valueString;
  }

  void _sendMessage(String text) async {
    text = text.trim();

    if (text.length > 0)  {
      print(utf8.encode(text + "\r\n"));
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;

        setState(() {
//          messages.add(_Message(clientID, text));
        });

      }
      catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
