import "package:flutter/material.dart";
import "package:flutter/cupertino.dart";
import "dart:math" as Math;


class Wheel{
  static double vectorToHue(Offset vector) => (((Math.atan2(vector.dy, vector.dx)) * 180.0 / Math.pi) + 360.0) % 360.0;
  static double vectorToSaturation(double vectorX, double squareRadio) => vectorX * 0.5 / squareRadio + 0.5;
  static double vectorToValue(double vectorY, double squareRadio) => 0.5 - vectorY * 0.5 / squareRadio;

  static Offset hueToVector(double h, double radio, Offset center) => new Offset(Math.cos(h) * radio + center.dx, Math.sin(h) * radio + center.dy);
  static double saturationToVector(double s, double squareRadio, double centerX) => (s - 0.5) * squareRadio / 0.5 + centerX;
  static double valueToVector(double l, double squareRadio, double centerY) => (0.5 - l) * squareRadio / 0.5 + centerY;
}

class WheelPicker extends StatefulWidget {

  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;

  WheelPicker({
    Key key,
    @required this.color,
    @required this.onChanged,
  }) : assert(color != null),
        super(key: key);

  @override
  _WheelPickerState createState() => new _WheelPickerState();
}

class _WheelPickerState extends State<WheelPicker> {

  HSVColor get color=> super.widget.color;


  final GlobalKey paletteKey = GlobalKey();
  Offset getOffset(Offset ratio){
    RenderBox renderBox = this.paletteKey.currentContext.findRenderObject();
    Offset startPosition = renderBox.localToGlobal(Offset.zero);
    return ratio-startPosition;
  }
  Size getSize(){
    RenderBox renderBox = this.paletteKey.currentContext.findRenderObject();
    return renderBox.size;
  }



  bool isWheel = false;
  bool isPalette = false;
  void onPanStart(Offset offset){
    RenderBox renderBox = this.paletteKey.currentContext.findRenderObject();
    Size size = renderBox.size;

    double radio =_WheelPainter.radio(size);
    double squareRadio =_WheelPainter.squareRadio(radio);

    Offset startPosition = renderBox.localToGlobal(Offset.zero);
    Offset center = Offset(size.width/2, size.height/2);
    Offset vector = offset-startPosition-center;

    bool isPalette=vector.dx.abs() < squareRadio && vector.dy.abs() < squareRadio;
    this.isWheel = !isPalette;
    this.isPalette = isPalette;

    //this.isWheel = vector.distance + _WheelPainter.strokeWidth > radio && vector.distance - squareRadio < radio;
    //this.isPalette =vector.dx.abs() < squareRadio && vector.dy.abs() < squareRadio;

    if (this.isWheel) super.widget.onChanged(this.color.withHue(Wheel.vectorToHue(vector)));
    if (this.isPalette) super.widget.onChanged(HSVColor.fromAHSV(
        this.color.alpha,
        this.color.hue,
        Wheel.vectorToSaturation(vector.dx, squareRadio).clamp(0.0, 1.0),
        Wheel.vectorToValue(vector.dy, squareRadio).clamp(0.0, 1.0)
    ));
  }
  void onPanUpdate(Offset offset){
    RenderBox renderBox = this.paletteKey.currentContext.findRenderObject();
    Size size = renderBox.size;

    double radio =_WheelPainter.radio(size);
    double squareRadio =_WheelPainter.squareRadio(radio);

    Offset startPosition = renderBox.localToGlobal(Offset.zero);
    Offset center = Offset(size.width/2, size.height/2);
    Offset vector = offset-startPosition-center;

    if (this.isWheel) super.widget.onChanged(this.color.withHue(Wheel.vectorToHue(vector)));
    if (this.isPalette) super.widget.onChanged(HSVColor.fromAHSV(
        this.color.alpha,
        this.color.hue,
        Wheel.vectorToSaturation(vector.dx, squareRadio).clamp(0.0, 1.0),
        Wheel.vectorToValue(vector.dy, squareRadio).clamp(0.0, 1.0)
    ));
  }
  void onPanDown(Offset offset)=> this.isWheel = this.isPalette = false;



  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
        onPanStart: (details)=>this.onPanStart(details.globalPosition),
        onPanUpdate: (details)=>this.onPanUpdate(details.globalPosition),
        onPanDown: (details)=>this.onPanDown(details.globalPosition),
        child: new Container(
            key: this.paletteKey,
            padding: const EdgeInsets.only(top: 12.0),
            width: 240,
            height: 240,
            child: new CustomPaint(
                painter: new _WheelPainter(color: this.color)
            )
        )
    );
  }
}


class _WheelPainter extends CustomPainter{

  static double strokeWidth = 8;
  static double doubleStrokeWidth = 16;
  static double radio(Size size)=> Math.min(size.width, size.height).toDouble() / 2 - _WheelPainter.strokeWidth;
  static double squareRadio(double radio) => (radio - _WheelPainter.strokeWidth)/ 1.414213562373095;

  final HSVColor color;

  _WheelPainter({
    Key key,
    this.color
  }):super();

  @override
  void paint(Canvas canvas, Size size) {

    Offset center = new Offset(size.width/2, size.height/2);
    double radio =_WheelPainter.radio(size);
    double squareRadio =_WheelPainter.squareRadio(radio);


    //Wheel
    Shader sweepShader = const SweepGradient(
      center: Alignment.bottomRight, 
      colors: const [
      Color.fromARGB(255, 255, 0, 0),
      Color.fromARGB(255, 255, 255, 0),
      Color.fromARGB(255, 0, 255, 0),
      Color.fromARGB(255, 0, 255, 255),
      Color.fromARGB(255, 0, 0, 255),
      Color.fromARGB(255, 255, 0, 255),
      Color.fromARGB(255, 255, 0, 0),
    ]).createShader(Rect.fromLTWH(0, 0, radio, radio));
    canvas.drawCircle(center, radio, new Paint()..style=PaintingStyle.stroke..strokeWidth = _WheelPainter.doubleStrokeWidth..shader=sweepShader);
    
    canvas.drawCircle(center, radio - _WheelPainter.strokeWidth, new Paint()..style=PaintingStyle.stroke..color=Colors.grey);
    canvas.drawCircle(center, radio + _WheelPainter.strokeWidth, new Paint()..style=PaintingStyle.stroke..color=Colors.grey);


    //Palette
    Rect rect = Rect.fromLTWH(center.dx - squareRadio, center.dy - squareRadio, squareRadio * 2, squareRadio * 2);
    RRect rRect = RRect.fromRectAndRadius(rect, Radius.circular(4));

    Shader horizontal = new LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, HSVColor.fromAHSV(1.0, this.color.hue, 1.0, 1.0).toColor()],
    ).createShader(rect);
    canvas.drawRRect(rRect, new Paint()..style=PaintingStyle.fill..shader = horizontal);
    
    Shader vertical = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    ) .createShader(rect);
    canvas.drawRRect(rRect, new Paint()..style=PaintingStyle.fill..shader = vertical);

    canvas.drawRRect(rRect, new Paint()..style=PaintingStyle.stroke..color = Colors.grey);
 

    //Thumb
    final Paint paintWhite = new Paint()..color=Colors.white..strokeWidth=4..style=PaintingStyle.stroke;
    final Paint paintBlack = new Paint()..color=Colors.black..strokeWidth=6..style=PaintingStyle.stroke;
    Offset wheel = Wheel.hueToVector(((this.color.hue + 360.0) * Math.pi / 180.0), radio, center);
    canvas.drawCircle(wheel, 12, paintBlack);
    canvas.drawCircle(wheel, 12, paintWhite);


    //Thumb
    double paletteX = Wheel.saturationToVector(this.color.saturation, squareRadio, center.dx);
    double paletteY = Wheel.valueToVector(this.color.value, squareRadio, center.dy);
    Offset paletteVector=new Offset(paletteX, paletteY);
    canvas.drawCircle(paletteVector, 12, paintBlack);
    canvas.drawCircle(paletteVector, 12, paintWhite);
  }

  @override
  bool shouldRepaint(_WheelPainter other) => true;
}
