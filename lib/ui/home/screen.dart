import 'package:exolutio/src/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../main.dart';

class HomeScreen extends StatelessWidget {
  final _model = locator<Model>();
  final _refresh = RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, value) {
            return [
              SliverAppBar(
                title: Text(
                  'Эволюция: ${true ? 'Письма' : 'Прочее'}',
                  textAlign: TextAlign.center,
                ),
                centerTitle: true,
                bottom: TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.mail)),
                    Tab(icon: Icon(Icons.info)),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildTab(context, Tag.letters),
              _buildTab(context, Tag.others),
            ],
          ),
        ),
      ),
    );
  }

  Consumer<Model> _buildTab(BuildContext context, Tag tag) {
    return Consumer<Model>(
      builder: (_, Model model, __) {
        _refresh.loadComplete();
        _refresh.refreshCompleted();
        return _buildRefresher(
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildList(context, model[tag]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRefresher({Widget child}) {
    return SmartRefresher(
      controller: _refresh,
      enablePullUp: true,
      enablePullDown: true,
      onRefresh: _model.refresh,
      onLoading: _model.loadMore,
      header: ClassicHeader(),
      footer: ClassicFooter(),
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
