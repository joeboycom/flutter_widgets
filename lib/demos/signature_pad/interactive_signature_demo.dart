import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'pdf_generator.dart';

class InteractiveSignatureDemo extends StatefulWidget {
  const InteractiveSignatureDemo({super.key});

  @override
  State<InteractiveSignatureDemo> createState() => _InteractiveSignatureDemoState();
}

class _InteractiveSignatureDemoState extends State<InteractiveSignatureDemo> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final GlobalKey<SfSignaturePadState> _signatureKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  
  Uint8List? _pdfBytes;
  String? _fileName;
  bool _isLoading = false;
  bool _showSignaturePad = false;
  
  // Signature area coordinates matching the contract PDF
  final List<SignatureArea> _signatureAreas = [
    SignatureArea(
      page: 1,
      x: 50,
      y: 480,
      width: 200,
      height: 80,
      label: 'Party A',
    ),
    SignatureArea(
      page: 1,
      x: 300,
      y: 480,
      width: 200,
      height: 80,
      label: 'Party B',
    ),
  ];
  
  SignatureArea? _currentSignatureArea;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Signature Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Wrap(
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
                    ElevatedButton.icon(
                      onPressed: _downloadSamplePDF,
                      icon: const Icon(Icons.download),
                      label: const Text('Download IRS Form'),
                    ),
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
              if (_pdfBytes != null) ...[
                const Divider(),
                Expanded(
                  child: Stack(
                    children: [
                      SfPdfViewer.memory(
                        _pdfBytes!,
                        key: _pdfViewerKey,
                        controller: _pdfViewerController,
                        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                          _showSignatureAreaHints();
                        },
                      ),
                      ..._buildSignatureAreaButtons(),
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
          if (_showSignaturePad) _buildSignaturePadOverlay(),
        ],
      ),
    );
  }

  List<Widget> _buildSignatureAreaButtons() {
    return _signatureAreas.map((area) {
      return Positioned(
        left: area.x.toDouble(),
        top: area.y.toDouble(),
        child: GestureDetector(
          onTap: () => _showSignatureDialog(area),
          child: Container(
            width: area.width.toDouble(),
            height: area.height.toDouble(),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit, color: Colors.blue),
                  Text(
                    area.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSignaturePadOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 400,
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
                    'Sign here: ${_currentSignatureArea?.label}',
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
                  ElevatedButton(
                    onPressed: _clearSignature,
                    child: const Text('Clear'),
                  ),
                  ElevatedButton(
                    onPressed: _saveSignature,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Signature'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignatureAreaHints() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Click on the blue areas to add your signature'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSignatureDialog(SignatureArea area) {
    setState(() {
      _currentSignatureArea = area;
      _showSignaturePad = true;
    });
  }

  void _cancelSignature() {
    setState(() {
      _showSignaturePad = false;
      _currentSignatureArea = null;
    });
    _clearSignature();
  }

  void _clearSignature() {
    _signatureKey.currentState?.clear();
  }

  Future<void> _saveSignature() async {
    if (_pdfBytes == null || _currentSignatureArea == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final PdfDocument document = PdfDocument(inputBytes: _pdfBytes);
      
      if (_currentSignatureArea!.page <= document.pages.count) {
        final PdfPage page = document.pages[_currentSignatureArea!.page - 1];
        
        final ui.Image signatureImage = await _signatureKey.currentState!.toImage();
        final ByteData? byteData = await signatureImage.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List signatureBytes = byteData!.buffer.asUint8List();
        
        final PdfBitmap bitmap = PdfBitmap(signatureBytes);
        
        page.graphics.drawImage(
          bitmap,
          Rect.fromLTWH(
            _currentSignatureArea!.x.toDouble(),
            _currentSignatureArea!.y.toDouble(),
            _currentSignatureArea!.width.toDouble(),
            _currentSignatureArea!.height.toDouble(),
          ),
        );
        
        final List<int> bytes = await document.save();
        document.dispose();
        
        setState(() {
          _pdfBytes = Uint8List.fromList(bytes);
          _showSignaturePad = false;
          _currentSignatureArea = null;
          _isLoading = false;
        });
        
        _showSnackBar('Signature added successfully');
        _clearSignature();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error saving signature: $e');
    }
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

  Future<void> _generateContract() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await PdfGenerator.generateSampleContract();
      setState(() {
        _pdfBytes = bytes;
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

  Future<void> _downloadSamplePDF() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Using a sample PDF with forms/signature fields
      final response = await http.get(
        Uri.parse('https://www.irs.gov/pub/irs-pdf/fw9.pdf'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _pdfBytes = response.bodyBytes;
          _fileName = 'IRS_Form_W9.pdf';
          _isLoading = false;
        });
        _showSnackBar('IRS form downloaded successfully');
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error downloading PDF: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class SignatureArea {
  final int page;
  final int x;
  final int y;
  final int width;
  final int height;
  final String label;

  SignatureArea({
    required this.page,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
  });
}