import 'package:exolutio/src/loader.dart';
import 'package:exolutio/src/model.dart';

void main() async {
  final model = HtmlModel(Loader());
  await model.loadMore();
  print(model[Tag.letters].map((e) => e.title).join('\n'));
}
