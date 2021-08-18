import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notes/Helpers/undo_rules.dart';
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
    // does this need a limit?
    ChangeStack changes = new ChangeStack();

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
                if (Platform.isWindows)
                  SizedBox(
                    width: 24,
                  ),
                if (Platform.isWindows)
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
                      icon: Icon(Icons.file_copy),
                    ),
                  ),
                if (Platform.isWindows)
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
                if (Platform.isAndroid || Platform.isIOS)
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(Icons.file_copy),
                          title: Text('Make a Copy'),
                          onTap: () async {
                            close.call();
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
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  )),
                            );
                            refresh.call();
                          },
                        ),
                      ),
                      PopupMenuItem(
                        height: 0,
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete Note'),
                          onTap: () async {
                            close.call();
                            close.call();
                            await Note("", "", DateTime.now())
                                .removeCard(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  duration: Duration(seconds: 3),
                                  elevation: 2,
                                  content: Text(
                                    'Note Deleted',
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  )),
                            );
                            refresh.call();
                          },
                        ),
                      ),
                    ],
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
                                      if (UndoRules.shouldStore(
                                          lastStoredTitle.text,
                                          currentTitle.value.text)) {
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
                                  if (UndoRules.shouldStore(lastStoredBody.text,
                                      currentBody.value.text)) {
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
