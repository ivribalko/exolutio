import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared/html_model.dart';

import '../../locator.dart';
import '../routes.dart';
import '../view_model.dart';
import 'link_view.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _model = locator<HtmlViewModel>();
  final _refresh = RefreshController(initialRefresh: false);
  final _tabs = <MapEntry<String, IconData>>[
    MapEntry('Письма', Icons.mail),
    MapEntry('Прочее', Icons.info),
  ];

  @override
  void initState() {
    super.initState();
    _model.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: _tabs.length,
        child: NestedScrollView(
          headerSliverBuilder: (context, value) {
            return [
              SliverAppBar(
                title: _TabTitle(_tabs),
                centerTitle: true,
                bottom: TabBar(
                  tabs: [
                    Tab(icon: Icon(_tabs[0].value)),
                    Tab(icon: Icon(_tabs[1].value)),
                  ],
                ),
              ),
            ];
          },
          body: Selector<HtmlViewModel, bool>(
            selector: (_, model) => model.any,
            builder: (_, any, __) {
              return TabBarView(
                children: [
                  if (any) _buildTab(context, Tag.letters),
                  if (any) _buildTab(context, Tag.others),
                  if (!any) Center(child: CircularProgressIndicator()),
                  if (!any) Center(child: CircularProgressIndicator()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Consumer<HtmlViewModel> _buildTab(BuildContext context, Tag tag) {
    return Consumer<HtmlViewModel>(
      builder: (_, HtmlViewModel model, __) {
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

  Widget _buildList(BuildContext context, List<LinkData> data) {
    assert(data.map((e) => e.url).toSet().toList().length == data.length);
    return SliverPadding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(data
            .map(
              (linkData) => Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinkView(
                  linkData,
                  () => Navigator.of(context).pushNamed(
                    Routes.read,
                    arguments: linkData,
                  ),
                ),
              ),
            )
            .toList()),
      ),
    );
  }
}

class _TabTitle extends StatefulWidget {
  final List<MapEntry<String, IconData>> _tabs;

  const _TabTitle(this._tabs);

  @override
  _TabTitleState createState() => _TabTitleState();
}

class _TabTitleState extends State<_TabTitle> {
  bool _subscribed = false;

  TabController get _tabController {
    return DefaultTabController.of(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribed) {
      _tabController.addListener(() {
        setState(() {});
      });
      _subscribed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget._tabs[_tabController.index].key,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: Get.textTheme.headline4.fontSize,
      ),
    );
  }
}
