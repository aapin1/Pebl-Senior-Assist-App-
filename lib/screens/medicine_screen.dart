import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/medicine_storage_service.dart';
import '../services/notification_service.dart';
import '../models/medicine.dart';
import 'add_edit_medicine_screen.dart';

/// Medicine management screen - fully responsive
/// Allows users to view, add, edit, and delete medications
/// Uses local storage (no login required)
class MedicineScreen extends StatefulWidget {
  final AccessibilityService accessibilityService;
  
  const MedicineScreen({
    super.key,
    required this.accessibilityService,
  });

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  // Storage service for medicines
  final MedicineStorageService _storageService = MedicineStorageService();

  // Notification service for scheduling local reminders
  final NotificationService _notificationService = NotificationService();
  
  // List of medicines loaded from storage
  List<Medicine> _medicines = [];
  
  // Loading state
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // Load medicines when screen opens
    _loadMedicines();
  }

  /// Build a human-readable description of when to take the medicine
  /// Routine comment: Converts stored HH:mm values into localized times
  String _buildTimesDescription(BuildContext context, Medicine medicine) {
    // If no times stored, return a simple placeholder
    if (medicine.timesToTake.isEmpty) {
      return 'No reminder times set';
    }

    // Determine if values look like clock times (contain a colon)
    final allLookLikeTimes = medicine.timesToTake.every((value) => value.contains(':'));

    if (!allLookLikeTimes) {
      // Routine comment: Backwards compatibility for older label-based entries
      return medicine.timesToTake.join(', ');
    }

    // Convert each HH:mm string to a user-friendly time using TimeOfDay
    final localizations = MaterialLocalizations.of(context);
    final List<String> formattedTimes = [];

    for (final value in medicine.timesToTake) {
      final parts = value.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          final timeOfDay = TimeOfDay(hour: hour, minute: minute);
          formattedTimes.add(localizations.formatTimeOfDay(timeOfDay, alwaysUse24HourFormat: false));
        }
      }
    }

    if (formattedTimes.isEmpty) {
      return medicine.timesToTake.join(', ');
    }

    // Routine comment: Prefix with 'Take at' for clarity on list screen
    return 'Take at ${formattedTimes.join(', ')}';
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  /// Load medicines from storage
  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load medicines from local storage
      final medicines = await _storageService.loadMedicines();
      
      // Update state with loaded medicines
      setState(() {
        _medicines = medicines;
        _isLoading = false;
      });

      // Routine comment: Reschedule all notifications to match latest medicines
      await _notificationService.rescheduleAll(_medicines);
    } catch (e) {
      // Handle error gracefully
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medicines: $e')),
        );
      }
    }
  }
  
  /// Delete a medicine
  Future<void> _deleteMedicine(String medicineId) async {
    try {
      // Delete from storage
      await _storageService.deleteMedicine(medicineId);
      
      // Reload list to show updated data
      await _loadMedicines();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting medicine: $e')),
        );
      }
    }
  }
  
  /// Navigate to add medicine screen
  void _navigateToAddMedicine() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMedicineScreen(
          accessibilityService: widget.accessibilityService,
          onSave: _loadMedicines,
        ),
      ),
    );
  }
  
  /// Navigate to edit medicine screen
  void _navigateToEditMedicine(Medicine medicine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMedicineScreen(
          accessibilityService: widget.accessibilityService,
          medicine: medicine,
          onSave: _loadMedicines,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate base text size from screen height for natural appearance
    final baseTextSize = screenHeight * 0.02;
    
    return AnimatedBuilder(
      animation: widget.accessibilityService,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            // Same gradient background as other screens
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
                  // Header with back button and title
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.01,
                    ),
                    child: Row(
                      children: [
                        // Back button
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back),
                          iconSize: screenHeight * 0.035,
                          color: Colors.blue.shade700,
                        ),
                        // Title
                        Expanded(
                          child: Text(
                            'My Medicines',
                            style: TextStyle(
                              fontSize: baseTextSize * 1.2 * widget.accessibilityService.textSizeMultiplier,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Spacer to balance back button
                        SizedBox(width: screenHeight * 0.035 + 16),
                      ],
                    ),
                  ),
                  
                  // Medicine list or empty state
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.blue.shade600,
                            ),
                          )
                        : _medicines.isEmpty
                            ? _buildEmptyState(screenHeight, screenWidth, baseTextSize)
                            : _buildMedicineList(screenHeight, screenWidth, baseTextSize),
                  ),
                  
                  // Add medicine button at bottom
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToAddMedicine,
                        icon: Icon(
                          Icons.add,
                          size: screenHeight * 0.03,
                        ),
                        label: Text(
                          'Add Medicine',
                          style: TextStyle(
                            fontSize: baseTextSize * 1.0 * widget.accessibilityService.textSizeMultiplier,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
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
  
  /// Build empty state when no medicines added yet
  Widget _buildEmptyState(double screenHeight, double screenWidth, double baseTextSize) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Medicine icon
            Container(
              width: screenHeight * 0.12,
              height: screenHeight * 0.12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenHeight * 0.03),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.medication,
                size: screenHeight * 0.06,
                color: Colors.purple.shade600,
              ),
            ),
            
            SizedBox(height: screenHeight * 0.03),
            
            // Empty state message
            Text(
              'No medicines yet',
              style: TextStyle(
                fontSize: baseTextSize * 1.1 * widget.accessibilityService.textSizeMultiplier,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: screenHeight * 0.01),
            
            Text(
              'Tap "Add Medicine" below to get started',
              style: TextStyle(
                fontSize: baseTextSize * 0.85 * widget.accessibilityService.textSizeMultiplier,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build list of medicines
  Widget _buildMedicineList(double screenHeight, double screenWidth, double baseTextSize) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      itemCount: _medicines.length,
      itemBuilder: (context, index) {
        final medicine = _medicines[index];
        return _buildMedicineCard(medicine, screenHeight, screenWidth, baseTextSize);
      },
    );
  }
  
  /// Build individual medicine card
  Widget _buildMedicineCard(Medicine medicine, double screenHeight, double screenWidth, double baseTextSize) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.purple.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade200.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine name and dosage
            Row(
              children: [
                Icon(
                  Icons.medication,
                  size: screenHeight * 0.03,
                  color: Colors.purple.shade600,
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: TextStyle(
                          fontSize: baseTextSize * 1.0 * widget.accessibilityService.textSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        medicine.dosage,
                        style: TextStyle(
                          fontSize: baseTextSize * 0.8 * widget.accessibilityService.textSizeMultiplier,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: screenHeight * 0.015),
            
            // Times to take
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: screenHeight * 0.025,
                  color: Colors.green.shade600,
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    _buildTimesDescription(context, medicine),
                    style: TextStyle(
                      fontSize: baseTextSize * 0.8 * widget.accessibilityService.textSizeMultiplier,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: screenHeight * 0.015),
            
            // Edit and Delete buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit button
                TextButton.icon(
                  onPressed: () => _navigateToEditMedicine(medicine),
                  icon: Icon(
                    Icons.edit,
                    size: screenHeight * 0.025,
                  ),
                  label: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: baseTextSize * 0.8 * widget.accessibilityService.textSizeMultiplier,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
                
                SizedBox(width: screenWidth * 0.02),
                
                // Delete button
                TextButton.icon(
                  onPressed: () {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'Delete Medicine?',
                          style: TextStyle(
                            fontSize: baseTextSize * 1.0 * widget.accessibilityService.textSizeMultiplier,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to delete ${medicine.name}?',
                          style: TextStyle(
                            fontSize: baseTextSize * 0.9 * widget.accessibilityService.textSizeMultiplier,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: baseTextSize * 0.9 * widget.accessibilityService.textSizeMultiplier,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteMedicine(medicine.id);
                            },
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: baseTextSize * 0.9 * widget.accessibilityService.textSizeMultiplier,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.delete,
                    size: screenHeight * 0.025,
                  ),
                  label: Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: baseTextSize * 0.8 * widget.accessibilityService.textSizeMultiplier,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
