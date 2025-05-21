import 'package:flutter/material.dart';

class map extends StatefulWidget {
  const map({super.key});

  map.from(Object? data);
  @override
  State<map> createState() => mapState();
}

class mapState extends State<map> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: Center(child: Text('map')));
  }
}
