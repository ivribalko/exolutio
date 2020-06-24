import 'package:exolutio/src/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../main.dart';
import '../common.dart';

class HomeScreen extends StatelessWidget {
  final _model = locator<Model>();
  final _refreshController = RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Selector<Model, bool>(
        selector: (_, Model model) => model.mail,
        builder: (_, bool mail, __) {
          return _buildRefresher(
            child: CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(mail),
                FutureBuilder<List<Link>>(
                  future: mail ? _model.letters : _model.others,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildList(context, snapshot.data);
                    } else if (snapshot.hasError) {
                      return Center(child: Text(snapshot.error));
                    } else {
                      return SliverProgressIndicator();
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(bool mail) {
    return SliverAppBar(
      leading: FlatButton.icon(
        onPressed: () => _model.mail = true,
        icon: Icon(mail ? Icons.mail : Icons.mail_outline),
        label: Container(),
      ),
      actions: <Widget>[
        FlatButton.icon(
          onPressed: () => _model.mail = false,
          icon: Icon(mail ? Icons.info_outline : Icons.info),
          label: Container(),
        ),
      ],
      expandedHeight: AppBarHeight,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Эволюция:\n${mail ? 'Письма' : 'Прочее'}',
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      centerTitle: true,
    );
  }

  Widget _buildRefresher({Widget child}) {
    return SmartRefresher(
      controller: _refreshController,
      enablePullUp: true,
      enablePullDown: true,
      onRefresh: () {},
      onLoading: () {},
      header: WaterDropHeader(),
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = Text("pull up load");
          } else if (mode == LoadStatus.loading) {
            body = CircularProgressIndicator();
          } else if (mode == LoadStatus.failed) {
            body = Text("Load Failed!Click retry!");
          } else if (mode == LoadStatus.canLoading) {
            body = Text("release to load more");
          } else {
            body = Text("No more Data");
          }
          return Container(
            height: 55.0,
            child: Center(child: body),
          );
        },
      ),
      child: child,
    );
  }

  Widget _buildList(BuildContext context, List<Link> data) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(data
            .map(
              (e) => Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: _buildLinkView(context, e),
              ),
            )
            .toList()),
      ),
    );
  }

  Widget _buildLinkView(BuildContext context, Link link) {
    return _LinkView(
      link,
      () => Navigator.of(context).pushNamed(
        '/read',
        arguments: [link.title, link],
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
    return Selector<Model, bool>(
      selector: (_, model) => model.isRead(data),
      builder: (BuildContext context, bool isRead, __) {
        return ListTile(
          dense: true,
          onTap: onTap,
          title: Text(
            data.title,
            style: TextStyle(
              color: isRead ? Theme.of(context).disabledColor : null,
              fontSize: 20,
            ),
          ),
        );
      },
    );
  }
}
