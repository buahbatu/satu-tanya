import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:satu_tanya/HomeScreen/cardContent.dart';
import 'package:satu_tanya/HomeScreen/homeAction.dart';
import 'package:satu_tanya/model/app_state.dart';
import 'package:satu_tanya/model/question.dart';
import 'package:satu_tanya/repository/repositoryHelper.dart';

final maxCardStack = 3;
final waitDuration = 1;

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<Question> shuffledQuestions;
  List<Question> selected5Questions;
  int currentStart = maxCardStack;

  bool hasDataOnDB = false;
  bool hasLoaded = true;
  bool showOnlyLoved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!hasDataOnDB) loadDataFromInternet();
    resetView();
  }

  void loadDataFromInternet() async {
    // add logic to prevent download everytime
    // ...
    print('after load 0');

    // load from internet logic
    final filters = await RepositoryHelper.getFilters();
    final questions = await RepositoryHelper.getQuestions();
    AppStateContainer.of(context).state.filters.addAll(filters);
    AppStateContainer.of(context).state.addQuestions(questions);
    hasDataOnDB = true;

    print('after load 1');

    // then
    resetView();
  }

  void resetView() {
    if (!mounted) return;
    setState(() {
      currentStart = 0; // resetCounter
      shuffledQuestions = AppStateContainer.of(context)
          .state
          .filteredQuestions()
          .where((question) => showOnlyLoved ? question.isLoved : true)
          .toList()
            ..shuffle();
      selected5Questions = shuffledQuestions.take(maxCardStack).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    int idx = 0;
    return Stack(
      alignment: AlignmentDirectional.center,
      children: (selected5Questions.map<Widget>(
        (question) {
          final i = idx++;
          return Positioned(
            bottom: 20 + (20.0 * i),
            child: buildCard(
                context: context,
                question: question,
                scale: i,
                isActive: i == 0 && hasLoaded),
          );
        },
      ).toList()
            ..add(Container(
              alignment: AlignmentDirectional.center,
              child: Text(
                hasDataOnDB ? 'Tanpa Tanya (?)' : 'Loading ...',
                style: Theme.of(context)
                    .textTheme
                    .display1
                    .copyWith(color: Colors.white, letterSpacing: 3),
              ),
            )))
          .reversed
          .toList()
            ..add(HomeAction(
                loadOnlyLoved,
                (selected5Questions.length > 0
                    ? selected5Questions[0]
                    : null))),
    );
  }

  Widget buildCard({
    @required BuildContext context,
    @required Question question,
    @required int scale,
    bool isActive = false,
  }) {
    final card = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 6,
      child: Container(
        child: CardContent(
          question: question,
          scale: scale,
        ),
        height: MediaQuery.of(context).size.height * 0.78,
        width: MediaQuery.of(context).size.width * (0.9 - (0.1 * scale)),
      ),
    );
    if (isActive) {
      return Dismissible(
        key: new Key(new Random().toString()),
        child: card,
        onDismissed: (direction) {
          if (!mounted) return;
          setState(() {
            hasLoaded = false;
            selected5Questions.remove(question);
          });
          addMoreQuestion();
        },
      );
    } else {
      return GestureDetector(
        child: card,
        onHorizontalDragStart: (detail) {
          if (scale == 0)
            Scaffold.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.purple,
              content: Text('Baca dan pahami dulu ya sebelum lanjut.. 😆'),
              duration: Duration(seconds: 1),
            ));
        },
      );
    }
  }

  void loadOnlyLoved({bool toggle = false}) {
    if (toggle) showOnlyLoved = !showOnlyLoved;
    resetView();

    String text = 'Menampilkan tanya favorit mu';
    if (!showOnlyLoved) text = 'Menampilkan semua tanya';

    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: Colors.purple,
      duration: Duration(seconds: 1),
    ));
  }

  void addMoreQuestion() async {
    await Future.delayed(Duration(seconds: waitDuration));
    hasLoaded = true;
    if (selected5Questions.length < maxCardStack) {
      if (!mounted) return;
      setState(() {
        selected5Questions.add(shuffledQuestions[currentStart++]);
        if (currentStart >= shuffledQuestions.length) {
          resetView();
        }
      });
    }
  }
}