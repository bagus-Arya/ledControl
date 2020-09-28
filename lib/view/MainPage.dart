import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import './DiscoveryPage.dart';
import './SelectBondedDevicePage.dart';
import './ChatPage.dart';

class Indexpage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<Indexpage> {
  //color test
  // Color _currentColor = const Color.fromARGB(255, 195, 54, 211);
  Color _currentColor = const Color(0xFF4286f4);
  
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

//  BackgroundCollectingTask _collectingTask;

  bool _autoAcceptPairingRequests = false;

  @override
  void initState() {
    super.initState();
    
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() { _bluetoothState = state; });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() { _address = address; });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() { _name = name; });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
//    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LED Control'),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            Divider(),
            ListTile(
              title: const Text('General')
            ),
            SwitchListTile(
              title: const Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async { // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }
                future().then((_) {
                  setState(() {});
                });
              },
            ),
            ListTile(
              title: const Text('Bluetooth status'),
              subtitle: Text(_bluetoothState.toString()),
              trailing: RaisedButton(
                child: const Text('Settings'),
                onPressed: () { 
                  FlutterBluetoothSerial.instance.openSettings();
                },
              ),
            ),
            ListTile(
              title: const Text('Local adapter address'),
              subtitle: Text(_address),
            ),
            ListTile(
              title: const Text('Local adapter name'),
              subtitle: Text(_name),
              onLongPress: null,
            ),
            ListTile(
              title: _discoverableTimeoutSecondsLeft == 0 ? const Text("Discoverable") : Text("Discoverable for ${_discoverableTimeoutSecondsLeft}s"),
              subtitle: const Text("PsychoX-Luna"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _discoverableTimeoutSecondsLeft != 0,
                    onChanged: null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      print('Discoverable requested');
                      final int timeout = await FlutterBluetoothSerial.instance.requestDiscoverable(60);
                      if (timeout < 0) {
                        print('Discoverable mode denied');
                      }
                      else {
                        print('Discoverable mode acquired for $timeout seconds');
                      }
                      setState(() {
                        _discoverableTimeoutTimer?.cancel();
                        _discoverableTimeoutSecondsLeft = timeout;
                        _discoverableTimeoutTimer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
                          setState(() {
                            if (_discoverableTimeoutSecondsLeft < 0) {
                              FlutterBluetoothSerial.instance.isDiscoverable.then((isDiscoverable) {
                                if (isDiscoverable) {
                                  print("Discoverable after timeout... might be infinity timeout :F");
                                  _discoverableTimeoutSecondsLeft += 1;
                                }
                              });
                              timer.cancel();
                              _discoverableTimeoutSecondsLeft = 0;
                            }
                            else {
                              _discoverableTimeoutSecondsLeft -= 1;
                            }
                          });
                        });
                      });
                    },
                  )
                ]
              )
            ),

            Divider(),
            ListTile(
              title: const Text('Devices discovery and connection')
            ),
            SwitchListTile(
              title: const Text('Auto-try specific pin when pairing'),
              subtitle: const Text('Pin 1234'),
              value: _autoAcceptPairingRequests,
              onChanged: (bool value) {
                setState(() {
                  _autoAcceptPairingRequests = value;
                });
                if (value) {
                  FlutterBluetoothSerial.instance.setPairingRequestHandler((BluetoothPairingRequest request) {
                    print("Trying to auto-pair with Pin 1234");
                    if (request.pairingVariant == PairingVariant.Pin) {
                      return Future.value("1234");
                    }
                    return null;
                  });
                }
                else {
                  FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
                }
              },
            ),
            ListTile(
              title: RaisedButton(
                child: const Text('Explore discovered devices'),
                onPressed: () async {
                  final BluetoothDevice selectedDevice = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) { return DiscoveryPage(); })
                  );

                  if (selectedDevice != null) {
                    print('Discovery -> selected ' + selectedDevice.address);
                  }
                  else {
                    print('Discovery -> no device selected');
                  }
                }
              ),
            ),
            ListTile(
              title: RaisedButton(
                child: const Text('Connect to paired device to start'),
                onPressed: () async {
                  final BluetoothDevice selectedDevice = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) { return SelectBondedDevicePage(checkAvailability: false); })
                  );

                  if (selectedDevice != null) {
                    print('Connect -> selected ' + selectedDevice.address);
                    _startChat(context, selectedDevice);
                  }
                  else {
                    print('Connect -> no device selected');
                  }
                },
              ),
            ),
            Divider(),
            ListTile(
              title: RaisedButton(
                child: const Text('Trial Custom Color Picker'),
                onPressed: _colorPicker
                ),
            ),
            Divider(),           
            ListTile(
              title: RaisedButton(
                child: const Text('Circle Picker'),
                onPressed: _colorPickers
                ),
            ),
            Divider(),           
            ListTile(
              title: RaisedButton(
                child: const Text('HSV Color Picker'),
                onPressed: _colorhsvPickers
                ),
            ),
            // Divider(),           
            // ListTile(
            //   title: RaisedButton(
            //     child: const Text('Custom Color Picker'),
            //     onPressed: _colorPickercustom
            //     ),
            // ),
          ],
        ),
      ),
    );
  }

  // method colors
  void _colorPicker(){
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
          return GestureDetector(
            onPanDown: (DragDownDetails details){
              _selectColors(details.localPosition);
            },
            onHorizontalDragUpdate: (DragUpdateDetails details){
              _selectColors(details.localPosition);
            },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top:100.0),
                      width: 300,
                      height: 100,
                      decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade100, 
                          Colors.yellow.shade300, 
                          Colors.redAccent.shade200, 
                          Colors.blue.shade300,
                          Colors.grey.shade900
                          ])
                    ),
                    )
                  )
                ],
              ),
          );
        })
    );
  }
  void _colorPickers(){
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    // isi widget disini
                    CircleColorPicker(
                      initialColor: _currentColor,
                      // onChanged: (color) => print(color),
                      onChanged: _onColorChanged,
                      colorCodeBuilder: (context, color){
                        return Text(
                          // 'rgb(${color.red}, ${color.green}, ${color.blue})',
                          '#${color.value.toRadixString(16).substring(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        );
                      },
                    ),
                  ],
              ),
            ),
          );
        })
    );
  }
  void _colorhsvPickers(){
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    // isi widget disini
                    ColorPicker(
                      color: _currentColor,
                      onChanged: _onColorChanged)
                  ],
              ),
            ),
          );
        })
    );
  }
  // void _colorPickercustom(){
  //   Navigator.of(context).push(
  //     new MaterialPageRoute(builder: (context) {
  //         return Scaffold(
  //           body: Center(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                 children: <Widget>[
  //                   // isi widget disini
  //                   ColorPicker(
  //                     pickerColor: _currentColor, 
  //                     onColorChanged: _onColorChanged,
  //                     )
  //                 ],
  //             ),
  //           ),
  //         );
  //       })
  //   );
  // }
  _onColorChanged(value) {
      setState(() {
        _currentColor = value;
        var myInt = colorToString(_currentColor);
        var myRgb = colorToRGB(_currentColor);
        print("To String: $myInt");
        print("To RGB: $myRgb");
        print("My Color: $_currentColor");
      });
  }

  String colorToString(Color c){
    String colorString = c.toString();
    String valueString = colorString.substring(10, colorString.length - 1);
    return valueString;
  }
  String colorToRGB(Color c){
    String colorString = c.toString();
    String rgb = colorString.substring(10, colorString.length - 1);
    return rgb[0]+rgb[1] + ", " + rgb[2]+ rgb[3] + ", " + rgb[3]+rgb[4];
  }

  void _selectColors(Offset touchPosition){
    // |  |----|  |----|  |----|  |----|  |
    final RenderBox renderBox = context.findRenderObject();
    final double blobDiameter = renderBox.size.height;
    final double blobRadius = blobDiameter/2;
    final double separatorSpace = (renderBox.size.width - (5* blobDiameter)) / (4 - 1);
    final double touchX = touchPosition.dx.clamp(0, renderBox.size.width);
    final double fractionalTouchPosition = max(touchX - blobRadius, 0.0) / (blobDiameter + separatorSpace);
    print('fractionalTouchPosition: $fractionalTouchPosition');
  }

  // end of method colors
  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) { return ChatPage(server: server); }));
  }

  Future<void> _startBackgroundTask(BuildContext context, BluetoothDevice server) async {

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occured while connecting'),
            content: Text(""),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
  }
}