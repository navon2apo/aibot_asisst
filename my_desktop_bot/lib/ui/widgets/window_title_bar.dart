import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';

class WindowTitleBar extends StatefulWidget {
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onSizeDisplayToggle;
  final bool showSizeDisplay;

  const WindowTitleBar({
    super.key,
    this.onSettingsPressed,
    this.onSizeDisplayToggle,
    this.showSizeDisplay = true,
  });

  @override
  _WindowTitleBarState createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> {
  bool isAlwaysOnTop = true;

  @override
  void initState() {
    super.initState();
    _checkAlwaysOnTop();
  }

  Future<void> _checkAlwaysOnTop() async {
    try {
      bool onTop = await windowManager.isAlwaysOnTop();
      if (mounted && onTop != isAlwaysOnTop) {
        setState(() {
          isAlwaysOnTop = onTop;
        });
      }

      // בדיקה חוזרת כל 5 שניות
      Future.delayed(Duration(seconds: 5), _checkAlwaysOnTop);
    } catch (e) {
      print('Error checking always on top: $e');
    }
  }

  Future<void> _toggleAlwaysOnTop() async {
    try {
      await windowManager.setAlwaysOnTop(!isAlwaysOnTop);
      setState(() {
        isAlwaysOnTop = !isAlwaysOnTop;
      });
    } catch (e) {
      print('Error toggling always on top: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColors = WindowButtonColors(
      iconNormal: Colors.grey[700],
      mouseOver: Colors.deepPurple[100],
      mouseDown: Colors.deepPurple[200],
      iconMouseOver: Colors.deepPurple[800],
      iconMouseDown: Colors.deepPurple[900],
    );

    final closeButtonColors = WindowButtonColors(
      iconNormal: Colors.grey[700],
      mouseOver: Colors.red,
      mouseDown: Colors.red[800],
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 40,
        color: Colors.white.withOpacity(0.5),
        child: WindowTitleBarBox(
          child: Row(
            children: [
              // Window title and logo with flexible width
              Expanded(
                child: MoveWindow(
                  child: Row(
                    children: [
                      SizedBox(width: 8), // פחות רווח
                      Icon(
                        Icons.android_rounded,
                        color: Colors.deepPurple,
                        size: 18, // אייקון קטן יותר
                      ),
                      SizedBox(width: 6), // פחות רווח
                      Flexible(
                        child: Text(
                          'עוזר השולחן החכם',
                          style: GoogleFonts.assistant(
                            fontSize: 12, // פונט קטן יותר
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis, // גלישת טקסט
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Window buttons - צמצום גודל הלחצנים
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Always on top button
                  SizedBox(
                    width: 28, // יותר צר
                    height: 40,
                    child: IconButton(
                      icon: Icon(
                        isAlwaysOnTop
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        size: 14, // קטן יותר
                      ),
                      onPressed: _toggleAlwaysOnTop,
                      tooltip:
                          isAlwaysOnTop ? 'בטל תמיד בחזית' : 'הצג תמיד בחזית',
                      color:
                          isAlwaysOnTop ? Colors.deepPurple : Colors.grey[700],
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ),
                  if (widget.onSettingsPressed != null)
                    SizedBox(
                      width: 28, // יותר צר
                      height: 40,
                      child: IconButton(
                        icon: Icon(Icons.settings, size: 14), // קטן יותר
                        onPressed: widget.onSettingsPressed,
                        tooltip: 'הגדרות',
                        color: Colors.grey[700],
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                  MinimizeWindowButton(colors: buttonColors),
                  MaximizeWindowButton(colors: buttonColors),
                  CloseWindowButton(colors: closeButtonColors),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
