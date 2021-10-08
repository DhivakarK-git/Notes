import 'package:flutter/material.dart';

import '../constants.dart';

class TestTextSelectionScroll extends StatefulWidget {
  @override
  _TestTextSelectionScrollState createState() =>
      _TestTextSelectionScrollState();
}

class _TestTextSelectionScrollState extends State<TestTextSelectionScroll> {
  final TextEditingController _body = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: ListView(
          children: [
            TextField(
              controller: _body,
              style: Theme.of(context).textTheme.bodyText1,
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}
