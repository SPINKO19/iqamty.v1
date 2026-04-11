import 'package:flutter/material.dart';
import '../components/custom_menu_button.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CustomMenuButton(),
        ),
        title: Text(title),
      ),
      body: Center(child: Text(title)),
    );
  }
}

