import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(Widget screen) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw StateError('Navigator not initialized');
    }
    return navigator.push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<dynamic> navigateToReplacement(Widget screen) {
    return navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void goBack() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw StateError('Navigator not initialized');
    }
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
