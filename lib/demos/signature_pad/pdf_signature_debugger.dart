import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:ui';

class PdfSignatureDebugger {
  static Future<Uint8List> generateDebugContract() async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();
    
    // Add page to the PDF
    final PdfPage page = document.pages.add();
    
    // Get page graphics and size
    final PdfGraphics graphics = page.graphics;
    final Size pageSize = page.getClientSize();
    
    // Draw title
    graphics.drawString(
      'Debug Contract - Coordinate Test',
      PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(50, 50, 500, 50),
    );
    
    // Draw page info
    graphics.drawString(
      'Page Height: ${pageSize.height.toStringAsFixed(0)} points',
      PdfStandardFont(PdfFontFamily.helvetica, 10),
      bounds: Rect.fromLTWH(50, 100, 200, 20),
    );
    
    // Draw contract text
    const String contractText = '''
This is a debug contract to test signature positioning.

The signature boxes below show their exact coordinates.
''';
    
    graphics.drawString(
      contractText,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(50, 130, 500, 100),
    );
    
    // Calculate Y positions from top
    final double signatureLabelY = 250;
    final double signatureBoxY = 280;
    
    // Draw signature labels and boxes with coordinates
    graphics.drawString(
      'Party A Signature: (x:50, y:$signatureBoxY from top)',
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(50, signatureLabelY, 250, 20),
    );
    
    // Draw signature box for Party A
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(50, signatureBoxY, 200, 80),
      pen: PdfPen(PdfColor(0, 0, 0), width: 1),
    );
    
    // Draw center cross for Party A box
    graphics.drawLine(
      PdfPen(PdfColor(255, 0, 0), width: 0.5),
      Offset(50, signatureBoxY + 40),
      Offset(250, signatureBoxY + 40),
    );
    graphics.drawLine(
      PdfPen(PdfColor(255, 0, 0), width: 0.5),
      Offset(150, signatureBoxY),
      Offset(150, signatureBoxY + 80),
    );
    
    graphics.drawString(
      'Party B Signature: (x:300, y:$signatureBoxY from top)',
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(300, signatureLabelY, 250, 20),
    );
    
    // Draw signature box for Party B
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(300, signatureBoxY, 200, 80),
      pen: PdfPen(PdfColor(0, 0, 0), width: 1),
    );
    
    // Draw center cross for Party B box
    graphics.drawLine(
      PdfPen(PdfColor(255, 0, 0), width: 0.5),
      Offset(300, signatureBoxY + 40),
      Offset(500, signatureBoxY + 40),
    );
    graphics.drawLine(
      PdfPen(PdfColor(255, 0, 0), width: 0.5),
      Offset(400, signatureBoxY),
      Offset(400, signatureBoxY + 80),
    );
    
    // Draw coordinate grid
    graphics.drawString(
      'Coordinate Reference:',
      PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(50, 400, 200, 20),
    );
    
    // Draw Y coordinate markers
    for (int y = 0; y <= 600; y += 100) {
      graphics.drawString(
        'Y: $y',
        PdfStandardFont(PdfFontFamily.helvetica, 8),
        bounds: Rect.fromLTWH(10, y.toDouble(), 40, 20),
      );
      graphics.drawLine(
        PdfPen(PdfColor(200, 200, 200), width: 0.5),
        Offset(0, y.toDouble()),
        Offset(600, y.toDouble()),
      );
    }
    
    // Save and return the document
    final List<int> bytes = await document.save();
    document.dispose();
    
    return Uint8List.fromList(bytes);
  }
  
  // Store the correct signature box positions
  static const Map<String, Rect> signaturePositions = {
    'Party A': Rect.fromLTWH(50, 280, 200, 80),
    'Party B': Rect.fromLTWH(300, 280, 200, 80),
  };
}