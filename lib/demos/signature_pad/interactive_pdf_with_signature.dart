import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'pdf_generator.dart';

class InteractivePdfWithSignature extends StatefulWidget {
  const InteractivePdfWithSignature({super.key});

  @override
  State<InteractivePdfWithSignature> createState() => _InteractivePdfWithSignatureState();
}

class _InteractivePdfWithSignatureState extends State<InteractivePdfWithSignature> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final GlobalKey<SfSignaturePadState> _signatureKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  
  Uint8List? _originalPdfBytes;
  Uint8List? _currentPdfBytes;
  String? _fileName;
  bool _isLoading = false;
  bool _showSignaturePad = false;
  
  // Store which signature position we're currently editing
  String? _currentSignaturePosition;
  
  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive PDF with Signature'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_currentPdfBytes != null && _originalPdfBytes != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetPdf,
              tooltip: 'Reset PDF',
            ),
          if (_currentPdfBytes != null)
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: _savePdf,
              tooltip: 'Save PDF',
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickPDF,
                          icon: const Icon(Icons.file_open),
                          label: const Text('Select PDF'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _generateContract,
                          icon: const Icon(Icons.description),
                          label: const Text('Generate Contract'),
                        ),
                      ],
                    ),
                    if (_currentPdfBytes != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Click the buttons below to add signatures:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showSignatureDialog('Party A'),
                            icon: const Icon(Icons.person),
                            label: const Text('Sign as Party A'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showSignatureDialog('Party B'),
                            icon: const Icon(Icons.person_outline),
                            label: const Text('Sign as Party B'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_fileName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'File: $_fileName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              if (_currentPdfBytes != null) ...[
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
                        _currentPdfBytes!,
                        key: _pdfViewerKey,
                        controller: _pdfViewerController,
                      ),
                    ),
                  ),
                ),
              ],
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          if (_showSignaturePad) _buildSignaturePadOverlay(),
        ],
      ),
    );
  }

  Widget _buildSignaturePadOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 350,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sign as $_currentSignaturePosition',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _cancelSignature,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: SfSignaturePad(
                    key: _signatureKey,
                    backgroundColor: Colors.white,
                    strokeColor: Colors.black,
                    minimumStrokeWidth: 1.0,
                    maximumStrokeWidth: 4.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _clearSignature,
                    child: const Text('Clear'),
                  ),
                  ElevatedButton(
                    onPressed: _applySignature,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply Signature'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignatureDialog(String position) {
    setState(() {
      _currentSignaturePosition = position;
      _showSignaturePad = true;
    });
  }

  void _cancelSignature() {
    setState(() {
      _showSignaturePad = false;
      _currentSignaturePosition = null;
    });
    _clearSignature();
  }

  void _clearSignature() {
    _signatureKey.currentState?.clear();
  }

  Future<void> _applySignature() async {
    if (_currentPdfBytes == null || _currentSignaturePosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get signature image
      final ui.Image signatureImage = await _signatureKey.currentState!.toImage();
      final ByteData? byteData = await signatureImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List signatureBytes = byteData!.buffer.asUint8List();
      
      // Load PDF document
      final PdfDocument document = PdfDocument(inputBytes: _currentPdfBytes);
      final PdfPage page = document.pages[0]; // First page
      
      // Create bitmap from signature
      final PdfBitmap bitmap = PdfBitmap(signatureBytes);
      
      // Define signature positions based on the position
      double x, y;
      if (_currentSignaturePosition == 'Party A') {
        x = 50;
        y = 480;
      } else {
        x = 300;
        y = 480;
      }
      
      // Draw signature on PDF
      page.graphics.drawImage(
        bitmap,
        Rect.fromLTWH(x, y, 200, 80),
      );
      
      // Save the modified PDF
      final List<int> bytes = await document.save();
      document.dispose();
      
      setState(() {
        _currentPdfBytes = Uint8List.fromList(bytes);
        _showSignaturePad = false;
        _currentSignaturePosition = null;
        _isLoading = false;
      });
      
      _showSnackBar('Signature added successfully');
      _clearSignature();
      
      // Reload the PDF viewer
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {});
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error applying signature: $e');
    }
  }

  Future<void> _resetPdf() async {
    if (_originalPdfBytes != null) {
      setState(() {
        _currentPdfBytes = Uint8List.fromList(_originalPdfBytes!);
      });
      _showSnackBar('PDF reset to original');
    }
  }

  Future<void> _savePdf() async {
    if (_currentPdfBytes == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/signed_${timestamp}_$_fileName');
      await file.writeAsBytes(_currentPdfBytes!);
      
      _showSnackBar('PDF saved to: ${file.path}');
    } catch (e) {
      _showSnackBar('Error saving PDF: $e');
    }
  }

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        Uint8List? bytes;
        
        if (result.files.single.bytes != null) {
          bytes = result.files.single.bytes;
        } else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          bytes = await file.readAsBytes();
        }
        
        if (bytes != null) {
          setState(() {
            _originalPdfBytes = Uint8List.fromList(bytes!);
            _currentPdfBytes = Uint8List.fromList(bytes);
            _fileName = result.files.single.name;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e');
    }
  }

  Future<void> _generateContract() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await PdfGenerator.generateSampleContract();
      setState(() {
        _originalPdfBytes = Uint8List.fromList(bytes);
        _currentPdfBytes = Uint8List.fromList(bytes);
        _fileName = 'sample_contract.pdf';
        _isLoading = false;
      });
      _showSnackBar('Contract generated successfully');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error generating contract: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}