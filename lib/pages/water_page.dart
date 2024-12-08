import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> {
  double fillPercentage = 1.0; // means full cup
  int counter = 0; // Counter for how many times the cup has been emptied

  void increaseFill() {
    setState(() {
      fillPercentage = (fillPercentage + 0.125).clamp(0.0, 1.0); //clamp restricts a value to certain range so that water no overflow
    });
  }

  void decreaseFill() {
    setState(() {
      fillPercentage = (fillPercentage - 0.125).clamp(0.0, 1.0);
      if (fillPercentage == 0.0 && counter < 8) {
        counter++;
        if (counter < 8) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Good Job!"),
              content: Text("You drank $counter/8 cups of water!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      fillPercentage = 1.0; // refills the cup
                    });
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          );
        } else {
          // This will not make the water fill up if you already drank 8 cups
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Congratulations!"),
              content: Text("You completed 8/8 cups of water for the day!"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Water Tracker"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Cups Drank: $counter/8",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
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
                  'assets/emptycup.png',
                  width: 250,
                  height: 300,
                  fit: BoxFit.fill,
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: counter >= 8 ? null : increaseFill, // Disable if counter is 8 or more
                  child: Text("Fill Cup"),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: decreaseFill,
                  child: Text("Drink Water"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
