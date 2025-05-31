import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

class SmsListenerWidget extends StatefulWidget {
  @override
  _SmsListenerWidgetState createState() => _SmsListenerWidgetState();
}

class _SmsListenerWidgetState extends State<SmsListenerWidget> {
  final Telephony telephony = Telephony.instance;
  List<String> transactions = [];

  @override
  void initState() {
    super.initState();

    // Request permissions
    telephony.requestSmsPermissions.then((isGranted) {
      if (isGranted ?? false) {
        // Permission granted, start listening
        telephony.listenIncomingSms(
          onNewMessage: (SmsMessage message) {
            setState(() {
              transactions.add("SMS: ${message.body}");
            });
          },
          onBackgroundMessage:
              backgroundMessageHandler, // optional, but correctly declared below
        );
      } else {
        print("SMS permission denied");
      }
    });
  }

  // Must be a top-level or static async function
  static Future<void> backgroundMessageHandler(SmsMessage message) async {
    // Handle background SMS here, for example log or update DB
    print("Background SMS received: ${message.body}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SMS Transactions")),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(transactions[index]),
        ),
      ),
    );
  }
}
