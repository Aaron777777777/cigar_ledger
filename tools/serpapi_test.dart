import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final envFile = File('.env');
  final envText = await envFile.readAsString();

  final apiKeyLine = envText
      .split('\n')
      .firstWhere((line) => line.startsWith('SERPAPI_KEY='));

  final apiKey = apiKeyLine.replaceFirst('SERPAPI_KEY=', '').trim();

  final query = Uri.encodeComponent('Plasencia Alma Fuerte Generacion V cigar');
  final url = Uri.parse(
    'https://serpapi.com/search.json?engine=google_shopping&q=$query&api_key=$apiKey',
  );

  final response = await http.get(url);

  print('Status: ${response.statusCode}');

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final results = (data['shopping_results'] as List?) ?? [];

  if (results.isEmpty) {
    print('No shopping results found.');
    return;
  }

  for (final item in results.take(10)) {
    final map = item as Map<String, dynamic>;

    print('---');
    print('Title: ${map['title'] ?? 'N/A'}');
    print('Price: ${map['price'] ?? 'N/A'}');
    print('Source: ${map['source'] ?? 'N/A'}');
    print('Product Link: ${map['product_link'] ?? 'N/A'}');
  }
}