import 'package:flutter/foundation.dart';

import '../models/invoice.dart';
import '../services/invoice_api_service.dart';

class InvoicesController extends ChangeNotifier {
  final InvoiceApiService _apiService;

  InvoicesController({required InvoiceApiService apiService})
      : _apiService = apiService;

  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _errorKey;
  String _searchQuery = '';

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  /// AppTexts key of the last error, to translate in the UI.
  String? get errorKey => _errorKey;
  String get searchQuery => _searchQuery;

  int get totalCount => _invoices.length;
  int get paidCount => _invoices.where((inv) => inv.status.toUpperCase() == 'PAID').length;
  int get pendingCount => _invoices.where((inv) => inv.status.toUpperCase() == 'PENDING').length;
  int get overdueCount => _invoices.where((inv) => inv.status.toUpperCase() == 'OVERDUE').length;

  double get totalAmount => _invoices.fold(0.0, (sum, inv) => sum + inv.amount);
  double get paidAmount => _invoices
      .where((inv) => inv.status.toUpperCase() == 'PAID')
      .fold(0.0, (sum, inv) => sum + inv.amount);

  List<Invoice> get filteredInvoices {
    if (_searchQuery.isEmpty) {
      return _invoices;
    }
    return _invoices.where((invoice) {
      final query = _searchQuery.toLowerCase();
      return invoice.invoiceNumber.toLowerCase().contains(query) ||
          invoice.clientName.toLowerCase().contains(query) ||
          invoice.status.toLowerCase().contains(query);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearError() {
    _errorKey = null;
    notifyListeners();
  }

  /// Charger toutes les factures
  Future<void> loadInvoices() async {
    _isLoading = true;
    _errorKey = null;
    notifyListeners();

    try {
      _invoices = await _apiService.getAllInvoices();
      // Trier par date décroissante
      _invoices.sort((a, b) => b.issueDate.compareTo(a.issueDate));
    } catch (e) {
      _errorKey = 'invoice.loadError';
      if (kDebugMode) {
        print('Erreur loadInvoices: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Créer une nouvelle facture
  Future<bool> createInvoice(Invoice invoice) async {
    _isLoading = true;
    _errorKey = null;
    notifyListeners();

    try {
      final created = await _apiService.createInvoice(invoice);
      _invoices.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorKey = 'invoice.saveError';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Erreur createInvoice: $e');
      }
      return false;
    }
  }

  /// Mettre à jour une facture
  Future<bool> updateInvoice(String id, Invoice invoice) async {
    _isLoading = true;
    _errorKey = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateInvoice(id, invoice);
      final index = _invoices.indexWhere((inv) => inv.id == id);
      if (index != -1) {
        _invoices[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorKey = 'invoice.saveError';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Erreur updateInvoice: $e');
      }
      return false;
    }
  }

  /// Supprimer une facture
  Future<bool> deleteInvoice(String id) async {
    _errorKey = null;

    try {
      await _apiService.deleteInvoice(id);
      _invoices.removeWhere((inv) => inv.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorKey = 'invoice.deleteError';
      notifyListeners();
      if (kDebugMode) {
        print('Erreur deleteInvoice: $e');
      }
      return false;
    }
  }

  /// Rechercher des factures
  Future<void> searchInvoices(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      await loadInvoices();
      return;
    }

    _isLoading = true;
    _errorKey = null;
    notifyListeners();

    try {
      _invoices = await _apiService.searchInvoices(query);
    } catch (e) {
      _errorKey = 'invoice.loadError';
      if (kDebugMode) {
        print('Erreur searchInvoices: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rafraîchir les données
  Future<void> refresh() async {
    await loadInvoices();
  }
}
