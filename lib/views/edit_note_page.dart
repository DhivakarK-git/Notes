import 'package:flutter/material.dart';
import 'package:notes/constants.dart';
import 'package:notes/model/note.dart';

class EditNotePage extends StatelessWidget {
  final Function close;
  final int index;
  final Note note;
  EditNotePage(this.close, this.index, this.note);

  @override
  Widget build(BuildContext context) {
    TextEditingController _title = TextEditingController(text: note.title),
        _body = TextEditingController(text: note.body);

    return WillPopScope(
      onWillPop: () async {
        if (_title.text != note.title || _body.text != note.body) {
          await Note(_title.text, _body.text, note.created).editCard(index);
          close.call();
        } else
          Navigator.of(context).pop();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              if (_title.text != note.title || _body.text != note.body)
                await Note(_title.text, _body.text, note.created)
                    .editCard(index);
              close.call();
            },
          ),
          toolbarHeight: 88,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: InkWell(
                onTap: () async {
                  await Note(_title.text, _body.text, DateTime.now())
                      .removeCard(index);
                  close.call();
                },
                child: Card(
                  color: Colors.cyan[200],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: kMatte,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "DELETE",
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
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Form(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 32),
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
