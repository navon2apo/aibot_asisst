import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_painter/flutter_painter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'tool_settings_bar.dart';
import 'package:flutter_painter/src/controllers/drawables/shape/shape_drawable.dart';
import 'package:flutter_painter/src/controllers/drawables/text_drawable.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:logger/logger.dart';

class ScreenshotEditor extends StatefulWidget {
  /// The raw bytes of the initial screenshot image.
  final Uint8List initialImage;

  const ScreenshotEditor({Key? key, required this.initialImage})
    : super(key: key);

  @override
  State<ScreenshotEditor> createState() => _ScreenshotEditorState();
}

class _ScreenshotEditorState extends State<ScreenshotEditor> {
  late final PainterController _controller;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 4.0;
  bool _loading = true;
  ui.Image? _backgroundImage;
  Color _strokeColor = Colors.black;
  Color _fillColor = Colors.transparent;
  double _shapeOpacity = 1.0;
  bool _isFill = false;
  bool _showToolSettings = false;
  ToolType? _activeTool;
  ObjectDrawable? _selectedObject;
  double _textFontSize = 18.0;
  ToolType? _lastActiveTool;
  FocusNode _focusNode = FocusNode();
  bool _uploadingImage = false;
  // Zoom & pan state
  double _zoomScale = 1.0;
  final TransformationController _transformationController =
      TransformationController();
  final logger = Logger();
  ScrollController _horizontalScrollController = ScrollController();
  ScrollController _verticalScrollController = ScrollController();
  bool _isDrawingOrDragging = false;

  @override
  void initState() {
    super.initState();
    _initPainter();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        RawKeyboard.instance.addListener(_handleKeyEvent);
      } else {
        RawKeyboard.instance.removeListener(_handleKeyEvent);
      }
    });
    _horizontalScrollController.addListener(_onHorizontalScroll);
    _verticalScrollController.addListener(_onVerticalScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformationController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.logicalKey.keyLabel == 'Delete') {
      if (_selectedObject != null) {
        _controller.removeDrawable(_selectedObject!);
        setState(() {
          _selectedObject = null;
        });
      } else {
        _controller.clearDrawables();
      }
    }
  }

  Future<void> _initPainter() async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(widget.initialImage, (ui.Image img) {
      completer.complete(img);
    });
    final image = await completer.future;
    setState(() {
      _backgroundImage = image;
      _controller =
          PainterController()
            ..freeStyleColor = _selectedColor
            ..freeStyleStrokeWidth = _strokeWidth;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _backgroundImage == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _selectedObject = _controller.selectedObjectDrawable;
    final isObjectSelected = _selectedObject != null;
    Color barColor;
    double barStrokeWidth;
    double barOpacity;
    bool barIsFill;
    if (isObjectSelected && _selectedObject != null) {
      if (_selectedObject is ShapeDrawable) {
        final shape = _selectedObject as ShapeDrawable;
        barColor = shape.paint.color;
        barStrokeWidth = shape.paint.strokeWidth;
        barOpacity = shape.paint.color.opacity;
        barIsFill = shape.paint.style == PaintingStyle.fill;
      } else if (_selectedObject is TextDrawable) {
        final text = _selectedObject as TextDrawable;
        barColor = text.style.color ?? Colors.black;
        barStrokeWidth = (text.style.fontWeight?.index ?? 4).toDouble();
        barOpacity = (text.style.color?.opacity ?? 1.0);
        barIsFill = true;
      } else {
        barColor = Colors.black;
        barStrokeWidth = _strokeWidth;
        barOpacity = _shapeOpacity;
        barIsFill = _isFill;
      }
    } else {
      barColor = _isFill ? _fillColor : _strokeColor;
      barStrokeWidth = _strokeWidth;
      barOpacity = _shapeOpacity;
      barIsFill = _isFill;
    }
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Screenshot Editor'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Download',
                onPressed: () async {
                  final painterImage = await _controller.renderImage(
                    Size(
                      _backgroundImage!.width.toDouble(),
                      _backgroundImage!.height.toDouble(),
                    ),
                  );
                  final recorder = ui.PictureRecorder();
                  final canvas = Canvas(recorder);
                  final paint = Paint();
                  canvas.drawImage(_backgroundImage!, Offset.zero, paint);
                  canvas.drawImage(painterImage, Offset.zero, paint);
                  final picture = recorder.endRecording();
                  final finalImage = await picture.toImage(
                    _backgroundImage!.width,
                    _backgroundImage!.height,
                  );
                  final byteData = await finalImage.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  if (byteData != null) {
                    final bytes = byteData.buffer.asUint8List();
                    // שמור קובץ
                    final result = await FilePicker.platform.saveFile(
                      dialogTitle: 'Save Edited Image',
                      fileName: 'edited_screenshot.png',
                    );
                    if (result != null) {
                      final file = File(result);
                      await file.writeAsBytes(bytes);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Image saved to $result')),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Done',
                onPressed: () async {
                  final painterImage = await _controller.renderImage(
                    Size(
                      _backgroundImage!.width.toDouble(),
                      _backgroundImage!.height.toDouble(),
                    ),
                  );
                  final recorder = ui.PictureRecorder();
                  final canvas = Canvas(recorder);
                  final paint = Paint();
                  canvas.drawImage(_backgroundImage!, Offset.zero, paint);
                  canvas.drawImage(painterImage, Offset.zero, paint);
                  final picture = recorder.endRecording();
                  final finalImage = await picture.toImage(
                    _backgroundImage!.width,
                    _backgroundImage!.height,
                  );
                  final byteData = await finalImage.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  Navigator.of(context).pop(byteData?.buffer.asUint8List());
                },
              ),
            ],
          ),
          body: Focus(
            focusNode: _focusNode,
            autofocus: true,
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // Zoom & pan controls
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Zoom slider
                              IconButton(
                                icon: Icon(Icons.fit_screen, size: 18),
                                tooltip: 'Fit to Canvas',
                                onPressed: _fitToCanvas,
                                splashRadius: 18,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.zoom_out, size: 18),
                              SizedBox(
                                width: 120,
                                child: Slider(
                                  value: _zoomScale,
                                  min: 0.5,
                                  max: 4.0,
                                  divisions: 35,
                                  onChanged: (v) {
                                    setState(() {
                                      _zoomScale = v;
                                      _transformationController.value =
                                          Matrix4.identity()..scale(_zoomScale);
                                      if (_zoomScale == 1.0) {
                                        _horizontalScrollController.jumpTo(0);
                                        _verticalScrollController.jumpTo(0);
                                      }
                                    });
                                  },
                                ),
                              ),
                              Icon(Icons.zoom_in, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${(_zoomScale * 100).toInt()}%',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Zoom: mouse wheel (Ctrl+Scroll) or slider. Pan: hand tool or drag.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            _zoomScale == 1.0
                                ? AspectRatio(
                                  aspectRatio:
                                      _backgroundImage!.width /
                                      _backgroundImage!.height,
                                  child: Stack(
                                    children: [
                                      Image.memory(
                                        widget.initialImage,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                      FlutterPainter(
                                        controller: _controller,
                                        onSelectedObjectDrawableChanged: (obj) {
                                          setState(() {
                                            _selectedObject = obj;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                )
                                : Scrollbar(
                                  controller: _verticalScrollController,
                                  thumbVisibility: true,
                                  child: Scrollbar(
                                    controller: _horizontalScrollController,
                                    thumbVisibility: true,
                                    notificationPredicate:
                                        (notif) => notif.depth == 1,
                                    child: SingleChildScrollView(
                                      controller: _verticalScrollController,
                                      scrollDirection: Axis.vertical,
                                      physics:
                                          _isDrawingOrDragging
                                              ? const NeverScrollableScrollPhysics()
                                              : null,
                                      child: SingleChildScrollView(
                                        controller: _horizontalScrollController,
                                        scrollDirection: Axis.horizontal,
                                        physics:
                                            _isDrawingOrDragging
                                                ? const NeverScrollableScrollPhysics()
                                                : null,
                                        child: Transform.scale(
                                          scale: _zoomScale,
                                          alignment: Alignment.topLeft,
                                          child: SizedBox(
                                            width:
                                                _backgroundImage!.width
                                                    .toDouble(),
                                            height:
                                                _backgroundImage!.height
                                                    .toDouble(),
                                            child: GestureDetector(
                                              onPanDown:
                                                  (_) => setState(
                                                    () =>
                                                        _isDrawingOrDragging =
                                                            true,
                                                  ),
                                              onPanStart:
                                                  (_) => setState(
                                                    () =>
                                                        _isDrawingOrDragging =
                                                            true,
                                                  ),
                                              onPanEnd:
                                                  (_) => setState(
                                                    () =>
                                                        _isDrawingOrDragging =
                                                            false,
                                                  ),
                                              onPanCancel:
                                                  () => setState(
                                                    () =>
                                                        _isDrawingOrDragging =
                                                            false,
                                                  ),
                                              child: Stack(
                                                children: [
                                                  Image.memory(
                                                    widget.initialImage,
                                                    fit: BoxFit.contain,
                                                    width:
                                                        _backgroundImage!.width
                                                            .toDouble(),
                                                    height:
                                                        _backgroundImage!.height
                                                            .toDouble(),
                                                  ),
                                                  FlutterPainter(
                                                    controller: _controller,
                                                    onSelectedObjectDrawableChanged:
                                                        (obj) {
                                                          setState(() {
                                                            _selectedObject =
                                                                obj;
                                                          });
                                                        },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
                _buildToolBar(),
                if ((_showToolSettings &&
                        _activeTool != null &&
                        _activeTool != ToolType.eraser) ||
                    isObjectSelected ||
                    _activeTool == ToolType.freeStyle)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swipe,
                              size: 16,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Scroll the settings bar sideways',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.deepPurple,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Colors.deepPurple,
                            ),
                          ],
                        ),
                      ),
                      ToolSettingsBar(
                        color:
                            _activeTool == ToolType.freeStyle
                                ? _selectedColor
                                : barColor,
                        strokeWidth:
                            _activeTool == ToolType.freeStyle
                                ? _strokeWidth
                                : barStrokeWidth,
                        opacity:
                            _activeTool == ToolType.freeStyle
                                ? _shapeOpacity
                                : barOpacity,
                        isFill:
                            _activeTool == ToolType.freeStyle
                                ? false
                                : barIsFill,
                        showFillToggle:
                            _activeTool == ToolType.rectangle ||
                            _activeTool == ToolType.ellipse ||
                            (isObjectSelected &&
                                (_selectedObject is ShapeDrawable)),
                        onColorChanged: (c) {
                          setState(() {
                            if (_activeTool == ToolType.freeStyle) {
                              _selectedColor = c;
                              _controller.freeStyleColor = c;
                            } else if (isObjectSelected &&
                                _selectedObject != null) {
                              if (_selectedObject is ShapeDrawable) {
                                final shape = _selectedObject as ShapeDrawable;
                                final newDrawable = shape.copyWith(
                                  paint:
                                      shape.paint
                                        ..color = c.withAlpha(
                                          (barOpacity * 255).toInt(),
                                        ),
                                );
                                _controller.replaceDrawable(shape, newDrawable);
                                _selectedObject = newDrawable;
                              } else if (_selectedObject is TextDrawable) {
                                final text = _selectedObject as TextDrawable;
                                final newDrawable = text.copyWith(
                                  style: text.style.copyWith(
                                    color: c.withAlpha(
                                      (barOpacity * 255).toInt(),
                                    ),
                                  ),
                                );
                                _controller.replaceDrawable(text, newDrawable);
                                _selectedObject = newDrawable;
                              }
                            } else {
                              if (_isFill)
                                _fillColor = c;
                              else
                                _strokeColor = c;
                              _controller.shapePaint =
                                  Paint()
                                    ..color = (_isFill
                                            ? _fillColor
                                            : _strokeColor)
                                        .withAlpha(
                                          (_shapeOpacity * 255).toInt(),
                                        )
                                    ..style =
                                        _isFill
                                            ? PaintingStyle.fill
                                            : PaintingStyle.stroke
                                    ..strokeWidth = _strokeWidth;
                              if (_activeTool == ToolType.text) {
                                _selectedColor = c;
                                _controller.textStyle = _controller.textStyle
                                    .copyWith(color: c);
                              }
                            }
                          });
                        },
                        onStrokeWidthChanged: (v) {
                          setState(() {
                            if (_activeTool == ToolType.freeStyle) {
                              _strokeWidth = v;
                              _controller.freeStyleStrokeWidth = v;
                            } else if (isObjectSelected &&
                                _selectedObject != null) {
                              if (_selectedObject is ShapeDrawable) {
                                final shape = _selectedObject as ShapeDrawable;
                                final newDrawable = shape.copyWith(
                                  paint: shape.paint..strokeWidth = v,
                                );
                                _controller.replaceDrawable(shape, newDrawable);
                                _selectedObject = newDrawable;
                              }
                            } else {
                              _strokeWidth = v;
                              _controller.shapePaint =
                                  Paint()
                                    ..color = (_isFill
                                            ? _fillColor
                                            : _strokeColor)
                                        .withAlpha(
                                          (_shapeOpacity * 255).toInt(),
                                        )
                                    ..style =
                                        _isFill
                                            ? PaintingStyle.fill
                                            : PaintingStyle.stroke
                                    ..strokeWidth = _strokeWidth;
                            }
                          });
                        },
                        onOpacityChanged: (v) {
                          setState(() {
                            if (_activeTool == ToolType.freeStyle) {
                              _shapeOpacity = v;
                              // אין תמיכה ישירה בשקיפות בציור חופשי, אבל אפשר להוסיף אם צריך
                            } else if (isObjectSelected &&
                                _selectedObject != null) {
                              if (_selectedObject is ShapeDrawable) {
                                final shape = _selectedObject as ShapeDrawable;
                                final newDrawable = shape.copyWith(
                                  paint:
                                      shape.paint
                                        ..color = barColor.withAlpha(
                                          (v * 255).toInt(),
                                        ),
                                );
                                _controller.replaceDrawable(shape, newDrawable);
                                _selectedObject = newDrawable;
                              } else if (_selectedObject is TextDrawable) {
                                final text = _selectedObject as TextDrawable;
                                final newDrawable = text.copyWith(
                                  style: text.style.copyWith(
                                    color: barColor.withAlpha(
                                      (v * 255).toInt(),
                                    ),
                                  ),
                                );
                                _controller.replaceDrawable(text, newDrawable);
                                _selectedObject = newDrawable;
                              }
                            } else {
                              _shapeOpacity = v;
                              _controller.shapePaint =
                                  Paint()
                                    ..color = (_isFill
                                            ? _fillColor
                                            : _strokeColor)
                                        .withAlpha(
                                          (_shapeOpacity * 255).toInt(),
                                        )
                                    ..style =
                                        _isFill
                                            ? PaintingStyle.fill
                                            : PaintingStyle.stroke
                                    ..strokeWidth = _strokeWidth;
                            }
                          });
                        },
                        onFillChanged: (v) {
                          setState(() {
                            if (isObjectSelected &&
                                _selectedObject != null &&
                                _selectedObject is ShapeDrawable) {
                              final shape = _selectedObject as ShapeDrawable;
                              final newDrawable = shape.copyWith(
                                paint:
                                    shape.paint
                                      ..style =
                                          v
                                              ? PaintingStyle.fill
                                              : PaintingStyle.stroke,
                              );
                              _controller.replaceDrawable(shape, newDrawable);
                              _selectedObject = newDrawable;
                            } else {
                              _isFill = v;
                              _controller.shapePaint =
                                  Paint()
                                    ..color = (_isFill
                                            ? _fillColor
                                            : _strokeColor)
                                        .withAlpha(
                                          (_shapeOpacity * 255).toInt(),
                                        )
                                    ..style =
                                        _isFill
                                            ? PaintingStyle.fill
                                            : PaintingStyle.stroke
                                    ..strokeWidth = _strokeWidth;
                            }
                          });
                        },
                        extraSettings:
                            (_activeTool == ToolType.text ||
                                    (isObjectSelected &&
                                        _selectedObject is TextDrawable))
                                ? Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    Text(
                                      'Size',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          _textFontSize = (_textFontSize - 2)
                                              .clamp(8.0, 96.0);
                                          if (_activeTool == ToolType.text) {
                                            _controller.textStyle = _controller
                                                .textStyle
                                                .copyWith(
                                                  fontSize: _textFontSize,
                                                );
                                          } else if (_selectedObject
                                              is TextDrawable) {
                                            final text =
                                                _selectedObject as TextDrawable;
                                            final newDrawable = text.copyWith(
                                              style: text.style.copyWith(
                                                fontSize: _textFontSize,
                                              ),
                                            );
                                            _controller.replaceDrawable(
                                              text,
                                              newDrawable,
                                            );
                                            _selectedObject = newDrawable;
                                          }
                                        });
                                      },
                                      iconSize: 18,
                                    ),
                                    Text(_textFontSize.toInt().toString()),
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          _textFontSize = (_textFontSize + 2)
                                              .clamp(8.0, 96.0);
                                          if (_activeTool == ToolType.text) {
                                            _controller.textStyle = _controller
                                                .textStyle
                                                .copyWith(
                                                  fontSize: _textFontSize,
                                                );
                                          } else if (_selectedObject
                                              is TextDrawable) {
                                            final text =
                                                _selectedObject as TextDrawable;
                                            final newDrawable = text.copyWith(
                                              style: text.style.copyWith(
                                                fontSize: _textFontSize,
                                              ),
                                            );
                                            _controller.replaceDrawable(
                                              text,
                                              newDrawable,
                                            );
                                            _selectedObject = newDrawable;
                                          }
                                        });
                                      },
                                      iconSize: 18,
                                    ),
                                  ],
                                )
                                : null,
                      ),
                    ],
                  ),
                if (_activeTool == ToolType.eraser)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove, size: 18),
                        Expanded(
                          child: Slider(
                            value: _strokeWidth,
                            min: 2,
                            max: 64,
                            onChanged: (v) {
                              setState(() {
                                _strokeWidth = v;
                                _controller.freeStyleStrokeWidth = v;
                              });
                            },
                          ),
                        ),
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 8),
                        Text(_strokeWidth.toInt().toString()),
                        SizedBox(width: 8),
                        Text(
                          'Eraser Size',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_uploadingImage)
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.2),
          ),
        if (_uploadingImage) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildToolBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children:
              [
                    _toolButton(
                      Icons.open_with,
                      _deselectTool,
                      isActive: _activeTool == null,
                    ),
                    _toolButton(
                      Icons.brush,
                      () => _onToolPressed(ToolType.freeStyle),
                      isActive: _activeTool == ToolType.freeStyle,
                    ),
                    _toolButton(
                      Icons.auto_fix_normal,
                      () => _onToolPressed(ToolType.eraser),
                      isActive: _activeTool == ToolType.eraser,
                    ),
                    _toolButton(
                      Icons.arrow_forward,
                      () => _onToolPressed(ToolType.arrow),
                      isActive: _activeTool == ToolType.arrow,
                    ),
                    _toolButton(
                      Icons.crop_square,
                      () => _onToolPressed(ToolType.rectangle),
                      isActive: _activeTool == ToolType.rectangle,
                    ),
                    _toolButton(
                      Icons.circle,
                      () => _onToolPressed(ToolType.ellipse),
                      isActive: _activeTool == ToolType.ellipse,
                    ),
                    _toolButton(
                      Icons.text_fields,
                      () => _onToolPressed(ToolType.text),
                      isActive: _activeTool == ToolType.text,
                    ),
                    _toolButton(Icons.delete, _onDeletePressed),
                    _toolButton(Icons.undo, () => _controller.undo()),
                    _toolButton(Icons.redo, () => _controller.redo()),
                    _toolButton(Icons.image, _onUploadImage),
                  ]
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: w,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  void _onToolPressed(ToolType type) {
    setState(() {
      if (_activeTool == type) {
        _deselectTool();
      } else {
        _activeTool = type;
        _showToolSettings = true;
        _selectTool(type);
      }
    });
  }

  void _deselectTool() {
    setState(() {
      _activeTool = null;
      _showToolSettings = false;
      _controller.shapeFactory = null;
      _controller.freeStyleMode = FreeStyleMode.none;
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_selectedObject != null) {
        _controller.removeDrawable(_selectedObject!);
        _selectedObject = null;
      } else {
        _controller.clearDrawables();
      }
    });
  }

  Widget _toolButton(
    IconData icon,
    VoidCallback onPressed, {
    bool isActive = false,
  }) {
    return Material(
      color: isActive ? Colors.deepPurple.shade100 : Colors.transparent,
      shape: const CircleBorder(),
      elevation: isActive ? 2 : 0,
      child: IconButton(
        icon: Icon(icon, color: isActive ? Colors.deepPurple : Colors.black87),
        onPressed: onPressed,
        splashRadius: 18,
        iconSize: 18,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        tooltip: null,
      ),
    );
  }

  void _selectTool(ToolType type) {
    setState(() {
      switch (type) {
        case ToolType.freeStyle:
          _controller.freeStyleMode = FreeStyleMode.draw;
          break;
        case ToolType.eraser:
          _controller.freeStyleMode = FreeStyleMode.erase;
          break;
        case ToolType.arrow:
          _controller.shapeFactory = ArrowFactory();
          break;
        case ToolType.rectangle:
          _controller.shapeFactory = RectangleFactory();
          break;
        case ToolType.ellipse:
          _controller.shapeFactory = OvalFactory();
          break;
        case ToolType.text:
          _controller.textStyle = _controller.textStyle.copyWith(
            color: _selectedColor,
            fontSize: _textFontSize,
          );
          _openToolSettings(ToolType.text);
          _controller.addText();
          break;
      }
      _controller.shapePaint =
          Paint()
            ..color = (_isFill ? _fillColor : _strokeColor).withAlpha(
              (_shapeOpacity * 255).toInt(),
            )
            ..style = _isFill ? PaintingStyle.fill : PaintingStyle.stroke
            ..strokeWidth = _strokeWidth;
    });
  }

  void _onUploadImage() async {
    debugPrint('onUploadImage called');
    setState(() {
      _uploadingImage = true;
    });
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      Uint8List? bytes = result.files.single.bytes;
      String? path = result.files.single.path;
      if (bytes == null && path != null) {
        debugPrint('Loading image from path: $path');
        try {
          bytes = await File(path).readAsBytes();
        } catch (e) {
          debugPrint('Failed to read file from path: $e');
        }
      }
      if (bytes != null) {
        debugPrint('File picked: ${result.files.single.name}');
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(bytes, (ui.Image img) {
          completer.complete(img);
        });
        final image = await completer.future;
        debugPrint('Image decoded: size = ${image.width}x${image.height}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // מחשבים את גודל הקנבס (FlutterPainter)
          final renderBox =
              _controller.painterKey.currentContext?.findRenderObject()
                  as RenderBox?;
          final canvasSize = renderBox?.size ?? Size(400, 500);
          debugPrint(
            'Canvas size for fitting image: \\${canvasSize.width}x\\${canvasSize.height}',
          );
          _controller.addImage(image, canvasSize);
          debugPrint(
            'Image added to canvas (fitted): size = \\${image.width}x\\${image.height}',
          );
          debugPrint(
            'Drawables count: \\${_controller.value.drawables.length}',
          );
          setState(() {
            _uploadingImage = false;
          });
        });
      } else {
        debugPrint('No file bytes found, cannot load image');
        setState(() {
          _uploadingImage = false;
        });
      }
    } else {
      debugPrint('No file picked or file is empty');
      setState(() {
        _uploadingImage = false;
      });
    }
  }

  void _openToolSettings(ToolType tool) {
    setState(() {
      _activeTool = tool;
      _showToolSettings = true;
    });
  }

  void _closeToolSettings() {
    setState(() {
      _showToolSettings = false;
    });
  }

  void _onHorizontalScroll() {
    final dx = _horizontalScrollController.offset;
    final matrix = _transformationController.value.clone();
    matrix.setTranslationRaw(dx, matrix.getTranslation().y, 0);
    _transformationController.value = matrix;
  }

  void _onVerticalScroll() {
    final dy = _verticalScrollController.offset;
    final matrix = _transformationController.value.clone();
    matrix.setTranslationRaw(matrix.getTranslation().x, dy, 0);
    _transformationController.value = matrix;
  }

  void _fitToCanvas() {
    setState(() {
      _zoomScale = 1.0;
      _transformationController.value = Matrix4.identity();
      _horizontalScrollController.jumpTo(0);
      _verticalScrollController.jumpTo(0);
    });
  }
}

enum ToolType { freeStyle, arrow, rectangle, ellipse, text, eraser }

class _ColorPickerDialog extends StatelessWidget {
  final Color initial;
  const _ColorPickerDialog({Key? key, required this.initial}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color selected = initial;
    return AlertDialog(
      title: const Text('Pick a color'),
      content: SingleChildScrollView(
        child: BlockPicker(
          pickerColor: initial,
          onColorChanged: (c) => selected = c,
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(selected),
        ),
      ],
    );
  }
}
