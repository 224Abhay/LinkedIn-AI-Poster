import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
 static Future<void> saveAccount(
     String urn, String name, String accessToken) async {
   final prefs = await SharedPreferences.getInstance();
   Map<String, dynamic> accounts = {};

   final storedAccounts = prefs.getString('linkedin_accounts');
   if (storedAccounts != null) {
     accounts = jsonDecode(storedAccounts);
   }

   accounts[urn] = {
     'name': name,
     'access_token': accessToken,
     'context': '' // Adding context field and initializing it as an empty string
   };

   await prefs.setString('linkedin_accounts', jsonEncode(accounts));
 }

 static Future<void> updateAccountContext(
     String urn, String newContext) async {
   SharedPreferences prefs = await SharedPreferences.getInstance();
   Map<String, dynamic> accounts = await getAccounts();
   if (accounts.containsKey(urn)) {
     accounts[urn]['context'] = newContext;
     await prefs.setString('linkedin_accounts', jsonEncode(accounts));
   }
 }

 static Future<Map<String, dynamic>> getAccounts() async {
   final prefs = await SharedPreferences.getInstance();
   final storedAccounts = prefs.getString('linkedin_accounts');
   if (storedAccounts != null) {
     return jsonDecode(storedAccounts);
   }
   return {};
 }

 static Future<void> saveAccounts(Map<String, dynamic> accounts) async {
   final prefs = await SharedPreferences.getInstance();
   await prefs.setString('linkedin_accounts', jsonEncode(accounts));
 }

 static Future<void> switchAccount(String urn) async {
   final prefs = await SharedPreferences.getInstance();
   await prefs.setString('current_account', urn);
 }

 static Future<String?> getCurrentAccount() async {
   final prefs = await SharedPreferences.getInstance();
   return prefs.getString('current_account');
 }

 static Future<void> removeAccount(String urn) async {
   final prefs = await SharedPreferences.getInstance();
   Map<String, dynamic> accounts = await getAccounts();
   accounts.remove(urn);
   await prefs.setString('linkedin_accounts', jsonEncode(accounts));
 }

 static Future<void> deleteAccount(String urn) async {
   final accounts = await getAccounts();
   accounts.remove(urn);
   await saveAccounts(accounts);
 }
}
