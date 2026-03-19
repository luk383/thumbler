import 'dart:convert';
import 'package:http/http.dart' as http;

class BookInfo {
  const BookInfo({
    required this.title,
    this.author,
    this.pages,
    this.thumbnailUrl,
    this.description,
  });

  final String title;
  final String? author;
  final int? pages;
  final String? thumbnailUrl;
  final String? description;
}

class BookLookupService {
  static const _base = 'https://www.googleapis.com/books/v1/volumes';

  /// Lookup by ISBN (barcode scan result).
  Future<BookInfo?> lookupIsbn(String isbn) async {
    try {
      final uri = Uri.parse('$_base?q=isbn:$isbn&maxResults=1');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = body['items'] as List?;
      if (items == null || items.isEmpty) return null;
      return _parse(items.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Search by title/author string.
  Future<List<BookInfo>> search(String query) async {
    try {
      final uri = Uri.parse(
          '$_base?q=${Uri.encodeComponent(query)}&maxResults=5&langRestrict=it');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = body['items'] as List? ?? [];
      return items
          .map((e) => _parse(e as Map<String, dynamic>))
          .whereType<BookInfo>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  BookInfo? _parse(Map<String, dynamic> item) {
    final info = item['volumeInfo'] as Map<String, dynamic>?;
    if (info == null) return null;
    final title = info['title'] as String? ?? '';
    if (title.isEmpty) return null;

    final authors = (info['authors'] as List?)?.cast<String>();
    final author = authors?.join(', ');
    final pages = (info['pageCount'] as num?)?.toInt();
    final description = info['description'] as String?;

    // Prefer https thumbnail
    final imageLinks = info['imageLinks'] as Map<String, dynamic>?;
    var thumb = (imageLinks?['thumbnail'] as String?)
        ?.replaceFirst('http://', 'https://');

    return BookInfo(
      title: title,
      author: author,
      pages: pages,
      thumbnailUrl: thumb,
      description: description,
    );
  }
}
