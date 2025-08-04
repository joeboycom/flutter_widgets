import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class PdfCoordinateTest extends StatefulWidget {
  const PdfCoordinateTest({super.key});

  @override
  State<PdfCoordinateTest> createState() => _PdfCoordinateTestState();
}

class _PdfCoordinateTestState extends State<PdfCoordinateTest> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final GlobalKey<SfSignaturePadState> _signatureKey = GlobalKey();
  
  Uint8List? _pdfBytes;
  bool _showSignaturePad = false;
  double _testX = 50;
  double _testY = 50;
  String _coordinateInfo = '';

  @override
  void initState() {
    super.initState();
    _generateTestPdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Coordinate Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Test Coordinates: X=$_testX, Y=$_testY',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('X:'),
                    SizedBox(
                      width: 200,
                      child: Slider(
                        value: _testX,
                        min: 0,
                        max: 600,
                        divisions: 60,
                        label: _testX.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _testX = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Y:'),
                    SizedBox(
                      width: 200,
                      child: Slider(
                        value: _testY,
                        min: 0,
                        max: 800,
                        divisions: 80,
                        label: _testY.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _testY = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _addTestSignature,
                  child: const Text('Add Test Signature at Position'),
                ),
                if (_coordinateInfo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _coordinateInfo,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          if (_pdfBytes != null) ...[
            const Divider(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SfPdfViewer.memory(
                    _pdfBytes!,
                    key: _pdfViewerKey,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateTestPdf() async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;
    final Size pageSize = page.getClientSize();
    
    // Draw title
    graphics.drawString(
      'PDF Coordinate Test Page',
      PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(50, 20, 500, 30),
    );
    
    // Draw page size info
    graphics.drawString(
      'Page Size: ${pageSize.width} x ${pageSize.height} points',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(50, 60, 500, 20),
    );
    
    // Draw grid
    final gridPen = PdfPen(PdfColor(200, 200, 200), width: 0.5);
    final textFont = PdfStandardFont(PdfFontFamily.helvetica, 8);
    
    // Vertical lines
    for (int x = 0; x <= pageSize.width; x += 50) {
      graphics.drawLine(gridPen, Offset(x.toDouble(), 0), Offset(x.toDouble(), pageSize.height));
      if (x % 100 == 0) {
        graphics.drawString(
          'X:$x',
          textFont,
          bounds: Rect.fromLTWH(x.toDouble() + 2, 5, 40, 15),
        );
      }
    }
    
    // Horizontal lines
    for (int y = 0; y <= pageSize.height; y += 50) {
      graphics.drawLine(gridPen, Offset(0, y.toDouble()), Offset(pageSize.width, y.toDouble()));
      if (y % 100 == 0) {
        graphics.drawString(
          'Y:$y',
          textFont,
          bounds: Rect.fromLTWH(5, y.toDouble() + 2, 40, 15),
        );
      }
    }
    
    // Draw the signature boxes from the contract
    final boxPen = PdfPen(PdfColor(0, 0, 255), width: 2);
    
    // Party A box
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(50, 480, 200, 80),
      pen: boxPen,
    );
    graphics.drawString(
      'Party A Box\n(50, 480, 200x80)',
      PdfStandardFont(PdfFontFamily.helvetica, 10),
      bounds: Rect.fromLTWH(55, 485, 190, 40),
    );
    
    // Party B box
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(300, 480, 200, 80),
      pen: boxPen,
    );
    graphics.drawString(
      'Party B Box\n(300, 480, 200x80)',
      PdfStandardFont(PdfFontFamily.helvetica, 10),
      bounds: Rect.fromLTWH(305, 485, 190, 40),
    );
    
    // Draw markers for common Y positions
    final markerPen = PdfPen(PdfColor(255, 0, 0), width: 1);
    final markerY = [100, 200, 300, 400, 480, 500, 600, 700];
    for (final y in markerY) {
      graphics.drawLine(
        markerPen,
        Offset(0, y.toDouble()),
        Offset(30, y.toDouble()),
      );
      graphics.drawString(
        'Y=$y',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(35, y.toDouble() - 5, 50, 15),
      );
    }
    
    final bytes = await document.save();
    document.dispose();
    
    setState(() {
      _pdfBytes = Uint8List.fromList(bytes);
      _coordinateInfo = 'Page Height: ${pageSize.height.toStringAsFixed(0)}\n' +
                       'Signature boxes at Y=480 (from top)';
    });
  }

  Future<void> _addTestSignature() async {
    if (_pdfBytes == null) return;

    try {
      // Create a simple test signature
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 50), paint);
      canvas.drawLine(const Offset(0, 0), const Offset(100, 50), paint);
      canvas.drawLine(const Offset(100, 0), const Offset(0, 50), paint);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'TEST',
          style: const TextStyle(color: Colors.red, fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(25, 15));
      
      final picture = recorder.endRecording();
      final img = await picture.toImage(100, 50);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final signatureBytes = byteData!.buffer.asUint8List();
      
      // Add to PDF
      final PdfDocument document = PdfDocument(inputBytes: _pdfBytes);
      final PdfPage page = document.pages[0];
      final PdfBitmap bitmap = PdfBitmap(signatureBytes);
      
      // Draw at the test position
      page.graphics.drawImage(
        bitmap,
        Rect.fromLTWH(_testX, _testY, 100, 50),
      );
      
      // Also draw position text
      page.graphics.drawString(
        '($_testX, $_testY)',
        PdfStandardFont(PdfFontFamily.helvetica, 8),
        bounds: Rect.fromLTWH(_testX, _testY - 15, 100, 15),
      );
      
      final bytes = await document.save();
      document.dispose();
      
      setState(() {
        _pdfBytes = Uint8List.fromList(bytes);
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}