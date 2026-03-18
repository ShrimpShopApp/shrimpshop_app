import 'package:flutter/foundation.dart';

class CustomerAccessModel extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isGastro = false;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isGastro => _isGastro;
  bool get isLoading => _isLoading;

  void setLoggedOut() {
    _isLoggedIn = false;
    _isGastro = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCustomerAccess({
    required Future<bool> Function() gastroCheck,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = true;
      _isGastro = await gastroCheck();
    } catch (e) {
      debugPrint('Gastro check error: $e');
      _isLoggedIn = true;
      _isGastro = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setLoggedInWithoutGastro() {
    _isLoggedIn = true;
    _isGastro = false;
    _isLoading = false;
    notifyListeners();
  }
}