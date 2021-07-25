import 'package:flutter/material.dart';
import 'package:notes/constants.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notes/model/note.dart';
import 'package:notes/views/edit_note_page.dart';
import 'package:animations/animations.dart';

class NotesSearchPage extends StatefulWidget {
  final bool darkMode;
  final Box<dynamic> box;
  NotesSearchPage(this.darkMode, this.box);
  @override
  _NotesSearchPageState createState() => _NotesSearchPageState();
}

class _NotesSearchPageState extends State<NotesSearchPage> {
  final TextEditingController _filter = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        actions: [
          Container(
            width: MediaQuery.of(context).size.width - 56,
            child: Center(
              child: TextFormField(
                autofocus: true,
                cursorColor: Theme.of(context).primaryColor == kGlacier
                    ? kMatte
                    : kGlacier,
                controller: _filter,
                onChanged: (val) {
                  setState(() {});
                },
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
              ),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: StreamBuilder(
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
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                        SizedBox(
                          height: 96,
                        ),
                      ],
                    ),
                  ),
                );
              final notesList = notesMap
                  .where(
                    (Note) =>
                        Note.title
                            .toString()
                            .toLowerCase()
                            .contains(_filter.text.toLowerCase()) ||
                        Note.body
                            .toString()
                            .toLowerCase()
                            .contains(_filter.text.toLowerCase()),
                  )
                  .toList();
              return Container(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: notesList.length,
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final note =
                        notesList[notesList.length - index - 1] as Note;
                    return OpenContainer(
                      transitionType: ContainerTransitionType.fadeThrough,
                      transitionDuration: Duration(milliseconds: 300),
                      openBuilder: (context, _) => SafeArea(
                        child: EditNotePage(
                          () {
                            setState(() {});
                            Navigator.of(context).pop();
                          },
                          notesList.length - index - 1,
                          note,
                        ),
                      ),
                      openColor: Theme.of(context).primaryColor,
                      closedElevation: 0,
                      closedColor: Theme.of(context).primaryColor,
                      closedBuilder: (context, _) => Container(
                        child: Card(
                          elevation: 0,
                          color: notes[(notesList.length - index - 1) % 8],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  note.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5!
                                      .copyWith(color: kMatte),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines:
                                      MediaQuery.of(context).size.width ~/ 100,
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
                    );
                  },
                ),
              );
            }
          } else
            //TODO: CHANge here
            return Container();
        },
      ),
    ));
  }
}
