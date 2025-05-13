import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FloatingMenu extends StatefulWidget {
  final Offset position;
  final Function(Offset) onPositionChanged;
  final VoidCallback onChatToggle;
  final VoidCallback onScreenshot;
  final VoidCallback onSettings;
  final VoidCallback onVoiceCommand;
  final VoidCallback onImageUpload;
  final VoidCallback onAudioRecord;
  final bool isListening;
  final bool isRecording;

  const FloatingMenu({
    super.key,
    required this.position,
    required this.onPositionChanged,
    required this.onChatToggle,
    required this.onScreenshot,
    required this.onSettings,
    required this.onVoiceCommand,
    required this.onImageUpload,
    required this.onAudioRecord,
    this.isListening = false,
    this.isRecording = false,
  });

  @override
  _FloatingMenuState createState() => _FloatingMenuState();
}

class _FloatingMenuState extends State<FloatingMenu>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  bool isLocked = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // טעינת מצב הנעילה בזמן אתחול
    _loadLockState();
  }

  // פונקציה לטעינת מצב הנעילה מההעדפות
  Future<void> _loadLockState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locked = prefs.getBool('floating_menu_locked') ?? false;

      setState(() {
        isLocked = locked;

        // אם התפריט נעול, נוודא שהוא מוצג
        if (isLocked) {
          isExpanded = true;
          _controller.forward();
        }
      });
    } catch (e) {
      print('Error loading lock state: $e');
    }
  }

  // פונקציה לשמירת מצב הנעילה בהעדפות
  Future<void> _saveLockState(bool locked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('floating_menu_locked', locked);
    } catch (e) {
      print('Error saving lock state: $e');
    }
  }

  void _toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else if (!isLocked) {
        _controller.reverse();
      }
    });
  }

  void _toggleLock() {
    setState(() {
      isLocked = !isLocked;

      // כאשר לוחצים על כפתור הנעילה:
      // אם נועלים - יש לוודא שהתפריט פתוח ולהשאיר אותו פתוח
      if (isLocked && !isExpanded) {
        isExpanded = true;
        _controller.forward();
      }
    });

    // שמירת מצב הנעילה
    _saveLockState(isLocked);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: widget.position.dx,
      top: widget.position.dy,
      child: Column(
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              widget.onPositionChanged(
                Offset(
                  widget.position.dx - details.delta.dx,
                  widget.position.dy + details.delta.dy,
                ),
              );
            },
            onTap: () {
              if (isLocked && isExpanded) {
                // לא עושים כלום - התפריט נעול ומוצג
              } else {
                _toggleExpanded();
              }
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color:
                    widget.isListening
                        ? Colors.red
                        : widget.isRecording
                        ? Colors.orange
                        : isLocked
                        ? Colors.green
                        : Colors.deepPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child:
                    isExpanded
                        ? Icon(
                          isLocked ? Icons.lock : Icons.close,
                          color: Colors.white,
                          key: ValueKey(isLocked ? 'lock' : 'close'),
                        )
                        : widget.isListening
                        ? Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 30,
                          key: ValueKey('mic'),
                        )
                        : widget.isRecording
                        ? Icon(
                          Icons.audiotrack,
                          color: Colors.white,
                          size: 30,
                          key: ValueKey('recording'),
                        )
                        : Icon(
                          Icons.android,
                          color: Colors.white,
                          size: 30,
                          key: ValueKey('robot'),
                        ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor:
                    isExpanded || isLocked
                        ? _expandAnimation
                        : Tween<double>(
                          begin: 0.0,
                          end: 0.0,
                        ).animate(_controller),
                axis: Axis.vertical,
                child: child,
              );
            },
            child: Column(
              children: [
                SizedBox(height: 10),
                _buildActionButton(
                  icon: Icons.message,
                  color: Colors.blue[400]!,
                  onTap: () {
                    widget.onChatToggle();
                    if (!isLocked) _toggleExpanded();
                  },
                  label: 'צ\'אט',
                ),
                SizedBox(height: 10),
                _buildActionButton(
                  icon: Icons.camera_alt,
                  color: Colors.green[400]!,
                  onTap: () {
                    widget.onScreenshot();
                    if (!isLocked) _toggleExpanded();
                  },
                  label: 'צילום מסך',
                ),
                SizedBox(height: 10),
                _buildActionButton(
                  icon: Icons.mic,
                  color: Colors.red[400]!,
                  onTap: () {
                    widget.onVoiceCommand();
                    if (!isLocked) _toggleExpanded();
                  },
                  label: 'פקודה קולית',
                ),
                SizedBox(height: 10),
                _buildActionButton(
                  icon: Icons.settings,
                  color: Colors.blueGrey[400]!,
                  onTap: () {
                    widget.onSettings();
                    if (!isLocked) _toggleExpanded();
                  },
                  label: 'הגדרות',
                ),
                SizedBox(height: 10),
                _buildActionButton(
                  icon: isLocked ? Icons.lock_open : Icons.lock,
                  color: Colors.orange[400]!,
                  onTap: () {
                    _toggleLock();
                  },
                  label: isLocked ? 'שחרר נעילה' : 'נעל תפריט',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        SizedBox(width: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
