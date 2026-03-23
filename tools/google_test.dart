import 'package:http/http.dart' as http;

void main() async {

  final url = Uri.parse(
      "https://www.google.com/search?q=Plasencia+Alma+Fuerte+Generacion+V+cigar+price");

  final response = await http.get(
    url,
    headers: {
      "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36"
    },
  );

  print("Status: ${response.statusCode}");
  print(response.body.substring(0, 800));
}