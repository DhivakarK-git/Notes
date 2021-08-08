import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notes/constants.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notes/model/note.dart';
import 'package:notes/views/edit_note_page.dart';
import 'package:animations/animations.dart';

class NotesSearchPage extends StatefulWidget {
  final Box<dynamic> box;
  final Function refresh;
  NotesSearchPage(this.box, this.refresh);

  @override
  _NotesSearchPageState createState() => _NotesSearchPageState();
}

class _NotesSearchPageState extends State<NotesSearchPage> {
  final TextEditingController _filter = new TextEditingController();
  ValueNotifier<String> listShouldChange = ValueNotifier("");
  ValueNotifier<bool> delete = ValueNotifier(false);
  List<int> deleteValues = [];
  ValueNotifier<int> deleteValuesLength = ValueNotifier(0);

  int count = 0;

  String copyTitle = '', copyBody = '';

  Future<void> deleteAll() async {
    deleteValues.sort();
    for (int index = deleteValuesLength.value - 1; index >= 0; index--)
      await Note("", "", DateTime.now()).removeCard(deleteValues[index]);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      key: ValueKey("Search"),
      onWillPop: () async {
        if (delete.value) {
          delete.value = false;
          deleteValues.clear();
          deleteValuesLength.value = 0;
        } else {
          if (FocusScope.of(context).hasFocus) {
            FocusScope.of(context).unfocus();
          }
          Timer(Duration(milliseconds: 108), () async => widget.refresh.call());
        }
        return false;
      },
      child: ValueListenableBuilder<bool>(
          valueListenable: delete,
          builder: (context, bool deleteMode, snapshot) {
            return Scaffold(
              appBar: deleteMode
                  ? AppBar(
                      key: ValueKey(0),
                      toolbarHeight: 88,
                      title: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              delete.value = false;
                              deleteValues.clear();
                              deleteValuesLength.value = 0;
                            },
                            icon: Icon(Icons.close),
                          ),
                          SizedBox(width: 16),
                          ValueListenableBuilder<int>(
                              valueListenable: deleteValuesLength,
                              builder:
                                  (context, int deleteValuesLength, snapshot) {
                                return Text(
                                  "${deleteValuesLength} Selected",
                                  style: Theme.of(context).textTheme.headline6,
                                );
                              }),
                        ],
                      ),
                      elevation: 0,
                      actions: [
                        ValueListenableBuilder<int>(
                            valueListenable: deleteValuesLength,
                            builder: (context, int len, snapshot) {
                              if (len == 1)
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: IconButton(
                                    tooltip: 'Make a Copy',
                                    onPressed: () async {
                                      await Note(copyTitle, copyBody,
                                              DateTime.now())
                                          .addCard();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            duration: Duration(seconds: 3),
                                            elevation: 2,
                                            content: Text(
                                              'Note Duplicated',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1,
                                            )),
                                      );
                                      delete.value = false;
                                      deleteValues.clear();
                                      deleteValuesLength.value = 0;
                                      widget.refresh.call();
                                    },
                                    icon: Icon(Icons.file_copy),
                                  ),
                                );
                              else
                                return Container();
                            }),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            onPressed: () async {
                              await deleteAll();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    duration: Duration(seconds: 3),
                                    elevation: 2,
                                    content: Text(
                                      deleteValuesLength.value > 1
                                          ? '${deleteValuesLength.value} Notes Deleted'
                                          : 'Note Deleted',
                                      style:
                                          Theme.of(context).textTheme.bodyText1,
                                    )),
                              );
                              delete.value = false;
                              deleteValues.clear();
                              deleteValuesLength.value = 0;
                              widget.refresh.call();
                            },
                            icon: Icon(Icons.delete),
                          ),
                        ),
                      ],
                    )
                  : AppBar(
                      toolbarHeight: 88,
                      leading: IconButton(
                        onPressed: () {
                          if (FocusScope.of(context).hasFocus) {
                            FocusScope.of(context).unfocus();
                          }
                          Timer(Duration(milliseconds: 108),
                              () async => widget.refresh.call());
                        },
                        icon: Icon(Icons.arrow_back),
                      ),
                      title: TextFormField(
                        autofocus: true,
                        cursorColor: Theme.of(context).primaryColor == kGlacier
                            ? kMatte
                            : kGlacier,
                        controller: _filter,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: "Search your notes",
                        ),
                        style: Theme.of(context).textTheme.bodyText1,
                        textInputAction: TextInputAction.done,
                        onChanged: (val) {
                          listShouldChange.value = val;
                        },
                      ),
                      elevation: 0,
                    ),
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(child: child, opacity: animation);
                },
                child: StreamBuilder(
                  key: ValueKey<int>(count == 1 ? --count : ++count),
                  stream: Hive.openBox('notes').asStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError)
                        return Text(snapshot.error.toString());
                      else {
                        final notesMap = Hive.box('notes').toMap().values;
                        if (notesMap.length == 0)
                          return Container(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lightbulb_rounded,
                                    size: 64,
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    "Notes you add appear here",
                                    style:
                                        Theme.of(context).textTheme.bodyText2,
                                  ),
                                  SizedBox(
                                    height: 96,
                                  ),
                                ],
                              ),
                            ),
                          );
                        else {
                          return ValueListenableBuilder<String>(
                              valueListenable: listShouldChange,
                              builder: (context, String filter, Widget) {
                                final notesInitialList = notesMap.toList();
                                final notesList = notesMap
                                    .where(
                                      (Note) =>
                                          Note.title
                                              .toString()
                                              .toLowerCase()
                                              .contains(filter.toLowerCase()) ||
                                          Note.body
                                              .toString()
                                              .toLowerCase()
                                              .contains(filter.toLowerCase()),
                                    )
                                    .toList();
                                return Container(
                                  key: PageStorageKey<String>('list'),
                                  child: ValueListenableBuilder<int>(
                                      valueListenable: deleteValuesLength,
                                      builder: (context, int len, snapshot) {
                                        return ListView.builder(
                                          padding: EdgeInsets.fromLTRB(
                                              16, 0, 16, 16),
                                          itemCount: notesList.length,
                                          physics: BouncingScrollPhysics(),
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            if (notesInitialList.contains(
                                                notesList[notesList.length -
                                                    index -
                                                    1])) {
                                              final note = notesList[
                                                  notesList.length -
                                                      index -
                                                      1] as Note;
                                              var currindex = notesInitialList
                                                  .indexOf(notesList[
                                                      notesList.length -
                                                          index -
                                                          1]);
                                              return InkWell(
                                                onTap: () {
                                                  if (deleteMode) {
                                                    if (deleteValues
                                                        .contains(currindex)) {
                                                      deleteValues
                                                          .remove(currindex);
                                                      deleteValuesLength
                                                          .value--;
                                                      if (deleteValues.length ==
                                                          0) {
                                                        delete.value = false;
                                                        deleteValues.clear();
                                                        deleteValuesLength
                                                            .value = 0;
                                                      }
                                                      if (deleteValues.length ==
                                                          1) {
                                                        final copyNote =
                                                            notesInitialList[
                                                                deleteValues[
                                                                    0]] as Note;
                                                        copyBody =
                                                            copyNote.body;
                                                        copyTitle =
                                                            copyNote.title;
                                                      } else {
                                                        copyBody = '';
                                                        copyTitle = '';
                                                      }
                                                    } else {
                                                      deleteValues
                                                          .add(currindex);
                                                      deleteValuesLength
                                                          .value++;
                                                    }
                                                  }
                                                },
                                                onLongPress: () {
                                                  if (!deleteMode) {
                                                    delete.value = true;
                                                    deleteValues.add(currindex);
                                                    deleteValuesLength.value++;
                                                    if (deleteValuesLength
                                                            .value ==
                                                        1) {
                                                      final copyNote =
                                                          notesInitialList[
                                                              deleteValues[
                                                                  0]] as Note;
                                                      copyBody = copyNote.body;
                                                      copyTitle =
                                                          copyNote.title;
                                                    } else {
                                                      copyBody = '';
                                                      copyTitle = '';
                                                    }
                                                  } else {
                                                    if (deleteValues
                                                        .contains(currindex)) {
                                                      deleteValues
                                                          .remove(currindex);
                                                      deleteValuesLength
                                                          .value--;

                                                      if (deleteValues.length ==
                                                          0) {
                                                        delete.value = false;
                                                        deleteValues.clear();
                                                        deleteValuesLength
                                                            .value = 0;
                                                      }
                                                      if (deleteValues.length ==
                                                          1) {
                                                        final copyNote =
                                                            notesInitialList[
                                                                deleteValues[
                                                                    0]] as Note;
                                                        copyBody =
                                                            copyNote.body;
                                                        copyTitle =
                                                            copyNote.title;
                                                      } else {
                                                        copyBody = '';
                                                        copyTitle = '';
                                                      }
                                                    } else {
                                                      deleteValues
                                                          .add(currindex);
                                                      deleteValuesLength
                                                          .value++;
                                                    }
                                                  }
                                                },
                                                child: deleteMode
                                                    ? Card(
                                                        elevation: 0,
                                                        color: deleteValues
                                                                .contains(
                                                                    currindex)
                                                            ? notes[
                                                                (currindex) % 8]
                                                            : Theme.of(context)
                                                                .cardColor,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16.0),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                note.title != ''
                                                                    ? note.title
                                                                    : note.body,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .headline5!
                                                                    .copyWith(
                                                                        color: !deleteValues.contains(currindex)
                                                                            ? Theme.of(context).iconTheme.color
                                                                            : kMatte),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: MediaQuery.of(context).size.width ~/
                                                                            100 >
                                                                        3
                                                                    ? 3
                                                                    : MediaQuery.of(context)
                                                                            .size
                                                                            .width ~/
                                                                        100,
                                                              ),
                                                              Text(
                                                                months[note.created
                                                                            .month -
                                                                        1] +
                                                                    " " +
                                                                    note.created
                                                                        .day
                                                                        .toString() +
                                                                    ", " +
                                                                    note.created
                                                                        .year
                                                                        .toString(),
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyText2!
                                                                    .copyWith(
                                                                        color: !deleteValues.contains(currindex)
                                                                            ? Theme.of(context).iconTheme.color
                                                                            : kMatte),
                                                              ),
                                                              SizedBox(
                                                                height: 16,
                                                              ),
                                                              Text(
                                                                note.body,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyText1!
                                                                    .copyWith(
                                                                        color: !deleteValues.contains(currindex)
                                                                            ? Theme.of(context).iconTheme.color
                                                                            : kMatte),
                                                                maxLines: null,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                    : OpenContainer(
                                                        transitionType:
                                                            ContainerTransitionType
                                                                .fadeThrough,
                                                        transitionDuration:
                                                            Duration(
                                                                milliseconds:
                                                                    200),
                                                        openBuilder:
                                                            (context, _) =>
                                                                SafeArea(
                                                          child: EditNotePage(
                                                            () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            () {
                                                              setState(() {});
                                                            },
                                                            currindex,
                                                            note,
                                                          ),
                                                        ),
                                                        openColor:
                                                            Theme.of(context)
                                                                .primaryColor,
                                                        closedElevation: 0,
                                                        closedColor:
                                                            Theme.of(context)
                                                                .primaryColor,
                                                        closedBuilder:
                                                            (context, _) =>
                                                                Container(
                                                          child: Card(
                                                            elevation: 0,
                                                            color: notes[
                                                                currindex % 8],
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .all(
                                                                      16.0),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    note.title !=
                                                                            ''
                                                                        ? note
                                                                            .title
                                                                        : note
                                                                            .body,
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .headline5!
                                                                        .copyWith(
                                                                            color:
                                                                                kMatte),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: MediaQuery.of(context).size.width ~/
                                                                                100 >
                                                                            3
                                                                        ? 3
                                                                        : MediaQuery.of(context).size.width ~/
                                                                            100,
                                                                  ),
                                                                  Text(
                                                                    months[note.created.month -
                                                                            1] +
                                                                        " " +
                                                                        note.created
                                                                            .day
                                                                            .toString() +
                                                                        ", " +
                                                                        note.created
                                                                            .year
                                                                            .toString(),
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .bodyText2!
                                                                        .copyWith(
                                                                            color:
                                                                                kMatte),
                                                                  ),
                                                                  SizedBox(
                                                                    height: 16,
                                                                  ),
                                                                  Text(
                                                                    note.body,
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .bodyText1!
                                                                        .copyWith(
                                                                            color:
                                                                                kMatte),
                                                                    maxLines:
                                                                        null,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                              );
                                            } else
                                              return Container();
                                          },
                                        );
                                      }),
                                );
                              });
                        }
                      }
                    } else
                      return Container();
                  },
                ),
              ),
            );
          }),
    );
  }
}
