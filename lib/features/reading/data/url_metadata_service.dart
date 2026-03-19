import 'package:http/http.dart' as http;

import '../domain/reading_item.dart';

class UrlMetadata {
  const UrlMetadata({
    required this.title,
    this.author,
    this.thumbnailUrl,
    this.description,
    required this.type,
    required this.sourceUrl,
  });

  final String title;
  final String? author;
  final String? thumbnailUrl;
  final String? description;
  final ReadingType type;
  final String sourceUrl;
}

class UrlMetadataService {
  /// Fetches Open Graph metadata from a URL and auto-detects content type.
  Future<UrlMetadata?> fetch(String rawUrl) async {
    final url = rawUrl.trim();
    if (url.isEmpty) return null;

    final type = _detectType(url);

    try {
      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (compatible; WolfLabBot/1.0)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final html = response.body;
      final title = _ogTag(html, 'og:title') ??
          _metaTag(html, 'title') ??
          _titleTag(html) ??
          uri.host;
      final image = _ogTag(html, 'og:image');
      final description = _ogTag(html, 'og:description') ??
          _metaTag(html, 'description');
      final siteName = _ogTag(html, 'og:site_name');

      return UrlMetadata(
        title: _cleanTitle(title, siteName),
        author: siteName ?? _authorFromUrl(url),
        thumbnailUrl: image,
        description: description,
        type: type,
        sourceUrl: url,
      );
    } catch (_) {
      // Fallback: just use URL as title
      return UrlMetadata(
        title: _titleFromUrl(url),
        author: _authorFromUrl(url),
        type: type,
        sourceUrl: url,
      );
    }
  }

  ReadingType _detectType(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return ReadingType.course; // video
    }
    if (lower.contains('spotify.com')) return ReadingType.podcast;
    if (lower.contains('udemy.com') ||
        lower.contains('coursera.org') ||
        lower.contains('edx.org') ||
        lower.contains('skillshare.com') ||
        lower.contains('linkedin.com/learning')) {
      return ReadingType.course;
    }
    if (lower.contains('podcast') ||
        lower.contains('anchor.fm') ||
        lower.contains('buzzsprout') ||
        lower.contains('podbean')) {
      return ReadingType.podcast;
    }
    return ReadingType.article;
  }

  String? _ogTag(String html, String property) {
    final pattern = RegExp(
      'property=["\']$property["\']\\s+content=["\']([^"\']+)["\']|'
      'content=["\']([^"\']+)["\']\\s+property=["\']$property["\']',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    final value = match?.group(1) ?? match?.group(2);
    return value?.trim().isEmpty == true ? null : value?.trim();
  }

  String? _metaTag(String html, String name) {
    final pattern = RegExp(
      'name=["\']$name["\']\\s+content=["\']([^"\']+)["\']|'
      'content=["\']([^"\']+)["\']\\s+name=["\']$name["\']',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    final value = match?.group(1) ?? match?.group(2);
    return value?.trim().isEmpty == true ? null : value?.trim();
  }

  String? _titleTag(String html) {
    final match = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
        .firstMatch(html);
    return match?.group(1)?.trim();
  }

  String _cleanTitle(String title, String? siteName) {
    if (siteName != null && title.endsWith(' - $siteName')) {
      return title.substring(0, title.length - siteName.length - 3).trim();
    }
    if (siteName != null && title.endsWith(' | $siteName')) {
      return title.substring(0, title.length - siteName.length - 3).trim();
    }
    return title;
  }

  String _titleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments =
          uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        return segments.last
            .replaceAll('-', ' ')
            .replaceAll('_', ' ')
            .split('.')
            .first;
      }
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  String? _authorFromUrl(String url) {
    try {
      final host = Uri.parse(url).host;
      if (host.contains('youtube')) return 'YouTube';
      if (host.contains('spotify')) return 'Spotify';
      if (host.contains('udemy')) return 'Udemy';
      if (host.contains('coursera')) return 'Coursera';
      if (host.contains('edx')) return 'edX';
      if (host.contains('skillshare')) return 'Skillshare';
      return null;
    } catch (_) {
      return null;
    }
  }
}
