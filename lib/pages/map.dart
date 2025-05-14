import 'package:flutter/material.dart';

class Map extends StatefulWidget {
  const Map({super.key});
  @override
  State<Map> createState() => MapState();
}

class MapState extends State<Map> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: Center(child: Text('map')));
  }
}
