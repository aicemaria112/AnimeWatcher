import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../services/storage_service.dart';

class PDFViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.pdfPath,
    required this.title,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isHorizontalScroll = true;
  bool _isContinuousMode = true;
  bool _isControlsVisible = true;
  late PDFViewController _pdfViewController;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadScrollDirection();
    _enterFullScreen();
  }

  @override
  void dispose() {
    _exitFullScreen();
    super.dispose();
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _loadScrollDirection() async {
    final direction = await _storageService.getScrollDirection();
    setState(() => _isHorizontalScroll = direction ?? true);
  }

  void _toggleScrollDirection() async {
    setState(() {
      _isHorizontalScroll = !_isHorizontalScroll;
    });
    await _storageService.saveScrollDirection(_isHorizontalScroll);
  }

  void _toggleContinuousMode() {
    setState(() {
      _isContinuousMode = !_isContinuousMode;
    });
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
           
            // PDF View
            PDFView(
              filePath: widget.pdfPath,
              enableSwipe: true,
              swipeHorizontal: !_isHorizontalScroll,
              fitEachPage: true,
              autoSpacing: false,
              pageFling: !_isContinuousMode,
              pageSnap: !_isContinuousMode,
              fitPolicy: FitPolicy.BOTH,
              backgroundColor: Colors.black,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages!;
                  _isLoading = false;
                });
              },
              onError: (error) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al cargar PDF: $error')),
                );
              },
              onPageError: (page, error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error en página $page: $error')),
                );
              },
              onViewCreated: (PDFViewController pdfViewController) {
                _pdfViewController = pdfViewController;
              },
              onPageChanged: (int? page, int? total) {
                if (page != null) {
                  setState(() => _currentPage = page);
                }
              },
            ),
            // Loading indicator
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
            
            // Floating controls that appear/disappear on tap
            if (_isControlsVisible) ...[              
              // Back button
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _goBack,
                  ),
                ),
              ),
              
              // Title
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              
              // Controls row at the top right
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isHorizontalScroll ? Icons.swap_horiz : Icons.swap_vert,
                          color: Colors.white,
                        ),
                        onPressed: _toggleScrollDirection,
                        tooltip: 'Toggle scroll direction',
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isContinuousMode ? Icons.view_stream : Icons.view_agenda,
                          color: Colors.white,
                        ),
                        onPressed: _toggleContinuousMode,
                        tooltip: 'Toggle continuous mode',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Page indicator at the bottom
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Página ${_currentPage + 1}/$_totalPages',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}