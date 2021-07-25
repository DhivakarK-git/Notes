import 'package:flutter/material.dart';
import 'package:notes/constants.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notes/model/note.dart';
import 'package:notes/views/NotesSearchPage.dart';
import 'package:notes/views/add_note_page.dart';
import 'package:notes/views/edit_note_page.dart';
import 'package:animations/animations.dart';

class NotesPage extends StatefulWidget {
  final bool darkMode, gridview;
  final Box<dynamic> box;
  NotesPage(this.darkMode, this.gridview, this.box);
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        title: Row(
          children: [
            Container(
              color: Colors.transparent,
              child: Center(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotesSearchPage(
                          widget.darkMode,
                          widget.box,
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.search_outlined,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 16,
            ),
            Text(
              "Notes",
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
        actions: [
          Container(
            color: Colors.transparent,
            child: Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    widget.box.put('gridview', !widget.gridview);
                  });
                },
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.gridview
                          ? Icons.grid_view_outlined
                          : Icons.view_agenda_outlined,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 8,
          ),
          Container(
            color: Colors.transparent,
            child: Center(
              child: InkWell(
                onTap: () {
                  widget.box.put('darkMode', !widget.darkMode);
                },
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.darkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 16,
          ),
        ],
        elevation: 0,
      ),
      floatingActionButton: OpenContainer(
          transitionType: ContainerTransitionType.fadeThrough,
          transitionDuration: Duration(milliseconds: 200),
          openBuilder: (context, _) => SafeArea(child: AddNotePage(() {
                setState(() {});
                Navigator.of(context).pop();
              })),
          openColor: Theme.of(context).primaryColor,
          closedElevation: 0,
          closedColor: Colors.transparent,
          closedBuilder: (context, _) => Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyan[300],
                ),
                child: Icon(
                  Icons.add,
                  color: kMatte,
                ),
              )),
      body: StreamBuilder(
        stream: Hive.openBox('notes').asStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError)
              return Text(snapshot.error.toString());
            else {
              final notesBox = Hive.box('notes');
              if (notesBox.length == 0)
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
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                        SizedBox(
                          height: 96,
                        ),
                      ],
                    ),
                  ),
                );
              return Container(
                child: widget.gridview
                    ? GridView.builder(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: notesBox.length,
                        physics: BouncingScrollPhysics(),
                        gridDelegate:
                            new SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          crossAxisCount: 2,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final note = notesBox
                              .getAt(notesBox.length - index - 1) as Note;
                          return OpenContainer(
                            transitionType: ContainerTransitionType.fadeThrough,
                            transitionDuration: Duration(milliseconds: 300),
                            openBuilder: (context, _) => SafeArea(
                              child: EditNotePage(
                                () {
                                  setState(() {});
                                  Navigator.of(context).pop();
                                },
                                notesBox.length - index - 1,
                                note,
                              ),
                            ),
                            openColor: Theme.of(context).primaryColor,
                            closedElevation: 0,
                            closedColor: Theme.of(context).primaryColor,
                            closedBuilder: (context, _) => Container(
                              child: Card(
                                elevation: 0,
                                color: notes[(notesBox.length - index - 1) % 8],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        note.title != ''
                                            ? note.title
                                            : note.body,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5!
                                            .copyWith(color: kMatte),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines:
                                            MediaQuery.of(context).size.width ~/
                                                100,
                                      ),
                                      Text(
                                        months[note.created.month - 1] +
                                            " " +
                                            note.created.day.toString() +
                                            ", " +
                                            note.created.year.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2!
                                            .copyWith(color: kMatte),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                        itemCount: notesBox.length,
                        physics: BouncingScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          final note = notesBox
                              .getAt(notesBox.length - index - 1) as Note;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: OpenContainer(
                              transitionType:
                                  ContainerTransitionType.fadeThrough,
                              transitionDuration: Duration(milliseconds: 300),
                              openBuilder: (context, _) => SafeArea(
                                child: EditNotePage(
                                  () {
                                    setState(() {});
                                    Navigator.of(context).pop();
                                  },
                                  (notesBox.length - index - 1),
                                  note,
                                ),
                              ),
                              openColor: Theme.of(context).primaryColor,
                              closedElevation: 0,
                              closedColor: Theme.of(context).primaryColor,
                              closedBuilder: (context, _) => Container(
                                child: Card(
                                  elevation: 0,
                                  color:
                                      notes[(notesBox.length - index - 1) % 8],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          note.title != ''
                                              ? note.title
                                              : note.body,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5!
                                              .copyWith(color: kMatte),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: MediaQuery.of(context)
                                                  .size
                                                  .width ~/
                                              100,
                                        ),
                                        Text(
                                          months[note.created.month - 1] +
                                              " " +
                                              note.created.day.toString() +
                                              ", " +
                                              note.created.year.toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2!
                                              .copyWith(color: kMatte),
                                        ),
                                        SizedBox(
                                          height: 16,
                                        ),
                                        Text(
                                          note.body,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(color: kMatte),
                                          maxLines: null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              );
            }
          } else
            return Container();
        },
      ),
    ));
  }
}
