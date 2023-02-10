import 'package:flutter/material.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';

typedef PointerMoveCallback = void Function(Offset offset);
typedef ScaleUpdateCallBack = void Function(ScaleUpdateDetails details);

class Sticker extends StatelessWidget {
  const Sticker({super.key, required this.stickerPath, required this.onDragStart, required this.onDragEnd, required this.onDragUpdate, required this.onScaleUpdate, });

  final String stickerPath;
  final VoidCallback onDragStart;
  final PointerMoveCallback onDragEnd;
  final PointerMoveCallback onDragUpdate;
  final ScaleUpdateCallBack onScaleUpdate;

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<Matrix4> notifier = ValueNotifier(Matrix4.identity());
    late Offset offset;
    return Listener(
      onPointerMove: (event) {
        offset = event.position;
        onDragUpdate(offset);
      },
      child: MatrixGestureDetector(
        onMatrixUpdate: (m, tm, sm, rm) {
          notifier.value = m;
        },
        onScaleStart: () {
          onDragStart();
        },
        onScaleEnd: () {
          onDragEnd(offset);
        },
        onScaleUpdate: (ScaleUpdateDetails details) {
          onScaleUpdate(details);
        },
        child: AnimatedBuilder(
          animation: notifier,
          builder: (ctx, child) {
            return Transform(
              transform: notifier.value,
              child: Align(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.asset(
                    stickerPath,
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


