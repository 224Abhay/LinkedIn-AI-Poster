import 'package:flutter/material.dart';
import 'package:linkedin_uploader/linkedin_autoposter.dart';
import 'storage_service.dart';
import 'sidebar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> accounts = {};
  String? currentAccount;
  bool _isLoading = true;
  bool _islogin = true;

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    setState(() => _isLoading = true);

    accounts = await StorageService.getAccounts();

    // Ensure _islogin is true if accounts is null or empty
    _islogin = accounts.isEmpty;

    currentAccount = await StorageService.getCurrentAccount();

    setState(() => _isLoading = false);
  }

  Future<void> switchAccount(String urn) async {
    await StorageService.switchAccount(urn);
    await loadAccounts();
    setState(() {
      currentAccount = urn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Widget
          Sidebar(
            accounts: accounts,
            switchAccount: switchAccount,
            refreshHomeScreen: loadAccounts, // This will refresh HomeScreen
          ),

          // Main Content Area
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _islogin
                    ? Center(child: Text("Please Log in First"))
                    : LinkedInAutoPoster(
                        key: ValueKey(currentAccount),
                        currentAccount ?? "",
                        accounts[currentAccount]?['access_token'] ?? "",
                        accounts[currentAccount]?['context'] ?? "",
                      ),
          ),
        ],
      ),
    );
  }
}
