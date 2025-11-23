import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/medicine_storage_service.dart';
import '../models/medicine.dart';

/// Screen for adding or editing a medicine
/// Form screen with all medicine fields
class AddEditMedicineScreen extends StatefulWidget {
  final AccessibilityService accessibilityService;
  final Medicine? medicine; // Null for add, populated for edit
  final VoidCallback onSave; // Callback to refresh list
  
  const AddEditMedicineScreen({
    super.key,
    required this.accessibilityService,
    this.medicine,
    required this.onSave,
  });

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Storage service
  final MedicineStorageService _storageService = MedicineStorageService();
  
  // Text controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _notesController;
  
  // Selected times to take medicine
  final Set<String> _selectedTimes = {};
  
  // Available time options
  final List<String> _timeOptions = ['Morning', 'Afternoon', 'Evening', 'Bedtime'];
  
  // Saving state
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data if editing
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _dosageController = TextEditingController(text: widget.medicine?.dosage ?? '');
    _notesController = TextEditingController(text: widget.medicine?.notes ?? '');
    
    // Initialize selected times if editing
    if (widget.medicine != null) {
      _selectedTimes.addAll(widget.medicine!.timesToTake);
    }
  }
  
  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  /// Save medicine to storage
  Future<void> _saveMedicine() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Check at least one time is selected
    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one time to take medicine')),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Create medicine object
      final medicine = Medicine(
        id: widget.medicine?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        timesToTake: _selectedTimes.toList(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        createdAt: widget.medicine?.createdAt ?? DateTime.now(),
      );
      
      // Save or update medicine
      if (widget.medicine == null) {
        await _storageService.addMedicine(medicine);
      } else {
        await _storageService.updateMedicine(medicine);
      }
      
      // Call callback to refresh list
      widget.onSave();
      
      // Go back to medicine list
      if (mounted) {
        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.medicine == null 
                ? 'Medicine added successfully' 
                : 'Medicine updated successfully'),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving medicine: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate base text size
    final baseTextSize = screenHeight * 0.02;
    
    return AnimatedBuilder(
      animation: widget.accessibilityService,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            // Same gradient background
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade100,
                  Colors.blue.shade50,
                  Colors.white,
                  Colors.green.shade50,
                  Colors.green.shade100,
                ],
                stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.01,
                    ),
                    child: Row(
                      children: [
                        // Back button
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          iconSize: screenHeight * 0.035,
                          color: Colors.blue.shade700,
                        ),
                        // Title
                        Expanded(
                          child: Text(
                            widget.medicine == null ? 'Add Medicine' : 'Edit Medicine',
                            style: TextStyle(
                              fontSize: baseTextSize * 1.2 * widget.accessibilityService.textSizeMultiplier,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Spacer
                        SizedBox(width: screenHeight * 0.035 + 16),
                      ],
                    ),
                  ),
                  
                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Medicine Name field
                            _buildTextField(
                              controller: _nameController,
                              label: 'Medicine Name',
                              hint: 'e.g., Metformin',
                              icon: Icons.medication,
                              required: true,
                              baseTextSize: baseTextSize,
                              screenHeight: screenHeight,
                            ),
                            
                            SizedBox(height: screenHeight * 0.018),
                            
                            // Dosage field
                            _buildTextField(
                              controller: _dosageController,
                              label: 'Dosage',
                              hint: 'e.g., 500mg',
                              icon: Icons.science,
                              required: true,
                              baseTextSize: baseTextSize,
                              screenHeight: screenHeight,
                            ),
                            
                            SizedBox(height: screenHeight * 0.025),
                            
                            // When to take section
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: screenHeight * 0.025,
                                        color: Colors.blue.shade600,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        'When to Take',
                                        style: TextStyle(
                                          fontSize: baseTextSize * 0.9 * widget.accessibilityService.textSizeMultiplier,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: screenHeight * 0.012),
                                  
                                  // Time selection chips
                                  Wrap(
                                    spacing: screenWidth * 0.02,
                                    runSpacing: screenHeight * 0.01,
                                    children: _timeOptions.map((time) {
                                      final isSelected = _selectedTimes.contains(time);
                                      return ChoiceChip(
                                        label: Text(
                                          time,
                                          style: TextStyle(
                                            fontSize: baseTextSize * 0.85 * widget.accessibilityService.textSizeMultiplier,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? Colors.white : Colors.blue.shade700,
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedTimes.add(time);
                                            } else {
                                              _selectedTimes.remove(time);
                                            }
                                          });
                                        },
                                        selectedColor: Colors.blue.shade600,
                                        backgroundColor: Colors.white,
                                        side: BorderSide(
                                          color: isSelected ? Colors.blue.shade600 : Colors.blue.shade300,
                                          width: 1.5,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.03,
                                          vertical: screenHeight * 0.01,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: screenHeight * 0.02),
                            
                            // Notes field (optional)
                            _buildTextField(
                              controller: _notesController,
                              label: 'Notes (Optional)',
                              hint: 'Any special instructions',
                              icon: Icons.note,
                              required: false,
                              maxLines: 3,
                              baseTextSize: baseTextSize,
                              screenHeight: screenHeight,
                            ),
                            
                            SizedBox(height: screenHeight * 0.03),
                            
                            // Save button
                            SizedBox(
                              width: double.infinity,
                              height: screenHeight * 0.07,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveMedicine,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 3,
                                ),
                                child: _isSaving
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        'Save Medicine',
                                        style: TextStyle(
                                          fontSize: baseTextSize * 1.0 * widget.accessibilityService.textSizeMultiplier,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Build text field with consistent styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool required,
    required double baseTextSize,
    required double screenHeight,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: maxLines > 1 ? 3 : 1,
      style: TextStyle(
        fontSize: baseTextSize * 0.9 * widget.accessibilityService.textSizeMultiplier,
        height: 1.3,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: baseTextSize * 0.85 * widget.accessibilityService.textSizeMultiplier,
          color: Colors.blue.shade700,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: baseTextSize * 0.8 * widget.accessibilityService.textSizeMultiplier,
          color: Colors.grey.shade400,
        ),
        prefixIcon: Icon(
          icon, 
          size: screenHeight * 0.028,
          color: Colors.blue.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.95),
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenHeight * 0.02,
          vertical: screenHeight * 0.018,
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            }
          : null,
    );
  }
}
