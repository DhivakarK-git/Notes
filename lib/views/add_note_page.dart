import 'package:flutter/material.dart';
import 'package:notes/constants.dart';
import 'dart:async';
import 'package:notes/model/note.dart' as note;

class AddNotePage extends StatelessWidget {
  final Function close;
  AddNotePage(this.close);

  @override
  Widget build(BuildContext context) {
    String title = '', body = '';

    Future<void> save(context) async {
      if (title.isNotEmpty || body.isNotEmpty) {
        await note.Note(title, body, DateTime.now()).addCard();
        close.call();
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              duration: Duration(seconds: 3),
              elevation: 2,
              content: Text(
                'Empty Note Discarded',
                style: Theme.of(context).textTheme.bodyText1,
              )),
        );
      }
    }

    return WillPopScope(
      onWillPop: () async {
        if (FocusScope.of(context).hasFocus) {
          FocusScope.of(context).unfocus();
          Timer(Duration(milliseconds: 200), () async => await save(context));
        } else
          await save(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 88,
          elevation: 0,
        ),
        body: Container(
            margin: EdgeInsets.symmetric(horizontal: 18),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Form(
                child: Column(
                  children: [
                    TextFormField(
                      cursorColor: Theme.of(context).primaryColor == kGlacier
                          ? kMatte
                          : kGlacier,
                      onChanged: (value) {
                        title = value;
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: "Title",
                      ),
                      textInputAction: TextInputAction.next,
                      style: Theme.of(context).textTheme.headline4,
                      keyboardType: TextInputType.text,
                    ),
                    TextFormField(
                      autofocus: true,
                      cursorColor: Theme.of(context).primaryColor == kGlacier
                          ? kMatte
                          : kGlacier,
                      onChanged: (value) {
                        body = value;
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: "Note",
                      ),
                      textInputAction: TextInputAction.newline,
                      style: Theme.of(context).textTheme.bodyText1,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }
}
