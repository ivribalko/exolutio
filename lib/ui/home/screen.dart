import 'package:evotexto/src/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen(this.data);

  final List<Link> data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: AppBarHeight,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Эволюция:\nПисьма',
                textAlign: TextAlign.center,
              ),
              centerTitle: true,
            ),
            centerTitle: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate(
                data.map((e) => _buildLinkView(context, e)).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkView(BuildContext context, Link link) {
    return _LinkView(
      link,
      () => Navigator.of(context).pushNamed(
        '/read',
        arguments: link,
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
    return Consumer<Model>(
      builder: (BuildContext context, Model model, __) {
        return ListTile(
          onTap: () {
            model.setRead(data);
            onTap();
          },
          title: Text(
            data.title,
            style: model.isRead(data)
                ? TextStyle(color: Theme.of(context).disabledColor)
                : null,
          ),
        );
      },
    );
  }
}
