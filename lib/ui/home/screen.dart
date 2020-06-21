import 'package:evotexto/src/model.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen(this.data);

  final List<Link> data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Эволюция'),
            centerTitle: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate(data
                .map(
                  (e) => _LinkView(
                    e,
                    () => Navigator.of(context).pushNamed(
                      '/read',
                      arguments: e,
                    ),
                  ),
                )
                .toList()),
          ),
        ],
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
    return ListTile(
      onTap: onTap,
      title: Text(data.title),
    );
  }
}
