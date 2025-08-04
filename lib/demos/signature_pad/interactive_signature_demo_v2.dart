import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'pdf_generator.dart';

class InteractiveSignatureDemoV2 extends StatefulWidget {
  const InteractiveSignatureDemoV2({super.key});

  @override
  State<InteractiveSignatureDemoV2> createState() => _InteractiveSignatureDemoV2State();
}

class _InteractiveSignatureDemoV2State extends State<InteractiveSignatureDemoV2> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final GlobalKey<SfSignaturePadState> _signatureKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  
  Uint8List? _pdfBytes;
  String? _fileName;
  bool _isLoading = false;
  bool _showSignaturePad = false;
  double _pdfPageHeight = 0;
  double _pdfPageWidth = 0;
  
  // Signature area coordinates in PDF points (72 points = 1 inch)
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
  final Map<int, Uint8List> _signatures = {};

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Signature Demo V2'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_signatures.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveFinalPDF,
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
                  ],
                ),
              ),
              if (_fileName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        'File: $_fileName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_signatures.isNotEmpty)
                        Text(
                          'Signatures added: ${_signatures.length}',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                    ],
                  ),
                ),
              if (_pdfBytes != null) ...[
                const Divider(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          SfPdfViewer.memory(
                            _pdfBytes!,
                            key: _pdfViewerKey,
                            controller: _pdfViewerController,
                            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                              setState(() {
                                _pdfPageHeight = details.document.pages[0].size.height;
                                _pdfPageWidth = details.document.pages[0].size.width;
                              });
                              _showSignatureAreaHints();
                            },
                            onPageChanged: (PdfPageChangedDetails details) {
                              setState(() {}); // Refresh to update signature area positions
                            },
                          ),
                          if (_pdfPageHeight > 0 && _pdfPageWidth > 0)
                            ..._buildSignatureAreaOverlays(constraints),
                        ],
                      );
                    },
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

  List<Widget> _buildSignatureAreaOverlays(BoxConstraints constraints) {
    final currentPageNumber = _pdfViewerController.pageNumber;
    final zoomLevel = _pdfViewerController.zoomLevel;
    
    // Get the visible size of the PDF viewer
    final viewerWidth = constraints.maxWidth;
    final viewerHeight = constraints.maxHeight;
    
    // Calculate the scale factor between PDF points and screen pixels
    final baseScale = viewerWidth / _pdfPageWidth;
    final scale = baseScale * zoomLevel;
    
    // Calculate the offset for centered PDF
    final scaledPageWidth = _pdfPageWidth * scale;
    final scaledPageHeight = _pdfPageHeight * scale;
    final offsetX = (viewerWidth - scaledPageWidth) / 2;
    final offsetY = (viewerHeight - scaledPageHeight) / 2;
    
    return _signatureAreas
        .where((area) => area.page == currentPageNumber)
        .map((area) {
      final index = _signatureAreas.indexOf(area);
      final hasSignature = _signatures.containsKey(index);
      
      // Convert PDF coordinates to screen coordinates
      // PDF coordinate system: origin at bottom-left
      // Screen coordinate system: origin at top-left
      final screenX = offsetX + (area.x * scale);
      final screenY = offsetY + ((_pdfPageHeight - area.y - area.height) * scale);
      final screenWidth = area.width * scale;
      final screenHeight = area.height * scale;
      
      return Positioned(
        left: screenX,
        top: screenY,
        child: GestureDetector(
          onTap: () => _showSignatureDialog(area),
          child: Container(
            width: screenWidth,
            height: screenHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: hasSignature ? Colors.green : Colors.blue,
                width: 2,
              ),
              color: hasSignature 
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasSignature ? Icons.check : Icons.edit,
                    color: hasSignature ? Colors.green : Colors.blue,
                    size: 20 * zoomLevel,
                  ),
                  Text(
                    area.label,
                    style: TextStyle(
                      fontSize: 12 * zoomLevel,
                      color: hasSignature ? Colors.green : Colors.blue,
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
                    onPressed: _saveSignatureToMemory,
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

  Future<void> _saveSignatureToMemory() async {
    if (_currentSignatureArea == null) return;

    try {
      final ui.Image signatureImage = await _signatureKey.currentState!.toImage();
      final ByteData? byteData = await signatureImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List signatureBytes = byteData!.buffer.asUint8List();
      
      final index = _signatureAreas.indexOf(_currentSignatureArea!);
      setState(() {
        _signatures[index] = signatureBytes;
        _showSignaturePad = false;
        _currentSignatureArea = null;
      });
      
      _showSnackBar('Signature saved. Add more signatures or click Save PDF.');
      _clearSignature();
    } catch (e) {
      _showSnackBar('Error saving signature: $e');
    }
  }

  Future<void> _saveFinalPDF() async {
    if (_pdfBytes == null || _signatures.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final PdfDocument document = PdfDocument(inputBytes: _pdfBytes);
      
      for (var entry in _signatures.entries) {
        final index = entry.key;
        final signatureBytes = entry.value;
        final area = _signatureAreas[index];
        
        if (area.page <= document.pages.count) {
          final PdfPage page = document.pages[area.page - 1];
          final PdfBitmap bitmap = PdfBitmap(signatureBytes);
          
          page.graphics.drawImage(
            bitmap,
            Rect.fromLTWH(
              area.x.toDouble(),
              area.y.toDouble(),
              area.width.toDouble(),
              area.height.toDouble(),
            ),
          );
        }
      }
      
      final List<int> bytes = await document.save();
      document.dispose();
      
      setState(() {
        _pdfBytes = Uint8List.fromList(bytes);
        _signatures.clear();
        _isLoading = false;
      });
      
      _showSnackBar('All signatures embedded in PDF successfully');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
        setState(() {
          _signatures.clear();
        });
        
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
      _signatures.clear();
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