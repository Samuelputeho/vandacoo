import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

abstract class PaymentRemoteDataSource {
  Future<String> initiateDpoPayment(String amount, String currency);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  static const String _apiEndpoint = 'https://secure.3gdirectpay.com/API/v6/';
  static const String _companyToken =
      '57466282-EBD7-4ED5-B699-8659330A6996'; // Replace with your company token
  static const String _serviceType = '45'; // Example service type

  @override
  Future<String> initiateDpoPayment(String amount, String currency) async {
    try {
      // Create the XML request body
      final xmlRequest = '''<?xml version="1.0" encoding="utf-8"?>
<API3G>
  <CompanyToken>$_companyToken</CompanyToken>
  <Request>createToken</Request>
  <Transaction>
    <PaymentAmount>$amount</PaymentAmount>
    <PaymentCurrency>$currency</PaymentCurrency>
    <CompanyRef>Order_${DateTime.now().millisecondsSinceEpoch}</CompanyRef>
    <RedirectURL>https://your-app.com/payment-success</RedirectURL>
    <BackURL>https://your-app.com/payment-failed</BackURL>
    <CompanyRefUnique>0</CompanyRefUnique>
    <PTL>5</PTL>
  </Transaction>
  <Services>
    <Service>
      <ServiceType>$_serviceType</ServiceType>
      <ServiceDescription>Sample Service Description</ServiceDescription>
      <ServiceDate>${DateTime.now().toIso8601String()}</ServiceDate>
    </Service>
  </Services>
</API3G>''';

      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/xml', // Send XML data
        },
        body: xmlRequest,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to initiate DPO payment: ${response.body}');
      }

      // Print the full XML response for debugging
      print("📄 XML Response: ${response.body}");

      // Parse the XML response
      final xmlDoc = XmlDocument.parse(response.body);

      // Extract necessary elements
      final resultCode = xmlDoc.findAllElements('Result').first.innerText;
      final resultExplanation =
          xmlDoc.findAllElements('ResultExplanation').first.innerText;

      if (resultCode != '000') {
        throw Exception('DPO Error: $resultExplanation (Code: $resultCode)');
      }

      final transToken = xmlDoc.findAllElements('TransToken').first.innerText;
      return transToken; // Return transaction token
    } catch (err) {
      throw Exception('DPO Payment Error: $err');
    }
  }
}
