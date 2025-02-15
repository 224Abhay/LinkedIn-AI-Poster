import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_manager.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class Sidebar extends StatefulWidget {
  final Map<String, dynamic> accounts;
  final Function(String) switchAccount;
  final VoidCallback refreshHomeScreen;

  const Sidebar({
    required this.accounts,
    required this.switchAccount,
    required this.refreshHomeScreen,
  });

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool showDropdown = false;
  Map<String, dynamic> accounts = {};
  String? currentAccount;

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    var updatedAccounts = await StorageService.getAccounts();
    var updatedCurrent = await StorageService.getCurrentAccount();
    setState(() {
      accounts = updatedAccounts;
      currentAccount = updatedCurrent;
    });
  }

  void login() {
    AuthService.loginWithLinkedIn((authCode) {
      AuthService.fetchAccessToken(authCode).then((_) => loadAccounts());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          if (accounts.isNotEmpty) ...[
            GestureDetector(
              onTap: () => setState(() => showDropdown = !showDropdown),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                margin: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        accounts[currentAccount]?['name'] ?? "Select Account",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(showDropdown
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            if (showDropdown)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: accounts.entries.map((entry) {
                    String urn = entry.key;
                    String name = entry.value['name'];
                    return ListTile(
                      title: Text(name, style: TextStyle(fontSize: 14)),
                      onTap: () {
                        widget.switchAccount(urn);
                        setState(() {
                          showDropdown = false;
                          currentAccount = urn;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
          Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KnowledgeScreen()),
                ),
                icon: Icon(
                  Icons.abc,
                  color: Colors.white,
                ),
                label: Text(
                  "Knowledege",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 164, 146, 81),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: login,
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                label: Text(
                  "Add Account",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountManager(
                      refreshCallback: () {
                        loadAccounts(); // Refresh Sidebar accounts
                        widget.refreshHomeScreen(); // Also refresh HomeScreen
                      },
                    ),
                  ),
                ),
                icon: Icon(Icons.settings, color: Colors.white),
                label: Text("Manage Accounts",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KnowledgeScreen extends StatefulWidget {
  @override
  _KnowledgeScreenState createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  TextEditingController knowledgeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadKnowledge();
  }

  Future<void> loadKnowledge() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedKnowledge =
        prefs.getString('knowledge'); // Retrieve saved knowledge
    if (savedKnowledge != null) {
      setState(() {
        knowledgeController.text = savedKnowledge; // Set the text field value
      });
    }
  }

  Future<void> saveKnowledge() async {
    String knowledgeText = knowledgeController.text;
    if (knowledgeText.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('knowledge', knowledgeText);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Knowledge saved successfully')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter some knowledge')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Knowledge')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Expanded(
            child: TextField(
              controller: knowledgeController,
              maxLines: null, // Allow multiple lines
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: saveKnowledge,
            child: Text('Save Knowledge'),
          )
        ]),
      ),
    );
  }
}
