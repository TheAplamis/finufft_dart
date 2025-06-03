class FinufftException implements Exception {
  final String message;
  final int? errorCode;

  FinufftException(this.message, {this.errorCode});

  @override
  String toString() {
    if (errorCode != null) {
      return 'FinufftException: \$message (Error Code: \$errorCode)';
    }
    return 'FinufftException: \$message';
  }
}
