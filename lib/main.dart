import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes/constants.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notes/views/NotesPage.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:notes/model/note.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  Hive.registerAdapter(
    NoteAdapter(),
  );
  await Hive.openBox('darkModeBox');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<dynamic>>(
        valueListenable: Hive.box('darkModeBox').listenable(),
        builder: (context, box, widget) {
          bool darkMode = box.get('darkMode',
              defaultValue: Theme.of(context).brightness == Brightness.dark);
          bool gridview = box.get('gridview', defaultValue: true);
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            systemNavigationBarColor:
                darkMode ? kMatte : kGlacier, // navigation bar color
            statusBarColor: kMatte, // status bar color
          ));
          return MaterialApp(
            title: 'Notes',
            themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData.light().copyWith(
              primaryColor: kGlacier,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              scaffoldBackgroundColor: kGlacier,
              cardColor: kFrost,
              primaryIconTheme: IconThemeData(color: kMatte),
              textTheme: TextTheme(
                headline1: GoogleFonts.poppins(
                  fontSize: 93,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1.5,
                  color: kMatte,
                ),
                headline2: GoogleFonts.poppins(
                  fontSize: 58,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.5,
                  color: kMatte,
                ),
                headline3: GoogleFonts.poppins(
                  fontSize: 46,
                  fontWeight: FontWeight.w400,
                  color: kMatte,
                ),
                headline4: GoogleFonts.poppins(
                  fontSize: 33,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.25,
                  color: kMatte,
                ),
                headline5: GoogleFonts.poppins(
                  fontSize: 23,
                  fontWeight: FontWeight.w400,
                  color: kMatte,
                ),
                headline6: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15,
                  color: kMatte,
                ),
                subtitle1: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.15,
                  color: kMatte,
                ),
                subtitle2: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  color: kMatte,
                ),
                bodyText1: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                  color: kMatte,
                ),
                bodyText2: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.25,
                  color: kMatte,
                ),
                button: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.25,
                  color: kMatte,
                ),
                caption: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.4,
                  color: kMatte,
                ),
                overline: GoogleFonts.openSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.5,
                  color: kMatte,
                ),
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              primaryColor: kMatte,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              scaffoldBackgroundColor: kMatte,
              cardColor: kShadow,
              textTheme: TextTheme(
                headline1: GoogleFonts.poppins(
                    fontSize: 93,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1.5),
                headline2: GoogleFonts.poppins(
                    fontSize: 58,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.5),
                headline3: GoogleFonts.poppins(
                    fontSize: 46, fontWeight: FontWeight.w400),
                headline4: GoogleFonts.poppins(
                    fontSize: 33,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.25),
                headline5: GoogleFonts.poppins(
                    fontSize: 23, fontWeight: FontWeight.w400),
                headline6: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.15),
                subtitle1: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.15),
                subtitle2: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1),
                bodyText1: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5),
                bodyText2: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.25),
                button: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.25),
                caption: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.4),
                overline: GoogleFonts.openSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5),
              ),
            ),
            debugShowCheckedModeBanner: false,
            home: NotesPage(darkMode, gridview, box),
          );
        });
  }
}
