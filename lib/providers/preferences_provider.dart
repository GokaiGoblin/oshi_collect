import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';

import 'dart:convert';

class PreferencesProvider extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _cardViewColumnsKey = 'card_view_columns';
  static const _currencyCodeKey = 'currency_code';
  static const _fxRatesUpdatedAtKey = 'fx_rates_updated_at';

  int _cardViewColumns = 2;
  ThemeMode _themeMode = ThemeMode.light;
  String _currencyCode = 'USD';
  int? _fxRatesUpdatedAt;

  final Map<String, double> _fxRates = {
    'USD': 1.0,
    'GBP': 1.0,
    'EUR': 1.0,
    'JPY': 1.0,
    'AUD': 1.0,
    'CAD': 1.0,
  };

  int get cardViewColumns => _cardViewColumns;
  GridSize get gridSize => _cardViewColumns == 3 ? GridSize.three : GridSize.two;
  ThemeMode get themeMode => _themeMode;
  String get currencyCode => _currencyCode;
  int? get fxRatesUpdatedAt => _fxRatesUpdatedAt;
  Map<String, double> get fxRates => Map.unmodifiable(_fxRates);

  PreferencesProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTheme = prefs.getString(_themeModeKey);
    if (savedTheme == ThemeMode.dark.name) {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == ThemeMode.light.name) {
      _themeMode = ThemeMode.light;
    }

    final savedColumns = prefs.getInt(_cardViewColumnsKey);
    if (savedColumns == 2 || savedColumns == 3) {
      _cardViewColumns = savedColumns!;
    }

    final savedCurrency = prefs.getString(_currencyCodeKey);
    if (savedCurrency != null) _currencyCode = savedCurrency;

    _fxRatesUpdatedAt = prefs.getInt(_fxRatesUpdatedAtKey);

    for (final code in ['GBP', 'EUR', 'JPY', 'AUD', 'CAD']) {
      final rate = prefs.getDouble('fx_rate_$code');
      if (rate != null) _fxRates[code] = rate;
    }

    notifyListeners();
    _fetchFxRatesIfNeeded();
  }

  Future<void> _fetchFxRatesIfNeeded() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_fxRatesUpdatedAt != null && now - _fxRatesUpdatedAt! < 86400000) return;
    try {
      final uri = Uri.parse(
          'https://api.frankfurter.app/latest?from=USD&to=GBP,EUR,JPY,AUD,CAD');
      final response = await http.get(uri);
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>;
      for (final entry in rates.entries) {
        final rate = (entry.value as num).toDouble();
        _fxRates[entry.key] = rate;
      }
      _fxRates['USD'] = 1.0;
      _fxRatesUpdatedAt = now;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_fxRatesUpdatedAtKey, now);
      for (final entry in rates.entries) {
        await prefs.setDouble('fx_rate_${entry.key}', (entry.value as num).toDouble());
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _themeMode = ThemeMode.light;
    _cardViewColumns = 2;
    _currencyCode = 'USD';
    _fxRatesUpdatedAt = null;
    _fxRates.updateAll((k, v) => 1.0);
    notifyListeners();
  }

  Future<void> toggleCardViewColumns() async {
    _cardViewColumns = _cardViewColumns == 3 ? 2 : 3;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cardViewColumnsKey, _cardViewColumns);
  }

  // Kept for backward compatibility — grid pages using GridSize will still work.
  void setGridSize(GridSize size) {
    final cols = size == GridSize.three ? 3 : 2;
    if (_cardViewColumns == cols) return;
    _cardViewColumns = cols;
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    if (_currencyCode == code) return;
    _currencyCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyCodeKey, code);
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeMode.name);
  }
}
