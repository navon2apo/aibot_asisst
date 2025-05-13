import 'package:flutter/material.dart';

/// דיאלוג לבחירת סוג צילום המסך
/// מאפשר למשתמש לבחור את סוג הצילום שברצונו לבצע
class ScreenshotModeDialog extends StatelessWidget {
  const ScreenshotModeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('בחר סוג צילום מסך'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(
              context: context,
              icon: Icons.fullscreen,
              title: 'צילום מסך מלא',
              subtitle: 'צילום של כל המסך',
              value: 'entire_screen',
            ),
            _buildOption(
              context: context,
              icon: Icons.crop,
              title: 'בחירת אזור',
              subtitle: 'בחר אזור ספציפי לצילום',
              value: 'region',
            ),
            _buildOption(
              context: context,
              icon: Icons.window,
              title: 'צילום חלון',
              subtitle: 'צילום של חלון ספציפי',
              value: 'window',
            ),
            _buildOption(
              context: context,
              icon: Icons.app_shortcut,
              title: 'צילום האפליקציה',
              subtitle: 'צילום של האפליקציה הנוכחית',
              value: 'current_app',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => Navigator.pop(context, value),
    );
  }
}
