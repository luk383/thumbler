import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/book_lookup_service.dart';

/// Returns a [BookInfo] when a valid ISBN is scanned and found.
class IsbnScannerPage extends StatefulWidget {
  const IsbnScannerPage({super.key});

  @override
  State<IsbnScannerPage> createState() => _IsbnScannerPageState();
}

class _IsbnScannerPageState extends State<IsbnScannerPage> {
  final _controller = MobileScannerController();
  final _service = BookLookupService();

  bool _loading = false;
  String? _error;
  String? _lastScanned;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_loading) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw == _lastScanned) return;

    // Accept EAN-13 / ISBN-13 / ISBN-10
    final isIsbn = (barcode?.format == BarcodeFormat.ean13 ||
            barcode?.format == BarcodeFormat.ean8 ||
            barcode?.format == BarcodeFormat.code128) &&
        (raw.length == 10 || raw.length == 13);

    if (!isIsbn) {
      setState(() => _error = 'Codice non riconosciuto come ISBN. Riprova.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _lastScanned = raw;
    });

    await _controller.stop();

    final book = await _service.lookupIsbn(raw);

    if (!mounted) return;

    if (book == null) {
      setState(() {
        _loading = false;
        _error = 'Libro non trovato per ISBN $raw. Inserisci manualmente.';
      });
      await _controller.start();
      return;
    }

    if (mounted) Navigator.of(context).pop(book);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scansiona ISBN'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, state, _) => Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: Colors.white,
              ),
            ),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Viewfinder overlay
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: cs.primary, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_loading)
                  const CircularProgressIndicator(color: Colors.white)
                else if (_error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  const Text(
                    'Inquadra il codice a barre del libro',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
