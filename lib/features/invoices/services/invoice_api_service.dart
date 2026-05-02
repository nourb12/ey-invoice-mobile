import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../models/invoice.dart';

class InvoiceApiService {
  /// Récupérer toutes les factures
  Future<List<Invoice>> getAllInvoices() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/invoices'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data.map((json) => Invoice.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer une facture par ID
  Future<Invoice> getInvoiceById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/invoices/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Invoice.fromJson(json.decode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw Exception('Facture non trouvée');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Créer une nouvelle facture
  Future<Invoice> createInvoice(Invoice invoice) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/invoices'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(invoice.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Invoice.fromJson(json.decode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de création: $e');
    }
  }

  /// Mettre à jour une facture
  Future<Invoice> updateInvoice(int id, Invoice invoice) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/invoices/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(invoice.toJson()),
      );

      if (response.statusCode == 200) {
        return Invoice.fromJson(json.decode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw Exception('Facture non trouvée');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de mise à jour: $e');
    }
  }

  /// Supprimer une facture
  Future<void> deleteInvoice(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/invoices/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de suppression: $e');
    }
  }

  /// Rechercher des factures
  Future<List<Invoice>> searchInvoices(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/invoices?search=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data.map((json) => Invoice.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de recherche: $e');
    }
  }
}
