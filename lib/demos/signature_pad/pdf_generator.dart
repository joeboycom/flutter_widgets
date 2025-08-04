import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:ui';

class PdfGenerator {
  static Future<Uint8List> generateSampleContract() async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();
    
    // Add page to the PDF
    final PdfPage page = document.pages.add();
    
    // Get page graphics
    final PdfGraphics graphics = page.graphics;
    
    // Draw title
    graphics.drawString(
      'Sample Contract Agreement',
      PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(50, 50, 500, 50),
    );
    
    // Draw contract text
    const String contractText = '''
This is a sample contract agreement between Party A and Party B.

Terms and Conditions:
1. Both parties agree to the terms outlined in this document.
2. This agreement is valid from the date of signing.
3. Any disputes will be resolved through mutual discussion.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod 
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, 
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo 
consequat.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore 
eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, 
sunt in culpa qui officia deserunt mollit anim id est laborum.

By signing below, both parties acknowledge and agree to the terms stated above.
''';
    
    graphics.drawString(
      contractText,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(50, 120, 500, 300),
      format: PdfStringFormat(alignment: PdfTextAlignment.justify),
    );
    
    // Draw signature labels and boxes
    graphics.drawString(
      'Party A Signature:',
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(50, 450, 200, 20),
    );
    
    // Draw signature box for Party A
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(50, 480, 200, 80),
      pen: PdfPen(PdfColor(0, 0, 0), width: 1),
    );
    
    graphics.drawString(
      'Party B Signature:',
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(300, 450, 200, 20),
    );
    
    // Draw signature box for Party B
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(300, 480, 200, 80),
      pen: PdfPen(PdfColor(0, 0, 0), width: 1),
    );
    
    // Draw date fields
    graphics.drawString(
      'Date: ________________',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(50, 580, 200, 20),
    );
    
    graphics.drawString(
      'Date: ________________',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(300, 580, 200, 20),
    );
    
    // Save and return the document
    final List<int> bytes = await document.save();
    document.dispose();
    
    return Uint8List.fromList(bytes);
  }
}