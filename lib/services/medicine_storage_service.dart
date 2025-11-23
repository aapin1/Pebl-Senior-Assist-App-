import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';

/// Service for storing and retrieving medicines locally on device
/// Uses SharedPreferences for simple, persistent storage
/// No login required - data stays on device
class MedicineStorageService {
  static const String _medicinesKey = 'medicines_list';
  
  /// Save a list of medicines to local storage
  /// Routine comment: Converts medicine objects to JSON and stores them
  Future<void> saveMedicines(List<Medicine> medicines) async {
    try {
      // Get shared preferences instance for local storage
      final prefs = await SharedPreferences.getInstance();
      
      // Convert each medicine to JSON format
      final List<Map<String, dynamic>> medicinesJson = 
          medicines.map((medicine) => medicine.toJson()).toList();
      
      // Encode to JSON string for storage
      final String jsonString = jsonEncode(medicinesJson);
      
      // Save to local storage
      await prefs.setString(_medicinesKey, jsonString);
    } catch (e) {
      // Log error but don't crash - graceful error handling
      print('Error saving medicines: $e');
      rethrow;
    }
  }
  
  /// Load all medicines from local storage
  /// Routine comment: Retrieves stored JSON and converts back to Medicine objects
  Future<List<Medicine>> loadMedicines() async {
    try {
      // Get shared preferences instance
      final prefs = await SharedPreferences.getInstance();
      
      // Retrieve stored JSON string
      final String? jsonString = prefs.getString(_medicinesKey);
      
      // If no data stored yet, return empty list
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      // Decode JSON string to list
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      // Convert each JSON object back to Medicine object
      final List<Medicine> medicines = jsonList
          .map((json) => Medicine.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return medicines;
    } catch (e) {
      // If error loading, return empty list rather than crashing
      print('Error loading medicines: $e');
      return [];
    }
  }
  
  /// Add a new medicine to storage
  /// Routine comment: Loads existing medicines, adds new one, saves back
  Future<void> addMedicine(Medicine medicine) async {
    try {
      // Load current list of medicines
      final medicines = await loadMedicines();
      
      // Add new medicine to list
      medicines.add(medicine);
      
      // Save updated list back to storage
      await saveMedicines(medicines);
    } catch (e) {
      print('Error adding medicine: $e');
      rethrow;
    }
  }
  
  /// Update an existing medicine
  /// Routine comment: Finds medicine by ID and replaces it with updated version
  Future<void> updateMedicine(Medicine updatedMedicine) async {
    try {
      // Load current list
      final medicines = await loadMedicines();
      
      // Find index of medicine to update
      final index = medicines.indexWhere((m) => m.id == updatedMedicine.id);
      
      // If found, replace with updated version
      if (index != -1) {
        medicines[index] = updatedMedicine;
        await saveMedicines(medicines);
      }
    } catch (e) {
      print('Error updating medicine: $e');
      rethrow;
    }
  }
  
  /// Delete a medicine by ID
  /// Routine comment: Removes medicine from list and saves updated list
  Future<void> deleteMedicine(String medicineId) async {
    try {
      // Load current list
      final medicines = await loadMedicines();
      
      // Remove medicine with matching ID
      medicines.removeWhere((m) => m.id == medicineId);
      
      // Save updated list
      await saveMedicines(medicines);
    } catch (e) {
      print('Error deleting medicine: $e');
      rethrow;
    }
  }
  
  /// Clear all medicines (for testing or reset)
  /// Routine comment: Removes all stored medicine data
  Future<void> clearAllMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_medicinesKey);
    } catch (e) {
      print('Error clearing medicines: $e');
      rethrow;
    }
  }
}
