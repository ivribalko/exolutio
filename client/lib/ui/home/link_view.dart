import 'package:client/src/meta_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared/html_model.dart';

class LinkView extends StatelessWidget {
  LinkView(this.data, this.onTap);

  final LinkData data;
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
                    fontSize: Get.textTheme.headline6.fontSize,
                  ),
                ),
                subtitle: Text(data.date),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 8.0,
                top: 8.0,
                right: 16.0,
                bottom: 8.0,
              ),
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
