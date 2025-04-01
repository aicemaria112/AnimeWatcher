import 'dart:io';
import 'package:flutter/material.dart';
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
  late PDFViewController _pdfViewController;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadScrollDirection();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_isHorizontalScroll ? Icons.swap_horiz : Icons.swap_vert),
            onPressed: _toggleScrollDirection,
            tooltip: 'Toggle scroll direction',
          ),
          IconButton(
            icon: Icon(_isContinuousMode ? Icons.view_stream : Icons.view_agenda),
            onPressed: _toggleContinuousMode,
            tooltip: 'Toggle continuous mode',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                const Text('PDF', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.pdfPath,
            enableSwipe: true,
            swipeHorizontal: _isHorizontalScroll,
            fitEachPage: true,
            autoSpacing: !_isContinuousMode,
            pageFling: !_isContinuousMode,
            pageSnap: !_isContinuousMode,
            fitPolicy: FitPolicy.BOTH,
            
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
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink(),
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
      ),
    );
  }
}