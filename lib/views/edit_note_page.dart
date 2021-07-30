import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:notes/constants.dart';
import 'package:notes/model/note.dart';
import 'dart:async';
import 'package:undo/undo.dart';

class EscIntent extends Intent {
  const EscIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class EditNotePage extends StatelessWidget {
  final Function close, refresh;
  final int index;
  final Note note;
  EditNotePage(this.close, this.refresh, this.index, this.note);

  @override
  Widget build(BuildContext context) {
    ChangeStack changes = new ChangeStack(limit: 15);

    ValueNotifier<TextEditingValue> currentTitle =
            ValueNotifier(TextEditingValue(text: note.title)),
        currentBody = ValueNotifier(TextEditingValue(text: note.body));

    TextEditingValue lastStoredTitle = TextEditingValue(text: note.title),
        lastStoredBody = TextEditingValue(text: note.body);

    Future<void> edit(context) async {
      if (currentTitle.value.text != note.title ||
          currentBody.value.text != note.body) {
        await Note(
                currentTitle.value.text, currentBody.value.text, note.created)
            .editCard(index);
        refresh.call();
      }
    }

    return WillPopScope(
      onWillPop: () async {
        close.call();
        await edit(context);
        return false;
      },
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.escape): const EscIntent(),
          LogicalKeySet(LogicalKeyboardKey.exit): const EscIntent(),
          LogicalKeySet(LogicalKeyboardKey.undo): const UndoIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
              const UndoIntent(),
          LogicalKeySet(LogicalKeyboardKey.redo): const RedoIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
              const RedoIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
              LogicalKeyboardKey.keyZ): const RedoIntent(),
        },
        child: Actions(
          actions: {
            EscIntent: CallbackAction<EscIntent>(
              onInvoke: (EscIntent intent) async {
                close.call();
                await edit(context);
                return false;
              },
            ),
            UndoIntent: CallbackAction<UndoIntent>(
              onInvoke: (UndoIntent intent) {
                if (currentTitle.value != lastStoredTitle) {
                  var temp = currentTitle.value;
                  changes.add(
                    new Change<TextEditingValue>(
                      lastStoredTitle,
                      () => currentTitle.value = temp,
                      (val) => currentTitle.value = val,
                    ),
                  );
                }
                if (currentBody.value != lastStoredBody) {
                  var temp = currentBody.value;
                  changes.add(
                    new Change<TextEditingValue>(
                      lastStoredBody,
                      () => currentBody.value = temp,
                      (val) => currentBody.value = val,
                    ),
                  );
                }
                changes.undo();
                lastStoredTitle = currentTitle.value;
                lastStoredBody = currentBody.value;
              },
            ),
            RedoIntent: CallbackAction<RedoIntent>(
              onInvoke: (RedoIntent intent) {
                changes.redo();
                lastStoredTitle = currentTitle.value;
                lastStoredBody = currentBody.value;
              },
            ),
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 88,
              elevation: 0,
              actions: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: IconButton(
                        tooltip:
                            'Undo' + (Platform.isWindows ? " (Ctrl+Z)" : ""),
                        onPressed: () {
                          if (currentTitle.value != lastStoredTitle) {
                            var temp = currentTitle.value;
                            changes.add(
                              new Change<TextEditingValue>(
                                lastStoredTitle,
                                () => currentTitle.value = temp,
                                (val) => currentTitle.value = val,
                              ),
                            );
                          }
                          if (currentBody.value != lastStoredBody) {
                            var temp = currentBody.value;
                            changes.add(
                              new Change<TextEditingValue>(
                                lastStoredBody,
                                () => currentBody.value = temp,
                                (val) => currentBody.value = val,
                              ),
                            );
                          }
                          changes.undo();
                          lastStoredTitle = currentTitle.value;
                          lastStoredBody = currentBody.value;
                        },
                        icon: Icon(Icons.undo),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: IconButton(
                        tooltip:
                            'Redo' + (Platform.isWindows ? " (Ctrl+Y)" : ""),
                        onPressed: () {
                          changes.redo();
                          lastStoredTitle = currentTitle.value;
                          lastStoredBody = currentBody.value;
                        },
                        icon: Icon(Icons.redo),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 24,
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: IconButton(
                    tooltip: 'Make a Copy',
                    onPressed: () async {
                      close.call();
                      await Note(currentTitle.value.text,
                              currentBody.value.text, DateTime.now())
                          .addCard();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            duration: Duration(seconds: 3),
                            elevation: 2,
                            content: Text(
                              'Note Duplicated',
                              style: Theme.of(context).textTheme.bodyText1,
                            )),
                      );
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
                      await Note("", "", DateTime.now()).removeCard(index);
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
                            ValueListenableBuilder<TextEditingValue>(
                                valueListenable: currentTitle,
                                builder: (context, TextEditingValue curTitle,
                                    snapshot) {
                                  TextEditingController _title =
                                      TextEditingController();
                                  _title.value = curTitle;
                                  return TextFormField(
                                    cursorColor:
                                        Theme.of(context).primaryColor ==
                                                kGlacier
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
                                    style:
                                        Theme.of(context).textTheme.headline4,
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.text,
                                    onChanged: (val) {
                                      if (currentBody.value != lastStoredBody) {
                                        var temp = currentBody.value;
                                        changes.add(
                                          new Change<TextEditingValue>(
                                            lastStoredBody,
                                            () => currentBody.value = temp,
                                            (val) => currentBody.value = val,
                                          ),
                                        );
                                        lastStoredBody = currentBody.value;
                                      }
                                      currentTitle.value = _title.value;
                                      String changedText = "";
                                      if (val.length >
                                          lastStoredTitle.text.length) {
                                        for (int i = 0;
                                            i < lastStoredTitle.text.length;
                                            i++) {
                                          if (val[i] !=
                                              lastStoredTitle.text[i]) {
                                            changedText += val[i];
                                            if (i + 1 <
                                                lastStoredTitle.text.length) {
                                              val = val.substring(0, i) +
                                                  val.substring(i + 1);
                                            }
                                          }
                                        }
                                        if (changedText.isEmpty) {
                                          changedText = val.substring(
                                              lastStoredTitle.text.length);
                                        }
                                        if (changedText.contains('.') ||
                                            changedText.contains(',') ||
                                            changedText.contains('!') ||
                                            changedText.contains('?') ||
                                            changedText.contains(':') ||
                                            changedText.contains(';') ||
                                            changedText.contains('\"') ||
                                            changedText.contains('-') ||
                                            changedText.contains('_') ||
                                            changedText.contains(' ')) {
                                          changes.add(
                                            new Change<TextEditingValue>(
                                              lastStoredTitle,
                                              () => currentTitle.value =
                                                  _title.value,
                                              (val) => currentTitle.value = val,
                                            ),
                                          );
                                          lastStoredTitle = _title.value;
                                        }
                                      } else if (val.length <
                                          lastStoredTitle.text.length) {
                                        changes.add(
                                          new Change<TextEditingValue>(
                                            lastStoredTitle,
                                            () => currentTitle.value =
                                                _title.value,
                                            (val) => currentTitle.value = val,
                                          ),
                                        );
                                        lastStoredTitle = _title.value;
                                      }
                                    },
                                  );
                                }),
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
                        child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: currentBody,
                            builder:
                                (context, TextEditingValue curBody, snapshot) {
                              TextEditingController _body =
                                  TextEditingController();
                              _body.value = curBody;
                              return TextFormField(
                                autofocus: true,
                                cursorColor:
                                    Theme.of(context).primaryColor == kGlacier
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
                                onChanged: (val) {
                                  if (currentTitle.value != lastStoredTitle) {
                                    var temp = currentTitle.value;
                                    changes.add(
                                      new Change<TextEditingValue>(
                                        lastStoredTitle,
                                        () => currentTitle.value = temp,
                                        (val) => currentTitle.value = val,
                                      ),
                                    );
                                    lastStoredTitle = currentTitle.value;
                                  }
                                  currentBody.value = _body.value;
                                  String changedText = "";
                                  if (val.length > lastStoredBody.text.length) {
                                    for (int i = 0;
                                        i < lastStoredBody.text.length;
                                        i++) {
                                      if (val[i] != lastStoredBody.text[i]) {
                                        changedText += val[i];
                                        if (i + 1 <
                                            lastStoredBody.text.length) {
                                          val = val.substring(0, i) +
                                              val.substring(i + 1);
                                        }
                                      }
                                    }
                                    if (changedText.isEmpty) {
                                      changedText = val.substring(
                                          lastStoredBody.text.length);
                                    }
                                    if (changedText.contains('.') ||
                                        changedText.contains(',') ||
                                        changedText.contains('!') ||
                                        changedText.contains('?') ||
                                        changedText.contains(':') ||
                                        changedText.contains(';') ||
                                        changedText.contains('\"') ||
                                        changedText.contains('-') ||
                                        changedText.contains('_') ||
                                        changedText.contains(' ')) {
                                      changes.add(
                                        new Change<TextEditingValue>(
                                          lastStoredBody,
                                          () => currentBody.value = _body.value,
                                          (val) => currentBody.value = val,
                                        ),
                                      );
                                      lastStoredBody = _body.value;
                                    }
                                  } else if (val.length <
                                      lastStoredTitle.text.length) {
                                    changes.add(
                                      new Change<TextEditingValue>(
                                        lastStoredBody,
                                        () => currentBody.value = _body.value,
                                        (val) => currentBody.value = val,
                                      ),
                                    );
                                    lastStoredBody = _body.value;
                                  }
                                },
                                maxLines: null,
                              );
                            }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
