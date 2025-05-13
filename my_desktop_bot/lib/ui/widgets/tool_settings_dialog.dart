import 'package:flutter/material.dart';

class ToolSettingsDialog extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final double opacity;
  final bool isFill;
  final bool showFillToggle;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<bool>? onFillChanged;
  final VoidCallback? onClose;
  final List<Color>? palette;
  final String? title;

  const ToolSettingsDialog({
    Key? key,
    required this.color,
    required this.strokeWidth,
    required this.opacity,
    required this.isFill,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onOpacityChanged,
    this.onFillChanged,
    this.onClose,
    this.palette,
    this.title,
    this.showFillToggle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors =
        palette ??
        [
          Colors.black,
          Colors.white,
          Colors.red,
          Colors.green,
          Colors.blue,
          Colors.yellow,
          Colors.orange,
          Colors.purple,
          Colors.cyan,
          Colors.brown,
        ];
    return GestureDetector(
      onTap: onClose,
      child: Material(
        color: Colors.black.withOpacity(0.1),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                ],
                Text('צבע', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Row(
                  children:
                      colors
                          .map(
                            (c) => GestureDetector(
                              onTap: () => onColorChanged(c),
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        c == color
                                            ? Colors.deepPurple
                                            : Colors.grey.shade300,
                                    width: c == color ? 3 : 1,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                SizedBox(height: 18),
                Text('עובי', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed:
                          () => onStrokeWidthChanged(
                            (strokeWidth - 1).clamp(1, 50),
                          ),
                      tooltip: 'הקטן עובי',
                    ),
                    SizedBox(
                      width: 120,
                      child: Slider(
                        min: 1,
                        max: 50,
                        value: strokeWidth,
                        onChanged: onStrokeWidthChanged,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed:
                          () => onStrokeWidthChanged(
                            (strokeWidth + 1).clamp(1, 50),
                          ),
                      tooltip: 'הגדל עובי',
                    ),
                    SizedBox(width: 8),
                    Text(strokeWidth.toInt().toString()),
                  ],
                ),
                SizedBox(height: 18),
                Text('שקיפות', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.opacity, size: 20),
                    SizedBox(
                      width: 120,
                      child: Slider(
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        value: opacity,
                        onChanged: onOpacityChanged,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('${(opacity * 100).toInt()}%'),
                  ],
                ),
                if (showFillToggle && onFillChanged != null) ...[
                  SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'מילוי',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Switch(
                        value: isFill,
                        onChanged: onFillChanged,
                        activeColor: Colors.deepPurple,
                      ),
                      Text(isFill ? 'מלא' : 'רק מסגרת'),
                    ],
                  ),
                ],
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onClose,
                    child: Text(
                      'סגור',
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
