import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PostService {
  static String openAiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  static Future<String?> generatePostContent(String title,
      {String? userContext}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? generalKnowledge = prefs.getString('knowledge');

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $openAiApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content':
                "${generalKnowledge ?? "Generate a LinkedIn post based on this title."} User Context: ${userContext ?? Null}"
          },
          {'role': 'user', 'content': 'Title: $title'},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      print('Error generating content: ${response.body}');
      return null;
    }
  }
}

class LinkedInAPI {
  // Upload Image to LinkedIn and Get Image URN
  static Future<String?> uploadImage(
      String accessToken, File imageFile, String urn) async {
    final registerResponse = await http.post(
      Uri.parse('https://api.linkedin.com/v2/assets?action=registerUpload'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'X-Restli-Protocol-Version': '2.0.0',
      },
      body: jsonEncode({
        "registerUploadRequest": {
          "recipes": ["urn:li:digitalmediaRecipe:feedshare-image"],
          "owner": "urn:li:person:$urn",
          "serviceRelationships": [
            {
              "relationshipType": "OWNER",
              "identifier": "urn:li:userGeneratedContent"
            }
          ]
        }
      }),
    );

    if (registerResponse.statusCode != 200) {
      print("Image registration failed: ${registerResponse.body}");
      return null;
    }

    final uploadData = jsonDecode(registerResponse.body);
    String uploadUrl = uploadData['value']['uploadMechanism']
            ['com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest']
        ['uploadUrl'];
    String imageUrn = uploadData['value']['asset'];

    // Upload image to LinkedIn's server
    final imageUploadResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'image/jpeg', // Adjust based on file type
      },
      body: imageFile.readAsBytesSync(),
    );

    if (imageUploadResponse.statusCode == 201) {
      return imageUrn;
    } else {
      print("Image upload failed: ${imageUploadResponse.body}");
      return null;
    }
  }

  // Post Content to LinkedIn with Optional Image
  static Future<bool> postToLinkedIn(
      String urn, String accessToken, String content, File? imageFile) async {
    String? imageUrn;

    if (imageFile != null) {
      imageUrn = await uploadImage(accessToken, imageFile, urn);
      if (imageUrn == null) {
        print("Failed to upload image.");
        return false;
      }
    }

    final response = await http.post(
      Uri.parse('https://api.linkedin.com/v2/ugcPosts'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'X-Restli-Protocol-Version': '2.0.0',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "author": "urn:li:person:$urn",
        "lifecycleState": "PUBLISHED",
        "specificContent": {
          "com.linkedin.ugc.ShareContent": {
            "shareCommentary": {"text": content},
            "shareMediaCategory": imageUrn != null ? "IMAGE" : "NONE",
            if (imageUrn != null)
              "media": [
                {
                  "status": "READY",
                  "description": {"text": "Image post"},
                  "media": imageUrn,
                  "title": {"text": "Uploaded Image"}
                }
              ]
          }
        },
        "visibility": {"com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"},
      }),
    );

    return response.statusCode == 201;
  }
}
