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
    return WillPopScope(
      onWillPop: () async {
        if (title.isNotEmpty || body.isNotEmpty) {
          note.Note(title, body, DateTime.now()).addCard();
          close.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
                elevation: 2,
                backgroundColor: kShadow,
                content: Text(
                  'Empty Note Discarded',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1!
                      .copyWith(color: kGlacier),
                )),
          );
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              if (FocusScope.of(context).hasFocus) {
                FocusScope.of(context).unfocus();
                Timer(Duration(milliseconds: 200),
                    () async => Navigator.of(context).pop());
              } else
                Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back),
          ),
          toolbarHeight: 88,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: InkWell(
                onTap: () async {
                  if (title.isNotEmpty || body.isNotEmpty) {
                    note.Note(title, body, DateTime.now()).addCard();
                    close.call();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 3),
                          elevation: 2,
                          backgroundColor: kShadow,
                          content: Text(
                            'Note is Empty',
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1!
                                .copyWith(color: kGlacier),
                          )),
                    );
                  }
                },
                child: Card(
                  color: Colors.cyan[200],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.save,
                          color: kMatte,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "SAVE",
                          style: Theme.of(context)
                              .textTheme
                              .button!
                              .copyWith(color: kMatte),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
