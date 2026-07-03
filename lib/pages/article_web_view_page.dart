import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n/app_strings.dart';

class ArticleWebViewPage extends StatefulWidget {
  final Uri url;
  final String title;

  const ArticleWebViewPage({super.key, required this.url, required this.title});

  static bool get supportsEmbeddedWebView {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => false,
    };
  }

  @override
  State<ArticleWebViewPage> createState() => _ArticleWebViewPageState();
}

class _ArticleWebViewPageState extends State<ArticleWebViewPage> {
  late final WebViewController _controller;
  var _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress);
            }
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _progress = 0;
                _error = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _progress = 100);
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            if (mounted) {
              setState(() => _error = error.description);
            }
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    final zh = AppStrings.isZh;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh),
            tooltip: zh ? '刷新' : 'Refresh',
          ),
          IconButton(
            onPressed: () =>
                launchUrl(widget.url, mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_browser),
            tooltip: zh ? '在浏览器打开' : 'Open in browser',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
          if (_error != null)
            _WebViewError(
              message: _error!,
              onRetry: () => _controller.reload(),
              onOpenExternal: () =>
                  launchUrl(widget.url, mode: LaunchMode.externalApplication),
            ),
        ],
      ),
    );
  }
}

class _WebViewError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onOpenExternal;

  const _WebViewError({
    required this.message,
    required this.onRetry,
    required this.onOpenExternal,
  });

  @override
  Widget build(BuildContext context) {
    final zh = AppStrings.isZh;
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.public_off_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                zh ? '网页加载失败' : 'Failed to load page',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(zh ? '重试' : 'Retry'),
                  ),
                  FilledButton.icon(
                    onPressed: onOpenExternal,
                    icon: const Icon(Icons.open_in_browser),
                    label: Text(zh ? '浏览器打开' : 'Open in browser'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
