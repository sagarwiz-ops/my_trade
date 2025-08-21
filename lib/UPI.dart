import 'package:flutter/material.dart';
import 'package:upi_pay/upi_pay.dart';

class UPI extends StatefulWidget {
  @override
  _UPIState createState() => _UPIState();
}

class _UPIState extends State<UPI> {
  List<ApplicationMeta> upiApps = [];

  @override
  void initState() {
    super.initState();
    loadUpiApps();
  }

  Future<void> loadUpiApps() async {
    final upiPay = UpiPay(); // Create an instance

    final apps = await upiPay.getInstalledUpiApplications(
      paymentType: UpiApplicationDiscoveryAppPaymentType.nonMerchant,
      statusType: UpiApplicationDiscoveryAppStatusType.workingWithWarnings,
    );

    if (apps.isEmpty) {
      print('⚠️ No UPI apps found');
    } else {
      for (final app in apps) {
        print('✅ Found app: ${app.upiApplication.getAppName()} - ${app.packageName}');
      }
    }

    setState(() {
      upiApps = apps;
    });
  }

  void initiateTransaction(ApplicationMeta app) async {
    final transactionRef = DateTime.now().millisecondsSinceEpoch.toString();
    final upiPay = UpiPay(); // ✅ create an instance

    final response = await upiPay.initiateTransaction(
      app: app.upiApplication,
      receiverUpiAddress: 'yourupi@upi', // Replace this with a real UPI ID
      receiverName: 'Your Name',
      transactionRef: transactionRef,
      transactionNote: 'Order Payment',
      amount: '1.00',
    );

    print('🔁 Transaction Status: ${response.status}');
    // print('📎 Approval Ref: ${response.approvalRef}');
    print('🧾 Raw Response: ${response.rawResponse}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select UPI App')),
      body: upiApps.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: upiApps.length,
        itemBuilder: (context, index) {
          final app = upiApps[index];
          return ListTile(
            title: Text(app.upiApplication.getAppName()),
            onTap: () => initiateTransaction(app),
          );
        },
      ),
    );
  }
}
