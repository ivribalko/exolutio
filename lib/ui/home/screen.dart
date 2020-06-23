import 'package:exolutio/src/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../common.dart';

class HomeScreen extends StatelessWidget {
  final _model = locator<Model>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Selector<Model, bool>(
        selector: (_, Model model) => model.mail,
        builder: (_, bool mail, __) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              StreamBuilder<List<Link>>(
                stream: _filteredArticles(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _buildList(context, snapshot.data);
                  } else {
                    return _buildLoading();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      leading: FlatButton.icon(
        onPressed: () => _model.mail = true,
        icon: Icon(_model.mail ? Icons.mail : Icons.mail_outline),
        label: Container(),
      ),
      actions: <Widget>[
        FlatButton.icon(
          onPressed: () => _model.mail = false,
          icon: Icon(_model.mail ? Icons.info_outline : Icons.info),
          label: Container(),
        ),
      ],
      expandedHeight: AppBarHeight,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Эволюция:\n${_model.mail ? 'Письма' : 'Прочее'}',
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      centerTitle: true,
    );
  }

  Stream<List<Link>> _filteredArticles() {
    return _model.mail ? _model.letters.asStream() : _model.others.asStream();
  }

  Widget _buildLoading() {
    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Link> data) {
    return SliverList(
      delegate: SliverChildListDelegate(data
          .map(
            (e) => _buildLinkView(context, e),
          )
          .toList()),
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
            model.saveRead(data);
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
