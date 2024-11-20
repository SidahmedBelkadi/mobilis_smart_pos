import 'package:flutter/material.dart';
import '../../utils/enums/documents_type.dart';

class MRZOverlay extends CustomPainter {
  final bool isDocumentRecognized;
  final DocumentsType documentsType;

  MRZOverlay({
    required this.isDocumentRecognized,
    required this.documentsType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDocumentRecognized ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const double padding = 20.0;
    final double rectWidth = size.width - 2 * padding;
    final double rectHeight = size.height / 3;
    const double x = padding;
    final double y = (size.height - rectHeight) / 2;
    const double borderRadius = 20.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, rectWidth, rectHeight),
      const Radius.circular(borderRadius),
    );

    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(rect),
    );

    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.7));

    canvas.drawRRect(rect, paint);

    const double mrzPadding = 2.0;
    double mrzBandHeight = documentsType == DocumentsType.passport ? 80.0 : 90.0;
    final double mrzStartY = y + rectHeight - mrzBandHeight - mrzPadding;

    const textStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      fontFamily: 'Courier',
    );

    const String mrzSymbol = '<';
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = const TextSpan(text: mrzSymbol, style: textStyle);
    textPainter.layout();

    final int symbolsPerLine = (rectWidth / textPainter.width).floor();
    final String mrzLine = mrzSymbol * symbolsPerLine;

    final mrzPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    final rows = documentsType == DocumentsType.passport ? 2 : 3;
    for (int i = 0; i < rows; i++) {
      mrzPainter.text = TextSpan(text: mrzLine, style: textStyle);
      mrzPainter.layout(minWidth: rectWidth, maxWidth: rectWidth);
      final double lineY = mrzStartY + i * (mrzPainter.height + 4);
      final offset = Offset(x + mrzPadding, lineY);
      mrzPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
