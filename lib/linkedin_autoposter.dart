import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'post_service.dart'; // Ensure this contains PostService and LinkedInAPI classes.

class LinkedInAutoPoster extends StatefulWidget {
  final urn;
  final accessToken;
  final context;

  const LinkedInAutoPoster(
    this.urn,
    this.accessToken,
    this.context, {
    Key? key, // Accept Key as a parameter
  }) : super(key: key); 

  @override
  _LinkedInAutoPosterState createState() => _LinkedInAutoPosterState();
}

class _LinkedInAutoPosterState extends State<LinkedInAutoPoster> {
  File? _selectedImage;
  TextEditingController _titleController = TextEditingController();
  TextEditingController _generatedContent = TextEditingController();
  bool _isLoading = false;
  bool _isPosting = false;

  Future<void> _generateContent() async {
    if (_titleController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? content = await PostService.generatePostContent(
          _titleController.text,
          userContext: widget.context);

      setState(() {
        _generatedContent.text = content ?? "Failed to generate content.";
      });
    } catch (e) {
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _postToLinkedIn() async {
    if (_generatedContent.text.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      bool success = await LinkedInAPI.postToLinkedIn(widget.urn,
          widget.accessToken, _generatedContent.text, _selectedImage);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Posted successfully!" : "Failed to post."),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "LinkedIn Auto Poster",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Enter Title",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.title, color: Colors.blueAccent),
                ),
              ),
              SizedBox(height: 15),
              if (_selectedImage == null) ...[
                _ImageDropBox(onImageSelected: (File file) {
                  setState(() {
                    _selectedImage = file;
                  });
                }),
              ],
              if (_selectedImage != null) ...[
                SizedBox(height: 10),
                Stack(
                  children: [
                    Image.file(
                      _selectedImage!,
                      height: 150,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 25),
              ElevatedButton(
                onPressed: _generateContent,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Generate Content",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (_generatedContent.text != "") ...[
                Divider(),
                Text("Generated Post:",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Expanded(
                  child: TextField(
                    controller: _generatedContent,
                    maxLines: null,
                  ),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _postToLinkedIn,
                  child: _isPosting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Post to LinkedIn",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageDropBox extends StatefulWidget {
  final Function(File) onImageSelected;
  const _ImageDropBox({required this.onImageSelected});

  @override
  _ImageDropBoxState createState() => _ImageDropBoxState();
}

class _ImageDropBoxState extends State<_ImageDropBox> {
  bool isDragging = false;

  Future<void> _pickImage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      File file = File(result.files.single.path!);
      widget.onImageSelected(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<File>(
      onAccept: (file) {
        widget.onImageSelected(file);
        setState(() {
          isDragging = false;
        });
      },
      onWillAccept: (_) {
        setState(() {
          isDragging = true;
        });
        return true;
      },
      onLeave: (_) {
        setState(() {
          isDragging = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: isDragging ? Colors.blue[100] : Colors.grey[200],
              border: Border.all(color: Colors.grey[400]!, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, size: 40, color: Colors.blueAccent),
                SizedBox(height: 5),
                Text("Drag & Drop or Click to Upload",
                    style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        );
      },
    );
  }
}
