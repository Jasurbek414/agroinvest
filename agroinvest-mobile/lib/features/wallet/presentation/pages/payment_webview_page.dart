import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';

/// Loads a Payme/Click checkout URL (from `GET /payments/checkout-url`) inside
/// an in-app WebView. Infrastructure only: until real merchant credentials are
/// configured on the backend, PaymentService.buildCheckoutUrl still returns a
/// sandbox/test URL, so this page works end-to-end today in test mode and
/// needs no mobile-side changes once real credentials are added later.
class PaymentWebviewPage extends StatefulWidget {
  final String checkoutUrl;
  final String title;

  const PaymentWebviewPage({
    super.key,
    required this.checkoutUrl,
    this.title = "To'lov",
  });

  @override
  State<PaymentWebviewPage> createState() => _PaymentWebviewPageState();
}

class _PaymentWebviewPageState extends State<PaymentWebviewPage> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress / 100),
          onPageStarted: (_) => setState(() => _hasError = false),
          onWebResourceError: (_) => setState(() => _hasError = true),
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_progress < 1)
            LinearProgressIndicator(
              value: _progress == 0 ? null : _progress,
              color: AppColors.primary,
              backgroundColor: AppColors.border,
              minHeight: 2,
            ),
          Expanded(
            child: _hasError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            "To'lov sahifasini yuklashda xatolik yuz berdi",
                            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _controller.reload(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Qayta urinish'),
                          ),
                        ],
                      ),
                    ),
                  )
                : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
