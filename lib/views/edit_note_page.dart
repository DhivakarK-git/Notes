import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:notes/Helpers/undo_rules.dart';
import 'package:notes/constants.dart';
import 'package:notes/model/note.dart';
import 'package:rich_text_controller/rich_text_controller.dart';
import 'dart:async';
import 'package:undo/undo.dart';
import 'package:url_launcher/url_launcher.dart';

RegExp urls = new RegExp(
  r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?",
);

RegExp hashtags = new RegExp(
  r"\B#[a-zA-Z0-9]+\b",
);

RegExp phonenos = new RegExp(
  r'(?:[+0]9)?[0-9]{10}',
);

RegExp emails = new RegExp(
  r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?",
);

const double _kHandleSize = 22.0;
const double _kToolbarContentDistanceBelow = _kHandleSize - 2.0;
const double _kToolbarContentDistance = 8.0;
const double _kToolbarScreenPadding = 8.0;
const double _kToolbarWidth = 222.0;

class _DesktopTextSelectionControls extends TextSelectionControls {
  final Function searchBack, save;
  _DesktopTextSelectionControls(this.searchBack, this.save);

  /// Desktop has no text selection handles.
  @override
  Size getHandleSize(double textLineHeight) {
    return Size.zero;
  }

  /// Builder for the Material-style desktop copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return _DesktopTextSelectionControlsToolbar(
      clipboardStatus: clipboardStatus,
      endpoints: endpoints,
      globalEditableRegion: globalEditableRegion,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate)
          ? () => handleCopy(delegate, clipboardStatus)
          : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll:
          canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
      handleCustomButton: delegate.canlinkselect()
          ? () {
              delegate.linkselect(searchBack, save);
              delegate.hideToolbar();
            }
          : null,
      selectionMidpoint: selectionMidpoint,
      lastSecondaryTapDownPosition: lastSecondaryTapDownPosition,
      textLineHeight: textLineHeight,
    );
  }

  /// Builds the text selection handles, but desktop has none.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type,
      double textLineHeight) {
    return const SizedBox.shrink();
  }

  /// Gets the position for the text selection handles, but desktop has none.
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return Offset.zero;
  }

  @override
  bool canSelectAll(TextSelectionDelegate delegate) {
    // Allow SelectAll when selection is not collapsed, unless everything has
    // already been selected. Same behavior as Android.
    final TextEditingValue value = delegate.textEditingValue;
    return delegate.selectAllEnabled &&
        value.text.isNotEmpty &&
        !(value.selection.start == 0 &&
            value.selection.end == value.text.length);
  }
}

// Generates the child that's passed into DesktopTextSelectionToolbar.
class _DesktopTextSelectionControlsToolbar extends StatefulWidget {
  const _DesktopTextSelectionControlsToolbar({
    Key? key,
    required this.clipboardStatus,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.handleCopy,
    required this.handleCut,
    required this.handlePaste,
    required this.handleSelectAll,
    required this.selectionMidpoint,
    required this.textLineHeight,
    required this.lastSecondaryTapDownPosition,
    required this.handleCustomButton,
  }) : super(key: key);

  final ClipboardStatusNotifier? clipboardStatus;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final VoidCallback? handleCopy;
  final VoidCallback? handleCut;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;
  final VoidCallback? handleCustomButton;
  final Offset? lastSecondaryTapDownPosition;
  final Offset selectionMidpoint;
  final double textLineHeight;

  @override
  _DesktopTextSelectionControlsToolbarState createState() =>
      _DesktopTextSelectionControlsToolbarState();
}

class _DesktopTextSelectionControlsToolbarState
    extends State<_DesktopTextSelectionControlsToolbar> {
  ClipboardStatusNotifier? _clipboardStatus;

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.handlePaste != null) {
      _clipboardStatus = widget.clipboardStatus ?? ClipboardStatusNotifier();
      _clipboardStatus!.addListener(_onChangedClipboardStatus);
      _clipboardStatus!.update();
    }
  }

  @override
  void didUpdateWidget(_DesktopTextSelectionControlsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clipboardStatus != widget.clipboardStatus) {
      if (_clipboardStatus != null) {
        _clipboardStatus!.removeListener(_onChangedClipboardStatus);
        _clipboardStatus!.dispose();
      }
      _clipboardStatus = widget.clipboardStatus ?? ClipboardStatusNotifier();
      _clipboardStatus!.addListener(_onChangedClipboardStatus);
      if (widget.handlePaste != null) {
        _clipboardStatus!.update();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    // When used in an Overlay, this can be disposed after its creator has
    // already disposed _clipboardStatus.
    if (_clipboardStatus != null && !_clipboardStatus!.disposed) {
      _clipboardStatus!.removeListener(_onChangedClipboardStatus);
      if (widget.clipboardStatus == null) {
        _clipboardStatus!.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render the menu until the state of the clipboard is known.
    if (widget.handlePaste != null &&
        _clipboardStatus!.value == ClipboardStatus.unknown) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final Offset midpointAnchor = Offset(
      (widget.selectionMidpoint.dx - widget.globalEditableRegion.left).clamp(
        mediaQuery.padding.left,
        mediaQuery.size.width - mediaQuery.padding.right,
      ),
      widget.selectionMidpoint.dy - widget.globalEditableRegion.top,
    );

    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final List<Widget> items = <Widget>[];

    void addToolbarButton(
      String text,
      VoidCallback onPressed,
    ) {
      items.add(_DesktopTextSelectionToolbarButton.text(
        context: context,
        onPressed: onPressed,
        text: text,
      ));
    }

    if (widget.handleCustomButton != null) {
      addToolbarButton("Open", widget.handleCustomButton!);
    }
    if (widget.handleCut != null) {
      addToolbarButton(localizations.cutButtonLabel, widget.handleCut!);
    }
    if (widget.handleCopy != null) {
      addToolbarButton(localizations.copyButtonLabel, widget.handleCopy!);
    }
    if (widget.handlePaste != null &&
        _clipboardStatus!.value == ClipboardStatus.pasteable) {
      addToolbarButton(localizations.pasteButtonLabel, widget.handlePaste!);
    }
    if (widget.handleSelectAll != null) {
      addToolbarButton(
          localizations.selectAllButtonLabel, widget.handleSelectAll!);
    }

    // If there is no option available, build an empty widget.
    if (items.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return _DesktopTextSelectionToolbar(
      anchor: widget.lastSecondaryTapDownPosition ?? midpointAnchor,
      children: items,
    );
  }
}

/// A Material-style desktop text selection toolbar.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting
/// text.
///
/// Tries to position itself as closesly as possible to [anchor] while remaining
/// fully on-screen.
///
/// See also:
///
///  * [_DesktopTextSelectionControls.buildToolbar], where this is used by
///    default to build a Material-style desktop toolbar.
///  * [TextSelectionToolbar], which is similar, but builds an Android-style
///    toolbar.
class _DesktopTextSelectionToolbar extends StatelessWidget {
  /// Creates an instance of _DesktopTextSelectionToolbar.
  const _DesktopTextSelectionToolbar({
    Key? key,
    required this.anchor,
    required this.children,
    this.toolbarBuilder = _defaultToolbarBuilder,
  })  : assert(children.length > 0),
        super(key: key);

  /// The point at which the toolbar will attempt to position itself as closely
  /// as possible.
  final Offset anchor;

  /// {@macro flutter.material.TextSelectionToolbar.children}
  ///
  /// See also:
  ///   * [DesktopTextSelectionToolbarButton], which builds a default
  ///     Material-style desktop text selection toolbar text button.
  final List<Widget> children;

  /// {@macro flutter.material.TextSelectionToolbar.toolbarBuilder}
  ///
  /// The given anchor and isAbove can be used to position an arrow, as in the
  /// default toolbar.
  final ToolbarBuilder toolbarBuilder;

  // Builds a desktop toolbar in the Material style.
  static Widget _defaultToolbarBuilder(BuildContext context, Widget child) {
    return SizedBox(
      width: _kToolbarWidth,
      child: Material(
        borderRadius: const BorderRadius.all(Radius.circular(7.0)),
        clipBehavior: Clip.antiAlias,
        elevation: 1.0,
        type: MaterialType.card,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final double paddingAbove = mediaQuery.padding.top + _kToolbarScreenPadding;
    final Offset localAdjustment = Offset(_kToolbarScreenPadding, paddingAbove);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _kToolbarScreenPadding,
        paddingAbove,
        _kToolbarScreenPadding,
        _kToolbarScreenPadding,
      ),
      child: CustomSingleChildLayout(
        delegate: DesktopTextSelectionToolbarLayoutDelegate(
          anchor: anchor - localAdjustment,
        ),
        child: toolbarBuilder(
            context,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            )),
      ),
    );
  }
}

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
);

const EdgeInsets _kToolbarButtonPadding = EdgeInsets.fromLTRB(
  20.0,
  0.0,
  20.0,
  3.0,
);

/// A [TextButton] for the Material desktop text selection toolbar.
class _DesktopTextSelectionToolbarButton extends StatelessWidget {
  /// Creates an instance of DesktopTextSelectionToolbarButton.
  const _DesktopTextSelectionToolbarButton({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  /// Create an instance of [_DesktopTextSelectionToolbarButton] whose child is
  /// a [Text] widget in the style of the Material text selection toolbar.
  _DesktopTextSelectionToolbarButton.text({
    Key? key,
    required BuildContext context,
    required this.onPressed,
    required String text,
  })  : child = Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: _kToolbarButtonFontStyle.copyWith(
            color: Theme.of(context).colorScheme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        super(key: key);

  /// {@macro flutter.material.TextSelectionToolbarTextButton.onPressed}
  final VoidCallback onPressed;

  /// {@macro flutter.material.TextSelectionToolbarTextButton.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.colorScheme.brightness == Brightness.dark;
    final Color primary = isDark ? Colors.white : Colors.black87;

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          primary: primary,
          shape: const RoundedRectangleBorder(),
          minimumSize: const Size(kMinInteractiveDimension, 36.0),
          padding: _kToolbarButtonPadding,
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

class OpenTextSelectionControls extends MaterialTextSelectionControls {
  final Function searchBack, save;
  OpenTextSelectionControls(this.searchBack, this.save);
  // Padding between the toolbar and the anchor.
  /// Builder for material-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return OpenTextSelectionControlsToolbar(
      globalEditableRegion: globalEditableRegion,
      textLineHeight: textLineHeight,
      selectionMidpoint: selectionMidpoint,
      endpoints: endpoints,
      delegate: delegate,
      clipboardStatus: clipboardStatus,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate)
          ? () => handleCopy(delegate, clipboardStatus)
          : null,
      handleCustomButton: delegate.canlinkselect()
          ? () {
              delegate.linkselect(searchBack, save);
              delegate.hideToolbar();
            }
          : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll:
          canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
    );
  }
}

class OpenTextSelectionControlsToolbar extends StatefulWidget {
  const OpenTextSelectionControlsToolbar({
    Key? key,
    required this.clipboardStatus,
    required this.delegate,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.handleCustomButton,
    required this.handleCut,
    required this.handleCopy,
    required this.handlePaste,
    required this.handleSelectAll,
    required this.selectionMidpoint,
    required this.textLineHeight,
  }) : super(key: key);

  final ClipboardStatusNotifier clipboardStatus;
  final TextSelectionDelegate delegate;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final VoidCallback? handleCustomButton;
  final VoidCallback? handleCut;
  final VoidCallback? handleCopy;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;
  final Offset selectionMidpoint;
  final double textLineHeight;

  @override
  OpenTextSelectionControlsToolbarState createState() =>
      OpenTextSelectionControlsToolbarState();
}

class OpenTextSelectionControlsToolbarState
    extends State<OpenTextSelectionControlsToolbar>
    with TickerProviderStateMixin {
  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.clipboardStatus.addListener(_onChangedClipboardStatus);
    widget.clipboardStatus.update();
  }

  @override
  void didUpdateWidget(OpenTextSelectionControlsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clipboardStatus != oldWidget.clipboardStatus) {
      widget.clipboardStatus.addListener(_onChangedClipboardStatus);
      oldWidget.clipboardStatus.removeListener(_onChangedClipboardStatus);
    }
    widget.clipboardStatus.update();
  }

  @override
  void dispose() {
    super.dispose();
    // When used in an Overlay, it can happen that this is disposed after its
    // creator has already disposed _clipboardStatus.
    if (!widget.clipboardStatus.disposed) {
      widget.clipboardStatus.removeListener(_onChangedClipboardStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there are no buttons to be shown, don't render anything.
    if (widget.handleCut == null &&
        widget.handleCopy == null &&
        widget.handlePaste == null &&
        widget.handleSelectAll == null &&
        widget.handleCustomButton == null) {
      return const SizedBox.shrink();
    }
    // If the paste button is desired, don't render anything until the state of
    // the clipboard is known, since it's used to determine if paste is shown.
    if (widget.handlePaste != null &&
        widget.clipboardStatus.value == ClipboardStatus.unknown) {
      return const SizedBox.shrink();
    }

    // Calculate the positioning of the menu. It is placed above the selection
    // if there is enough room, or otherwise below.
    final TextSelectionPoint startTextSelectionPoint = widget.endpoints[0];
    final TextSelectionPoint endTextSelectionPoint =
        widget.endpoints.length > 1 ? widget.endpoints[1] : widget.endpoints[0];
    final Offset anchorAbove = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top +
          startTextSelectionPoint.point.dy -
          widget.textLineHeight -
          _kToolbarContentDistance,
    );
    final Offset anchorBelow = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top +
          endTextSelectionPoint.point.dy +
          _kToolbarContentDistanceBelow,
    );

    // Determine which buttons will appear so that the order and total number is
    // known. A button's position in the menu can slightly affect its
    // appearance.
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final List<_TextSelectionToolbarItemData> itemDatas =
        <_TextSelectionToolbarItemData>[
      if (widget.handleCustomButton != null)
        _TextSelectionToolbarItemData(
          onPressed: widget.handleCustomButton!,
          label: 'Open',
        ),
      if (widget.handleCut != null)
        _TextSelectionToolbarItemData(
          label: localizations.cutButtonLabel,
          onPressed: widget.handleCut!,
        ),
      if (widget.handleCopy != null)
        _TextSelectionToolbarItemData(
          label: localizations.copyButtonLabel,
          onPressed: widget.handleCopy!,
        ),
      if (widget.handlePaste != null &&
          widget.clipboardStatus.value == ClipboardStatus.pasteable)
        _TextSelectionToolbarItemData(
          label: localizations.pasteButtonLabel,
          onPressed: widget.handlePaste!,
        ),
      if (widget.handleSelectAll != null)
        _TextSelectionToolbarItemData(
          label: localizations.selectAllButtonLabel,
          onPressed: widget.handleSelectAll!,
        ),
    ];

    // If there is no option available, build an empty widget.
    if (itemDatas.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return TextSelectionToolbar(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      children: itemDatas
          .asMap()
          .entries
          .map((MapEntry<int, _TextSelectionToolbarItemData> entry) {
        return TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(
              entry.key, itemDatas.length),
          onPressed: entry.value.onPressed,
          child: Text(entry.value.label),
        );
      }).toList(),
    );
  }
}

class _TextSelectionToolbarItemData {
  const _TextSelectionToolbarItemData({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;
}

extension TextSelectionDelegateExt on TextSelectionDelegate {
  bool canlinkselect() {
    if (textEditingValue.text.isEmpty) return false;
    if (urls.hasMatch(textEditingValue.text) ||
        emails.hasMatch(textEditingValue.text) ||
        phonenos.hasMatch(textEditingValue.text) ||
        hashtags.hasMatch(textEditingValue.text)) {
      if (urls.hasMatch(textEditingValue.text)) {
        var matches = urls.allMatches(textEditingValue.text);
        for (int i = 0; i < matches.length; i++) {
          if (textEditingValue.selection.baseOffset >=
                  matches.elementAt(i).start &&
              textEditingValue.selection.baseOffset <=
                  matches.elementAt(i).end) {
            return true;
          }
        }
      }
      if (emails.hasMatch(textEditingValue.text)) {
        var matches = emails.allMatches(textEditingValue.text);
        for (int i = 0; i < matches.length; i++) {
          if (textEditingValue.selection.baseOffset >=
                  matches.elementAt(i).start &&
              textEditingValue.selection.baseOffset <=
                  matches.elementAt(i).end) {
            return true;
          }
        }
      }
      if (phonenos.hasMatch(textEditingValue.text)) {
        var matches = phonenos.allMatches(textEditingValue.text);
        for (int i = 0; i < matches.length; i++) {
          if (textEditingValue.selection.baseOffset >=
                  matches.elementAt(i).start &&
              textEditingValue.selection.baseOffset <=
                  matches.elementAt(i).end) {
            return true;
          }
        }
      }
      if (hashtags.hasMatch(textEditingValue.text)) {
        var matches = hashtags.allMatches(textEditingValue.text);
        for (int i = 0; i < matches.length; i++) {
          if (textEditingValue.selection.baseOffset >=
                  matches.elementAt(i).start &&
              textEditingValue.selection.baseOffset <=
                  matches.elementAt(i).end) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> linkselect(Function searchback, Function save) async {
    if (textEditingValue.text.isEmpty) return;
    if (urls.hasMatch(textEditingValue.text) ||
        emails.hasMatch(textEditingValue.text) ||
        phonenos.hasMatch(textEditingValue.text) ||
        hashtags.hasMatch(textEditingValue.text)) {
      if (urls.hasMatch(textEditingValue.text)) {
        var matches = urls.allMatches(textEditingValue.text);
        for (int i = 0; i < matches.length; i++) {
          if (textEditingValue.selection.baseOffset >=
                  matches.elementAt(i).start &&
              textEditingValue.selection.baseOffset <=
                  matches.elementAt(i).end) {
            this.userUpdateTextEditingValue(
                this.textEditingValue.copyWith(
                      selection: TextSelection(
                          baseOffset: matches.elementAt(i).start,
                          extentOffset: matches.elementAt(i).end),
                    ),
                SelectionChangedCause.longPress);
            String url = textEditingValue.text.substring(
                matches.elementAt(i).start, matches.elementAt(i).end);
            if (url.substring(0, 4) != 'http') url = 'http://' + url;
            await launch(url);
            break;
          }
        }
      }
      if (emails.hasMatch(textEditingValue.text)) {
        var matches = emails.allMatches(textEditingValue.text);
        for (int i = 0; i < matches.length; i++) {
          if (textEditingValue.selection.baseOffset >=
                  matches.elementAt(i).start &&
              textEditingValue.selection.baseOffset <=
                  matches.elementAt(i).end) {
            this.userUpdateTextEditingValue(
                this.textEditingValue.copyWith(
                      selection: TextSelection(
                          baseOffset: matches.elementAt(i).start,
                          extentOffset: matches.elementAt(i).end),
                    ),
                SelectionChangedCause.longPress);
            String email = textEditingValue.text.substring(
                matches.elementAt(i).start, matches.elementAt(i).end);
            if (email.substring(0, 4) != 'mailto:') email = 'mailto:' + email;
            await launch(email);
            break;
          }
        }
      }
      if (phonenos.hasMatch(textEditingValue.text)) {
        var matches = phonenos.allMatches(textEditingValue.text);
        for (int i = 0; i < matches.length; i++) {
          if (textEditingValue.selection.baseOffset >=
                  matches.elementAt(i).start &&
              textEditingValue.selection.baseOffset <=
                  matches.elementAt(i).end) {
            this.userUpdateTextEditingValue(
                this.textEditingValue.copyWith(
                      selection: TextSelection(
                          baseOffset: matches.elementAt(i).start,
                          extentOffset: matches.elementAt(i).end),
                    ),
                SelectionChangedCause.longPress);
            String phone = textEditingValue.text.substring(
                matches.elementAt(i).start, matches.elementAt(i).end);
            if (phone.substring(0, 4) != 'tel:') phone = 'tel:' + phone;
            await launch(phone);
            break;
          }
        }
      }
      if (hashtags.hasMatch(textEditingValue.text)) {
        var matches = hashtags.allMatches(textEditingValue.text);
        for (int i = 0; i < matches.length; i++) {
          if (textEditingValue.selection.baseOffset >=
                  matches.elementAt(i).start &&
              textEditingValue.selection.baseOffset <=
                  matches.elementAt(i).end) {
            this.userUpdateTextEditingValue(
                this.textEditingValue.copyWith(
                      selection: TextSelection(
                          baseOffset: matches.elementAt(i).start,
                          extentOffset: matches.elementAt(i).end),
                    ),
                SelectionChangedCause.longPress);

            String hashtag = textEditingValue.text.substring(
                matches.elementAt(i).start + 1, matches.elementAt(i).end);
            await save(textEditingValue.text);
            searchback(hashtag);
            break;
          }
        }
      }
    }
  }
}

class EscIntent extends Intent {
  const EscIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class OpenIntent extends Intent {
  const OpenIntent();
}

class EditNotePage extends StatelessWidget {
  final Function close, refresh;
  final int index;
  final Note note;
  final Function searchBack;
  EditNotePage(
      this.close, this.refresh, this.index, this.note, this.searchBack);

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

    Future<void> save(context, title, body) async {
      await Note(title, body, note.created).editCard(index);
      refresh.call();
    }

    return WillPopScope(
      onWillPop: () async {
        close.call();
        await edit(context);
        return false;
      },
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO):
              const OpenIntent(),
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
            OpenIntent: CallbackAction<OpenIntent>(
              onInvoke: (OpenIntent intent) async {
                if (currentBody.value.text.isNotEmpty) {
                  if (urls.hasMatch(currentBody.value.text) ||
                      emails.hasMatch(currentBody.value.text) ||
                      phonenos.hasMatch(currentBody.value.text) ||
                      hashtags.hasMatch(currentBody.value.text)) {
                    if (urls.hasMatch(currentBody.value.text)) {
                      var matches = urls.allMatches(currentBody.value.text);
                      for (int i = 0; i < matches.length; i++) {
                        if (currentBody.value.selection.baseOffset >=
                                matches.elementAt(i).start &&
                            currentBody.value.selection.baseOffset <=
                                matches.elementAt(i).end) {
                          currentBody.value.copyWith(
                            selection: TextSelection(
                                baseOffset: matches.elementAt(i).start,
                                extentOffset: matches.elementAt(i).end),
                          );
                          String url = currentBody.value.text.substring(
                              matches.elementAt(i).start,
                              matches.elementAt(i).end);
                          if (url.substring(0, 4) != 'http')
                            url = 'http://' + url;
                          await launch(url);
                          break;
                        }
                      }
                    }
                    if (emails.hasMatch(currentBody.value.text)) {
                      var matches = emails.allMatches(currentBody.value.text);
                      for (int i = 0; i < matches.length; i++) {
                        if (currentBody.value.selection.baseOffset >=
                                matches.elementAt(i).start &&
                            currentBody.value.selection.baseOffset <=
                                matches.elementAt(i).end) {
                          currentBody.value.copyWith(
                            selection: TextSelection(
                                baseOffset: matches.elementAt(i).start,
                                extentOffset: matches.elementAt(i).end),
                          );
                          String email = currentBody.value.text.substring(
                              matches.elementAt(i).start,
                              matches.elementAt(i).end);
                          if (email.substring(0, 4) != 'mailto:')
                            email = 'mailto:' + email;
                          await launch(email);
                          break;
                        }
                      }
                    }
                    if (phonenos.hasMatch(currentBody.value.text)) {
                      var matches = phonenos.allMatches(currentBody.value.text);
                      for (int i = 0; i < matches.length; i++) {
                        if (currentBody.value.selection.baseOffset >=
                                matches.elementAt(i).start &&
                            currentBody.value.selection.baseOffset <=
                                matches.elementAt(i).end) {
                          currentBody.value.copyWith(
                            selection: TextSelection(
                                baseOffset: matches.elementAt(i).start,
                                extentOffset: matches.elementAt(i).end),
                          );
                          String phone = currentBody.value.text.substring(
                              matches.elementAt(i).start,
                              matches.elementAt(i).end);
                          if (phone.substring(0, 4) != 'tel:')
                            phone = 'tel:' + phone;
                          await launch(phone);
                          break;
                        }
                      }
                    }
                    if (hashtags.hasMatch(currentBody.value.text)) {
                      var matches = hashtags.allMatches(currentBody.value.text);
                      for (int i = 0; i < matches.length; i++) {
                        if (currentBody.value.selection.baseOffset >=
                                matches.elementAt(i).start &&
                            currentBody.value.selection.baseOffset <=
                                matches.elementAt(i).end) {
                          currentBody.value.copyWith(
                            selection: TextSelection(
                                baseOffset: matches.elementAt(i).start,
                                extentOffset: matches.elementAt(i).end),
                          );
                          String hashtag = currentBody.value.text.substring(
                              matches.elementAt(i).start + 1,
                              matches.elementAt(i).end);
                          await save(context, currentTitle.value.text,
                              currentBody.value.text);
                          searchBack(hashtag);
                          break;
                        }
                      }
                    }
                  }
                }
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
                                    textCapitalization:
                                        TextCapitalization.words,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  months[note.created.month - 1] +
                                      " " +
                                      note.created.day.toString() +
                                      ", " +
                                      note.created.year.toString(),
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                                ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: currentBody,
                                    builder: (context, TextEditingValue curBody,
                                        snapshot) {
                                      return Text(
                                        "${curBody.text.length} Characters",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      );
                                    }),
                              ],
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
                              RichTextController _body = RichTextController(
                                patternMap: {
                                  hashtags: TextStyle(
                                    color: Colors.cyan[300],
                                  ),
                                  urls: TextStyle(
                                    color: Colors.cyan[300],
                                    decoration: TextDecoration.underline,
                                  ),
                                  emails: TextStyle(
                                    color: Colors.cyan[300],
                                  ),
                                  phonenos: TextStyle(
                                    color: Colors.cyan[300],
                                  ),
                                },
                              );
                              _body.value = curBody;

                              bool enabled = false;

                              return TextFormField(
                                cursorColor:
                                    Theme.of(context).primaryColor == kGlacier
                                        ? kMatte
                                        : kGlacier,
                                controller: _body,
                                selectionControls: Platform.isWindows
                                    ? _DesktopTextSelectionControls(searchBack,
                                        (body) async {
                                        await save(context,
                                            currentTitle.value.text, body);
                                      })
                                    : OpenTextSelectionControls(searchBack,
                                        (body) async {
                                        await save(context,
                                            currentTitle.value.text, body);
                                      }),
                                onTap: () => currentBody.value = _body.value,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  hintText: "Note",
                                  hintMaxLines: null,
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                autofocus: Platform.isWindows,
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
                      SizedBox(
                        height: 56.0,
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
