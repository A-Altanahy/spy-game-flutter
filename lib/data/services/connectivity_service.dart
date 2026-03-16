import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:spyfall/core/constants/app_constants.dart';

/// Service for checking internet connectivity
class ConnectivityService {
  /// Test URLs for connectivity check
  static const List<String> _testUrls = [
    'https://www.google.com',
    'https://www.apple.com',
    'https://www.microsoft.com',
    'https://www.amazon.com',
    'https://www.cloudflare.com'
  ];

  /// Check if internet connection is available
  /// Tests multiple URLs to ensure robust detection
  Future<bool> checkInternetConnectivity() async {
    // print('Checking internet connectivity...');

    for (String url in _testUrls) {
      if (await _testUrl(url)) {
        // print('Successfully connected to $url');
        return true;
      }
    }

    // print('All connectivity tests failed. No internet connection.');
    return false;
  }

  /// Test a single URL for connectivity
  Future<bool> _testUrl(String url) async {
    try {
      // print('Trying to connect to $url');
      final client = http.Client();

      try {
        final response = await client.get(Uri.parse(url)).timeout(
          Duration(seconds: AppConstants.shortTimeout),
          onTimeout: () {
            // print('Connection to $url timed out');
            throw TimeoutException('Connection timed out');
          },
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // print('Successfully connected to $url with status code: ${response.statusCode}');
          return true;
        } else {
          // print('Connected to $url but received error status code: ${response.statusCode}');
          return false;
        }
      } catch (e) {
        // print('Error connecting to $url: $e');
        return false;
      } finally {
        client.close();
      }
    } catch (e) {
      // print('Exception when testing $url: $e');
      return false;
    }
  }

  /// Quick connectivity check (tests only one URL)
  Future<bool> quickConnectivityCheck() async {
    return await _testUrl(_testUrls.first);
  }
}
