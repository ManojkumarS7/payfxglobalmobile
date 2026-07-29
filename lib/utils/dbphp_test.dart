import 'package:http/http.dart' as http;
import 'api_constants2.dart';

Future<void> main() async {
  final url = '${ApiConstants.baseUrl}/db.php';
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print('db.php endpoint is working: $url');
      print('Response: ${response.body}');
    } else {
      print('db.php responded with status: ${response.statusCode}');
    }
  } catch (e) {
    print('db.php endpoint is not reachable: $e');
  }
}
