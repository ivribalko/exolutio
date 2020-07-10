import 'package:client/src/meta_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared/html_model.dart';

import '../../main.dart';
import '../routes.dart';
import '../view_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _model = locator<HtmlViewModel>();
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
                  'Эволюция',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.headline4.fontSize,
                  ),
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

  Consumer<HtmlViewModel> _buildTab(BuildContext context, Tag tag) {
    return Consumer<HtmlViewModel>(
      builder: (_, HtmlViewModel model, __) {
        if (!model.any) {
          _model.loadMore();
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          _refresh.loadComplete();
          _refresh.refreshCompleted();
        });
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
      header: MaterialClassicHeader(),
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
        Routes.read,
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
    return Selector<MetaModel, double>(
      selector: (_, model) => model.getProgress(data),
      builder: (BuildContext context, double progress, __) {
        return Row(
          children: <Widget>[
            Flexible(
              child: ListTile(
                dense: true,
                onTap: onTap,
                title: Text(
                  data.title.replaceFirst('Письмо: ', '').replaceAll('"', ''),
                  style: TextStyle(
                    color: _desaturateCompleted(progress, context),
                    fontSize: Theme.of(context).textTheme.headline6.fontSize,
                  ),
                ),
                subtitle: Text(data.date),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: _Progress(progress),
            ),
          ],
        );
      },
    );
  }

  Color _desaturateCompleted(double progress, BuildContext context) {
    return progress != null && progress >= 1
        ? Theme.of(context).disabledColor
        : null;
  }
}

class _Progress extends StatelessWidget {
  final progress;

  const _Progress(this.progress);

  @override
  Widget build(BuildContext context) {
    if ((progress ?? 0) >= 1) {
      return Icon(
        Icons.check,
        size: 35,
        color: Theme.of(context).accentColor,
      );
    } else {
      return CircularProgressIndicator(
        backgroundColor: Theme.of(context).disabledColor,
        value: progress ?? 0,
      );
    }
  }
}
