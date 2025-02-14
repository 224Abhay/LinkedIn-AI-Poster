import 'package:flutter/material.dart';
import 'storage_service.dart';

class AccountManager extends StatefulWidget {
  final VoidCallback refreshCallback; // Add this
  AccountManager({required this.refreshCallback});

  @override
  _AccountManagerState createState() => _AccountManagerState();
}

class _AccountManagerState extends State<AccountManager> {
  Map<String, dynamic> accounts = {};
  String? currentAccount;

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    accounts = await StorageService.getAccounts();
    currentAccount = await StorageService.getCurrentAccount();
    setState(() {});
  }

  Future<void> removeAccount(String urn) async {
    await StorageService.removeAccount(urn);
    await loadAccounts();
    widget.refreshCallback(); // Notify Sidebar to update UI
  }

  Future<void> editAccountContext(String urn) async {
    TextEditingController contextController =
        TextEditingController(text: accounts[urn]['context'] ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Account"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Name: ${accounts[urn]['name']}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Container(
                width: 900, // Fixed width of 800 pixels
                constraints: BoxConstraints(
                    maxHeight: 300), // Limits the maximum height to 200
                child: TextField(
                  controller: contextController,
                  decoration: InputDecoration(
                    labelText: "Context",
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  ),
                  maxLines:
                      null, // Allows the text field to expand vertically as needed
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Update the context in storage
                await StorageService.updateAccountContext(
                    urn, contextController.text);
                await loadAccounts(); // Reload accounts after saving
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Accounts')),
      body: ListView(
        children: accounts.entries.map((entry) {
          String urn = entry.key;
          String name = entry.value['name'];

          return ListTile(
            title: Text(name),
            subtitle: Text(urn),
            onTap: () => editAccountContext(urn), // Show popup on tap
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => removeAccount(urn),
            ),
          );
        }).toList(),
      ),
    );
  }
}
