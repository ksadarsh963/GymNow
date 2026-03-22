import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatefulWidget {
  final String gymOwnerId;
  final String userId;
  final double amount;
  final String planId;
  final int durationInDays;
  

  const PaymentScreen({
    super.key,
    required this.gymOwnerId,
    required this.userId,
    required this.amount,
    required this.planId,
    required this.durationInDays,
  });

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    initiateTransaction();
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clear all event listeners
    super.dispose();
  }

  void initiateTransaction() {
    var options = {
      'key': 'rzp_live_GHGknltonoeZQD', // Replace with your Razorpay API key
      'amount': (widget.amount * 100).toInt(), // Amount in paise
      'name': 'GymNow',
      'description': 'Subscription for Plan ${widget.planId}',
      'prefill': {
        'contact': '9876543210', // Replace with user's contact number
        'email': 'test@example.com', // Replace with user's email
      },
      'theme': {
        'color': '#3399cc',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint("Payment Successful: ${response.paymentId}");
    await saveSubscriptionDetails();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful!')),
    );
    Navigator.pop(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("Payment Failed: ${response.code} | ${response.message}");
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External Wallet Selected: ${response.walletName}");
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  Future<void> saveSubscriptionDetails() async {
    DateTime purchaseDate = DateTime.now();
    DateTime expiryDate = purchaseDate.add(Duration(days: widget.durationInDays));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.gymOwnerId)
        .update({
      'subscriptions': FieldValue.arrayUnion([
        {
          'userId': widget.userId,
          'planId': widget.planId,
          'purchaseDate': purchaseDate,
          'expiryDate': expiryDate,
          'status': 'Active',
          'cancellationOption': true,
        }
      ])
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'subscriptions': FieldValue.arrayUnion([
        {
          'gymOwnerId': widget.gymOwnerId,
          'purchaseDate': purchaseDate,
          'expiryDate': expiryDate,
          'status': 'Active',
          'cancellationOption': true,
        }
      ])
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Processing'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

