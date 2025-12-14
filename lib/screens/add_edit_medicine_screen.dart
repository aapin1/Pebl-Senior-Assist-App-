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
  
  // List of exact reminder times for this medicine
  // Routine comment: Each TimeOfDay represents one daily reminder time
  final List<TimeOfDay> _reminderTimes = [];

  // Whether reminders are enabled for this medicine
  bool _remindersEnabled = false;
  
  // Saving state
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data if editing
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _dosageController = TextEditingController(text: widget.medicine?.dosage ?? '');
    _notesController = TextEditingController(text: widget.medicine?.notes ?? '');
    
    // Initialize reminder times and toggle if editing an existing medicine
    if (widget.medicine != null) {
      // Routine comment: Try to parse stored timesToTake (HH:mm) into TimeOfDay objects
      for (final timeString in widget.medicine!.timesToTake) {
        final parts = timeString.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            _reminderTimes.add(TimeOfDay(hour: hour, minute: minute));
          }
        }
      }

      // Routine comment: Initialize reminders toggle from existing medicine
      _remindersEnabled = widget.medicine!.remindersEnabled;
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
    
    // Routine comment: If reminders are enabled, ensure at least one reminder time exists
    if (_remindersEnabled && _reminderTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one reminder time or turn off reminders')),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Routine comment: Build list and map of times in HH:mm format for storage and notifications
      final List<String> timesToTake = [];
      final Map<String, String> timesToTakeDetails = {};
      for (var i = 0; i < _reminderTimes.length; i++) {
        final timeOfDay = _reminderTimes[i];
        final hour = timeOfDay.hour.toString().padLeft(2, '0');
        final minute = timeOfDay.minute.toString().padLeft(2, '0');
        final value = '$hour:$minute';
        timesToTake.add(value);
        timesToTakeDetails['time_$i'] = value;
      }

      // Routine comment: Ensure dosage always includes 'mg' suffix for display
      String normalizedDosage = _dosageController.text.trim();
      if (normalizedDosage.isNotEmpty &&
          !normalizedDosage.toLowerCase().contains('mg')) {
        normalizedDosage = '$normalizedDosage mg';
      }

      // Create medicine object
      final medicine = Medicine(
        id: widget.medicine?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        dosage: normalizedDosage,
        timesToTake: timesToTake,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        createdAt: widget.medicine?.createdAt ?? DateTime.now(),
        timesToTakeDetails: timesToTakeDetails,
        remindersEnabled: _remindersEnabled,
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
        // Routine comment: Use floating SnackBar so it does not cover bottom button
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.medicine == null 
                  ? 'Medicine added successfully' 
                  : 'Medicine updated successfully',
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
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
                            
                            // Reminder times section
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
                                  // Routine comment: Single header row with icon, label, and switch
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: screenHeight * 0.025,
                                        color: Colors.blue.shade600,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Expanded(
                                        child: Text(
                                          'Pick times for reminders',
                                          style: TextStyle(
                                            fontSize: baseTextSize * 0.9 * widget.accessibilityService.textSizeMultiplier,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                          // Routine comment: Allow wrapping instead of ellipsis so full phrase is visible
                                          maxLines: 2,
                                          overflow: TextOverflow.visible,
                                          softWrap: true,
                                        ),
                                      ),
                                      Switch(
                                        value: _remindersEnabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _remindersEnabled = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: screenHeight * 0.008),

                                  // Routine comment: Show reminder times only when reminders are enabled
                                  if (_remindersEnabled)
                                    Column(
                                      children: [
                                        // List of existing reminder time rows
                                        ..._reminderTimes.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final timeOfDay = entry.value;
                                          final timeText = timeOfDay.format(context);
                                          return Padding(
                                            padding: EdgeInsets.only(top: screenHeight * 0.006),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: screenWidth * 0.03,
                                                vertical: screenHeight * 0.008,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.blue.shade100,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        size: screenHeight * 0.022,
                                                        color: Colors.blue.shade600,
                                                      ),
                                                      SizedBox(width: screenWidth * 0.02),
                                                      // Routine comment: Label stays short to avoid wrapping
                                                      Text(
                                                        'Reminder ${index + 1}',
                                                        style: TextStyle(
                                                          fontSize: baseTextSize * 0.85 * widget.accessibilityService.textSizeMultiplier,
                                                          color: Colors.grey.shade800,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      // Delete reminder time button
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.delete_outline,
                                                          size: screenHeight * 0.024,
                                                          color: Colors.red.shade400,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _reminderTimes.removeAt(index);
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: screenHeight * 0.004),
                                                  // Routine comment: Time button in its own row, right-aligned, to avoid overflow
                                                  Align(
                                                    alignment: Alignment.centerRight,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: TextButton(
                                                        onPressed: () async {
                                                          final picked = await showTimePicker(
                                                            context: context,
                                                            initialTime: timeOfDay,
                                                          );
                                                          if (picked != null) {
                                                            setState(() {
                                                              _reminderTimes[index] = picked;
                                                            });
                                                          }
                                                        },
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: Colors.blue.shade700,
                                                          padding: EdgeInsets.symmetric(
                                                            horizontal: screenWidth * 0.008,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          timeText,
                                                          style: TextStyle(
                                                            // Routine comment: Slightly smaller font so numbers do not touch
                                                            fontSize: baseTextSize * 0.76 * widget.accessibilityService.textSizeMultiplier,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          softWrap: false,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),

                                        SizedBox(height: screenHeight * 0.01),

                                        // Add new reminder time button
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              // Routine comment: Default initial time is 9:00 AM
                                              final initialTime = _reminderTimes.isNotEmpty
                                                  ? _reminderTimes.last
                                                  : const TimeOfDay(hour: 9, minute: 0);
                                              final picked = await showTimePicker(
                                                context: context,
                                                initialTime: initialTime,
                                              );
                                              if (picked != null) {
                                                setState(() {
                                                  _reminderTimes.add(picked);
                                                });
                                              }
                                            },
                                            icon: Icon(
                                              Icons.add_circle_outline,
                                              size: screenHeight * 0.024,
                                              color: Colors.blue.shade600,
                                            ),
                                            label: Text(
                                              'Add time',
                                              style: TextStyle(
                                                fontSize: baseTextSize * 0.85 * widget.accessibilityService.textSizeMultiplier,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                  // Routine comment: No extra helper text when reminders are off to keep UI clean
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
