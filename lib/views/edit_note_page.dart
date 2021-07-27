import 'package:flutter/material.dart';
import 'package:notes/constants.dart';
import 'package:notes/model/note.dart';
import 'dart:async';

class EditNotePage extends StatelessWidget {
  final Function close, refresh;
  final int index;
  final Note note;
  EditNotePage(this.close, this.refresh, this.index, this.note);

  @override
  Widget build(BuildContext context) {
    TextEditingController _title = TextEditingController(text: note.title),
        _body = TextEditingController(text: note.body);

    Future<void> edit(context) async {
      if (_title.text != note.title || _body.text != note.body) {
        await Note(_title.text, _body.text, note.created).editCard(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              duration: Duration(seconds: 3),
              elevation: 2,
              content: Text(
                'Changes Saved',
                style: Theme.of(context).textTheme.bodyText1,
              )),
        );
        refresh.call();
      }
    }

    return WillPopScope(
      onWillPop: () async {
        close.call();
        edit(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 88,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: IconButton(
                tooltip: 'Make a Copy',
                onPressed: () async {
                  await Note(_title.text, _body.text, DateTime.now()).addCard();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        duration: Duration(seconds: 3),
                        elevation: 2,
                        content: Text(
                          'Note Duplicated',
                          style: Theme.of(context).textTheme.bodyText1,
                        )),
                  );
                  Navigator.of(context).pop();
                  refresh.call();
                },
                icon: Icon(Icons.copy),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                tooltip: 'Delete Note',
                onPressed: () async {
                  close.call();
                  await Note(_title.text, _body.text, DateTime.now())
                      .removeCard(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        duration: Duration(seconds: 3),
                        elevation: 2,
                        content: Text(
                          'Note Deleted',
                          style: Theme.of(context).textTheme.bodyText1,
                        )),
                  );
                  refresh.call();
                },
                icon: Icon(Icons.delete),
              ),
            ),
          ],
        ),
        body: Container(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Form(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          cursorColor:
                              Theme.of(context).primaryColor == kGlacier
                                  ? kMatte
                                  : kGlacier,
                          controller: _title,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: "Title",
                          ),
                          style: Theme.of(context).textTheme.headline4,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.text,
                        ),
                        Text(
                          months[note.created.month - 1] +
                              " " +
                              note.created.day.toString() +
                              ", " +
                              note.created.year.toString(),
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: TextFormField(
                      cursorColor: Theme.of(context).primaryColor == kGlacier
                          ? kMatte
                          : kGlacier,
                      controller: _body,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: "Note",
                        hintMaxLines: null,
                      ),
                      style: Theme.of(context).textTheme.bodyText1,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
