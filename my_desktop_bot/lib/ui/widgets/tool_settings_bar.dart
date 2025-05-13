import 'package:flutter/material.dart';

class ToolSettingsBar extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final double opacity;
  final bool isFill;
  final bool showFillToggle;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<bool>? onFillChanged;
  final List<Color>? palette;
  final Widget? extraSettings;

  const ToolSettingsBar({
    Key? key,
    required this.color,
    required this.strokeWidth,
    required this.opacity,
    required this.isFill,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onOpacityChanged,
    this.onFillChanged,
    this.palette,
    this.showFillToggle = false,
    this.extraSettings,
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // שורה ראשונה: צבע, עובי, שקיפות, מילוי/מסגרת
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // צבע
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
                SizedBox(width: 16),
                // עובי
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
                      width: 80,
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
                SizedBox(width: 16),
                // שקיפות
                Row(
                  children: [
                    Icon(Icons.opacity, size: 20),
                    SizedBox(
                      width: 80,
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
                  SizedBox(width: 16),
                  Row(
                    children: [
                      Text('מילוי'),
                      Switch(
                        value: isFill,
                        onChanged: onFillChanged,
                        activeColor: Colors.deepPurple,
                      ),
                      Text(isFill ? 'מלא' : 'רק מסגרת'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // שורה שנייה: הגדרות נוספות (אם יש)
          if (extraSettings != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: extraSettings!,
            ),
        ],
      ),
    );
  }
}
