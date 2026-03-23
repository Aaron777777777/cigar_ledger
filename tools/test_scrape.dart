import 'package:http/http.dart' as http;

void main() async {

  final url = Uri.parse('https://www.cgarsltd.co.uk/cohiba-siglo-p-1528.html');

  final response = await http.get(
    url,
    headers: {
      "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36"
    },
  );

  final body = response.body.toLowerCase();

  print('Status: ${response.statusCode}');
  print('Contains "price": ${body.contains("price")}');
  print('Contains "£": ${response.body.contains("£")}');
}