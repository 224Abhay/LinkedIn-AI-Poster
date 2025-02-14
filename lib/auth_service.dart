import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static final String clientId = dotenv.env['CLIENT_ID'] ?? '';
  static final String clientSecret = dotenv.env['CLIENT_SECRET'] ?? '';
  static final String redirectUri = dotenv.env['REDIRECT_URI'] ?? '';
  static final String scope = dotenv.env['SCOPE'] ?? '';
  
  static Future<void> loginWithLinkedIn(Function(String) onAuthComplete) async {
    final authUrl =
        Uri.parse('https://www.linkedin.com/oauth/v2/authorization?response_type=code'
        '&client_id=$clientId'
        '&redirect_uri=$redirectUri'
        '&scope=$scope');

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl);
    } else {
      throw 'Could not launch LinkedIn login URL';
    }

    startAuthListener(onAuthComplete);
  }

  static void startAuthListener(Function(String) onAuthComplete) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8000);
    print("Listening on http://localhost:8000/");

    await for (HttpRequest request in server) {
      final uri = request.uri;
      if (uri.queryParameters.containsKey('code')) {
        String authCode = uri.queryParameters['code']!;
        onAuthComplete(authCode);
        request.response.write('Authentication successful! You can close this tab.');
        await request.response.close();
        server.close();
      }
    }
  }

  static Future<void> fetchAccessToken(String authCode) async {
    final response = await http.post(
      Uri.parse('https://www.linkedin.com/oauth/v2/accessToken'),
      body: {
        'grant_type': 'authorization_code',
        'code': authCode,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String accessToken = data['access_token'];
      await fetchUserURN(accessToken);
    } else {
      print('Error fetching access token: ${response.body}');
    }
  }

  static Future<void> fetchUserURN(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.linkedin.com/v2/userinfo'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'X-Restli-Protocol-Version': '2.0.0',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String urn = data['sub'];
      String name = data['name'];
      await StorageService.saveAccount(urn, name, accessToken);
    } else {
      print('Error fetching user URN: ${response.body}');
    }
  }
}
