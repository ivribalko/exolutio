import 'package:evotexto/src/model.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen(this.data);

  final List<Link> data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemBuilder: (context, index) => _LinkView(
          data[index],
          () => Navigator.of(context).pushNamed(
            '/read',
            arguments: data[index],
          ),
        ),
      ),
    );
  }
}

class _LinkView extends StatelessWidget {
  _LinkView(this.data, this.onTap);

  final Link data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(data.title),
    );
  }
}
