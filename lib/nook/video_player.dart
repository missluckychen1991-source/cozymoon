import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../content/videos.dart';

/// Opens a calm video. Videos with an id play inside the app through
/// YouTube's privacy-enhanced player, with no recommendations rabbit hole.
Future<void> openCalmVideo(BuildContext context, CalmVideo v) async {
  final id = v.youtubeId;
  if (id == null || id.isEmpty || kIsWeb) {
    // The in-app player is phone-only; the web preview opens YouTube instead.
    final uri = (id == null || id.isEmpty)
        ? Uri.https('www.youtube.com', '/results', {'search_query': v.search})
        : Uri.https('www.youtube-nocookie.com', '/embed/$id', {'rel': '0'});
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open YouTube right now.")));
    }
    return;
  }
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => _CalmPlayer(video: v)));
}

class _CalmPlayer extends StatefulWidget {
  const _CalmPlayer({required this.video});
  final CalmVideo video;

  @override
  State<_CalmPlayer> createState() => _CalmPlayerState();
}

class _CalmPlayerState extends State<_CalmPlayer> {
  late final WebViewController _web = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.black)
    ..setNavigationDelegate(NavigationDelegate(
      // Stay in the player: links out of it open nowhere.
      onNavigationRequest: (r) =>
          r.url.startsWith('https://www.youtube-nocookie.com/embed/') ||
                  r.url.startsWith('about:') ||
                  r.url.startsWith('data:')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
    ))
    ..loadHtmlString(_html(widget.video.youtubeId!),
        baseUrl: 'https://cozymoon.app');

  static String _html(String id) => '''
<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
<style>html,body{margin:0;height:100%;background:#000}iframe{position:absolute;inset:0;width:100%;height:100%;border:0}</style>
</head><body>
<iframe src="https://www.youtube-nocookie.com/embed/$id?rel=0&modestbranding=1&playsinline=1"
 allow="autoplay; encrypted-media; picture-in-picture" allowfullscreen></iframe>
</body></html>''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('${widget.video.emoji} ${widget.video.title}')),
      body: Column(children: [
        AspectRatio(
            aspectRatio: 16 / 9, child: WebViewWidget(controller: _web)),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
              'Just this one. When it ends, maybe close your eyes for a minute 💛',
              textAlign: TextAlign.center),
        ),
      ]),
    );
  }
}
