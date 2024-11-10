import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> {
  double fillPercentage = 0.0;

  void increaseFill() {
    setState(() {
      // Increment fill by 1/4 each time, up to full **TO BE CHANGED***
      fillPercentage = (fillPercentage + 0.25).clamp(0.0, 1.0);
    });
  }

  void decreaseFill() {
    setState(() {
      fillPercentage = (fillPercentage - 0.25).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Water Tracker"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Water fill background
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: Duration(seconds: 1),
                      width: 200,
                      height: 300 * fillPercentage,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/cup.png',
                  width: 250,
                  height: 300,
                  fit: BoxFit.fill,
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: increaseFill,
              child: Text("Fill Cup"),
            ),
            ElevatedButton(
              onPressed: decreaseFill,
              child: Text("Decrease Cup"),
            ),
          ],
        ),
      ),
    );
  }
}
