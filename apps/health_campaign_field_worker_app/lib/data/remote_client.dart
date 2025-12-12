// Importing necessary packages and files
import 'dart:io';

import 'package:dio/dio.dart'; // Dio package for HTTP requests
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/environment_config.dart'; // Custom utility file for environment configurations
import 'repositories/api_interceptors.dart'; // Custom API interceptors for Dio

// The DioClient class for managing the Dio instance
class DioClient {
  late Dio _dio; // Private instance of Dio
  bool _sslPinningEnabled = false; // Track if SSL pinning is configured

  // Singleton instance of DioClient
  static final DioClient _instance = DioClient._internal();

  // Factory constructor for DioClient
  factory DioClient() {
    return _instance;
  }

  // Private constructor of DioClient
  DioClient._internal() {
    _init(); // Initialize the Dio client during construction
  }

  // Getter method to access the Dio instance
  Dio get dio => _dio;

  // Initialization method for the Dio client
  void _init() {
    _dio = Dio()
      ..interceptors.addAll([
        // SSL Pinning check interceptor - must be first
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (!_sslPinningEnabled) {
              debugPrint('SSL Pinning: Request blocked - SSL pinning not enabled');
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'SSL Pinning not enabled. Call enableSSLPinning() first.',
                  type: DioExceptionType.cancel,
                ),
              );
            }
            return handler.next(options);
          },
        ),
        AuthTokenInterceptor(),
        ApiLoggerInterceptor(),
      ])
      ..options = BaseOptions(
        connectTimeout: Duration(
          milliseconds: envConfig.variables.connectTimeout,
        ),
        sendTimeout: Duration(
          milliseconds: envConfig.variables.sendTimeout,
        ),
        receiveTimeout: Duration(
          milliseconds: envConfig.variables.receiveTimeout,
        ),
        baseUrl: envConfig.variables.baseUrl,
      );
  }

  // Enable SSL certificate pinning
  Future<void> enableSSLPinning() async {
    if (_sslPinningEnabled) return; // Already enabled

    // Load the certificate from assets
    final certData = await rootBundle.load('assets/certificates/tls_cert.crt');
    final certBytes = certData.buffer.asUint8List();

    // Configure Dio to use custom HttpClient with SSL pinning
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      // Create SecurityContext with pinned certificate inside callback
      final securityContext = SecurityContext(withTrustedRoots: false);
      securityContext.setTrustedCertificatesBytes(certBytes);

      // Create HttpClient with the custom SecurityContext
      final httpClient = HttpClient(context: securityContext);
      httpClient.badCertificateCallback = (cert, host, port) {
        debugPrint('SSL Pinning: Bad certificate rejected for $host');
        throw DioException(
          requestOptions: RequestOptions(path: host),
          error: 'SSL Certificate validation failed for $host',
          type: DioExceptionType.badCertificate,
        );
      };

      return httpClient;
    };

    _sslPinningEnabled = true;
    debugPrint('SSL Certificate Pinning enabled');
  }

  // Disable SSL certificate pinning (use default system certificates)
  void disableSSLPinning() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      return HttpClient();
    };
    _sslPinningEnabled = false;
    debugPrint('SSL Certificate Pinning disabled');
  }
}
