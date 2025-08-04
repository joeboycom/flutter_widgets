import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

class SignaturePadDemo extends StatefulWidget {
  const SignaturePadDemo({super.key});

  @override
  State<SignaturePadDemo> createState() => _SignaturePadDemoState();
}

class _SignaturePadDemoState extends State<SignaturePadDemo> {
  final GlobalKey<SfSignaturePadState> signatureGlobalKey = GlobalKey();
  Uint8List? _pdfBytes;
  String? _fileName;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signature Pad Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickPDF,
                      icon: const Icon(Icons.file_open),
                      label: const Text('Select PDF'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _downloadSamplePDF,
                      icon: const Icon(Icons.download),
                      label: const Text('Download Sample'),
                    ),
                  ],
                ),
                if (_fileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Selected: $_fileName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          if (_pdfBytes != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Draw your signature:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SfSignaturePad(
                      key: signatureGlobalKey,
                      backgroundColor: Colors.white,
                      strokeColor: Colors.black,
                      minimumStrokeWidth: 1.0,
                      maximumStrokeWidth: 4.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _clearSignature,
                        child: const Text('Clear'),
                      ),
                      ElevatedButton(
                        onPressed: _saveSignatureToPDF,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save to PDF'),
                      ),
                      ElevatedButton(
                        onPressed: _uploadPDF,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Upload'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        if (result.files.single.bytes != null) {
          setState(() {
            _pdfBytes = result.files.single.bytes;
            _fileName = result.files.single.name;
          });
        } else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final bytes = await file.readAsBytes();
          setState(() {
            _pdfBytes = bytes;
            _fileName = result.files.single.name;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e');
    }
  }

  Future<void> _downloadSamplePDF() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _pdfBytes = response.bodyBytes;
          _fileName = 'sample.pdf';
          _isLoading = false;
        });
        _showSnackBar('Sample PDF downloaded successfully');
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error downloading sample PDF: $e');
    }
  }

  void _clearSignature() {
    signatureGlobalKey.currentState!.clear();
  }

  Future<void> _saveSignatureToPDF() async {
    if (_pdfBytes == null) {
      _showSnackBar('Please select a PDF first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final PdfDocument document = PdfDocument(inputBytes: _pdfBytes);
      final PdfPage page = document.pages[0];
      
      final ui.Image signatureImage = await signatureGlobalKey.currentState!.toImage();
      final ByteData? byteData = await signatureImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List signatureBytes = byteData!.buffer.asUint8List();
      
      final PdfBitmap bitmap = PdfBitmap(signatureBytes);
      
      page.graphics.drawImage(
        bitmap,
        const Rect.fromLTWH(100, 500, 200, 80),
      );
      
      final List<int> bytes = await document.save();
      document.dispose();
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/signed_$_fileName');
      await file.writeAsBytes(bytes);
      
      setState(() {
        _pdfBytes = Uint8List.fromList(bytes);
        _fileName = 'signed_$_fileName';
        _isLoading = false;
      });
      
      _showSnackBar('Signature added to PDF successfully');
      _clearSignature();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error saving signature: $e');
    }
  }

  Future<void> _uploadPDF() async {
    if (_pdfBytes == null) {
      _showSnackBar('No PDF to upload');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://httpbin.org/post'),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _pdfBytes!,
          filename: _fileName,
        ),
      );
      
      var response = await request.send();
      
      if (response.statusCode == 200) {
        _showSnackBar('PDF uploaded successfully');
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error uploading PDF: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}