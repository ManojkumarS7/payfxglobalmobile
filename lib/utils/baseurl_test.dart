import 'package:http/http.dart' as http;
import 'api_constants2.dart';

Future<void> main() async {
  final url = ApiConstants.baseUrl;
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print('Base URL is working: $url');
    } else {
      print('Base URL responded with status: ${response.statusCode}');
    }
  } catch (e) {
    print('Base URL is not reachable: $e');
  }
}
