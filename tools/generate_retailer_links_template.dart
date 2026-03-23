import 'dart:convert';
import 'dart:io';

const pricesFilePath = 'assets/data/prices.json';
const retailerLinksFilePath = 'assets/data/retailer_links.json';

Future<void> main() async {
  final pricesFile = File(pricesFilePath);

  if (!await pricesFile.exists()) {
    print('prices.json not found');
    exit(1);
  }

  final List<dynamic> cigars =
      jsonDecode(await pricesFile.readAsString()) as List<dynamic>;

  final Map<String, dynamic> output = {};

  for (final item in cigars) {
    if (item is! Map<String, dynamic>) continue;

    final name = (item['name'] ?? '').toString().trim();
    if (name.isEmpty) continue;

    output[name] = {
      'cgars': '',
      'smokeking': '',
      'havanahouse': '',
      'simplycigars': '',
      'jjfox': '',
      'montefortuna': '',
      'topcubans': '',
      'cigarsofcuba': '',
    };
  }

  const encoder = JsonEncoder.withIndent('  ');
  final outFile = File(retailerLinksFilePath);
  await outFile.writeAsString(encoder.convert(output));

  print('Generated $retailerLinksFilePath with ${output.length} cigars.');
}
