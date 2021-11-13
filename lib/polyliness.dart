import 'package:http/http.dart' as http;
import 'dart:convert';

class NetworkHelper {
  NetworkHelper({this.startLng, this.startLat, this.endLng, this.endLat});

  final String url = 'https://api.openrouteservice.org/v2/directions/';
  final String apiKey = '';
  final String pathParam = 'driving-car'; // Change it if you want
  final double startLng;
  final double startLat;
  final double endLng;
  final double endLat;

  Future getData() async {
    var uri = Uri.parse(
        '$url$pathParam?api_key=$apiKey&start=$startLng,$startLat&end=$endLng,$endLat');

    http.Response response = await http.get(uri);

    if (response.statusCode == 200) {
      String data = response.body;
      return jsonDecode(data);
    } else {
      print(response.statusCode);
    }
  }
}
