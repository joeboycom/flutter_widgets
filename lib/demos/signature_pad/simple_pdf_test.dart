import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';

class SimplePdfTest extends StatefulWidget {
  const SimplePdfTest({super.key});

  @override
  State<SimplePdfTest> createState() => _SimplePdfTestState();
}

class _SimplePdfTestState extends State<SimplePdfTest> {
  Uint8List? _pdfBytes;
  String _info = '';

  @override
  void initState() {
    super.initState();
    _createTestPdf();
  }

  Future<void> _createTestPdf() async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;
    final Size pageSize = page.getClientSize();
    
    // Get page dimensions
    final pageWidth = pageSize.width;
    final pageHeight = pageSize.height;
    
    setState(() {
      _info = 'Page: ${pageWidth}x${pageHeight} points';
    });
    
    // Draw reference points
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final smallFont = PdfStandardFont(PdfFontFamily.helvetica, 8);
    
    // Top-left corner (0,0)
    graphics.drawString('(0,0) Top-Left', font, 
      bounds: Rect.fromLTWH(5, 5, 100, 20));
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(0, 0, 50, 50),
      pen: PdfPen(PdfColor(255, 0, 0), width: 2),
    );
    
    // Center of page
    final centerX = pageWidth / 2;
    final centerY = pageHeight / 2;
    graphics.drawString('Center', font,
      bounds: Rect.fromLTWH(centerX - 30, centerY - 10, 60, 20));
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(centerX - 25, centerY - 25, 50, 50),
      pen: PdfPen(PdfColor(0, 255, 0), width: 2),
    );
    
    // Bottom-left corner
    graphics.drawString('Bottom-Left', font,
      bounds: Rect.fromLTWH(5, pageHeight - 25, 100, 20));
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(0, pageHeight - 50, 50, 50),
      pen: PdfPen(PdfColor(0, 0, 255), width: 2),
    );
    
    // Draw the actual signature boxes from contract
    final boxPen = PdfPen(PdfColor(128, 0, 128), width: 3);
    
    // Party A box at (50, 480)
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(50, 480, 200, 80),
      pen: boxPen,
    );
    graphics.drawString('Party A\n(50, 480, 200x80)', font,
      bounds: Rect.fromLTWH(55, 485, 190, 40));
    
    // Party B box at (300, 480)
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(300, 480, 200, 80),
      pen: boxPen,
    );
    graphics.drawString('Party B\n(300, 480, 200x80)', font,
      bounds: Rect.fromLTWH(305, 485, 190, 40));
    
    // Draw Y-axis markers
    for (int y = 0; y <= pageHeight; y += 100) {
      graphics.drawLine(
        PdfPen(PdfColor(200, 200, 200), width: 0.5),
        Offset(0, y.toDouble()),
        Offset(40, y.toDouble()),
      );
      graphics.drawString('Y=$y', smallFont,
        bounds: Rect.fromLTWH(45, y.toDouble() - 5, 50, 10));
    }
    
    // Special marker at Y=480
    graphics.drawLine(
      PdfPen(PdfColor(255, 0, 0), width: 2),
      Offset(0, 480),
      Offset(pageWidth, 480),
    );
    graphics.drawString('Y=480 (Signature Line)', font,
      bounds: Rect.fromLTWH(pageWidth - 200, 465, 180, 20));
    
    final bytes = await document.save();
    document.dispose();
    
    setState(() {
      _pdfBytes = Uint8List.fromList(bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple PDF Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(_info, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('This shows where (0,0) is and where Y=480 is located'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addTestMark,
                  child: const Text('Add Red X at (50, 480)'),
                ),
              ],
            ),
          ),
          if (_pdfBytes != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: SfPdfViewer.memory(_pdfBytes!),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addTestMark() async {
    if (_pdfBytes == null) return;

    final PdfDocument document = PdfDocument(inputBytes: _pdfBytes);
    final PdfPage page = document.pages[0];
    
    // Draw a red X at exactly (50, 480)
    final pen = PdfPen(PdfColor(255, 0, 0), width: 3);
    page.graphics.drawLine(pen, const Offset(40, 470), const Offset(60, 490));
    page.graphics.drawLine(pen, const Offset(60, 470), const Offset(40, 490));
    
    // Draw text showing the position
    page.graphics.drawString(
      'X marks (50, 480)',
      PdfStandardFont(PdfFontFamily.helvetica, 10),
      bounds: Rect.fromLTWH(70, 475, 100, 20),
    );
    
    final bytes = await document.save();
    document.dispose();
    
    setState(() {
      _pdfBytes = Uint8List.fromList(bytes);
    });
  }
}