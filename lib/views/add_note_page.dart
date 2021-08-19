import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notes/Helpers/undo_rules.dart';
import 'package:notes/constants.dart';
import 'dart:async';
import 'package:notes/model/note.dart' as note;
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

class AddNotePage extends StatelessWidget {
  final Function close;
  AddNotePage(this.close);

  @override
  Widget build(BuildContext context) {
    ChangeStack changes = new ChangeStack(limit: 15);

    ValueNotifier<TextEditingValue> currentTitle =
            ValueNotifier(TextEditingValue.empty),
        currentBody = ValueNotifier(TextEditingValue.empty);

    TextEditingValue lastStoredTitle = TextEditingValue.empty,
        lastStoredBody = TextEditingValue.empty;

    Future<void> save(context) async {
      if (currentTitle.value.text.isNotEmpty ||
          currentBody.value.text.isNotEmpty) {
        await note.Note(
                currentTitle.value.text, currentBody.value.text, DateTime.now())
            .addCard();
        close.call();
      } else
        Navigator.of(context).pop();
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
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                  Timer(Duration(milliseconds: 200),
                      () async => await save(context));
                } else
                  await save(context);
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
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: IconButton(
                    tooltip: 'Undo' + (Platform.isWindows ? " (Ctrl+Z)" : ""),
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
                    tooltip: 'Redo' + (Platform.isWindows ? " (Ctrl+Y)" : ""),
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
            body: Container(
                child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Form(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(18, 0, 18, 0),
                      child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: currentTitle,
                          builder:
                              (context, TextEditingValue curTitle, snapshot) {
                            TextEditingController _title =
                                TextEditingController();
                            _title.value = curTitle;
                            return TextFormField(
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
                                if (UndoRules.shouldStore(lastStoredTitle.text,
                                    currentTitle.value.text)) {
                                  changes.add(
                                    new Change<TextEditingValue>(
                                      lastStoredTitle,
                                      () => currentTitle.value = _title.value,
                                      (val) => currentTitle.value = val,
                                    ),
                                  );
                                  lastStoredTitle = _title.value;
                                }
                              },
                            );
                          }),
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
                              textCapitalization: TextCapitalization.sentences,
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
            )),
          ),
        ),
      ),
    );
  }
}
