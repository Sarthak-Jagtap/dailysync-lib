// lib/finance_manager/views/create_expense_screen.dart
import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Corrected ML Kit import
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker

import '../controllers/finance_controller.dart';
import '../models/expense_model.dart';

class CreateExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;

  const CreateExpenseScreen({super.key, this.existingExpense});

  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _merchantController;

  String? _selectedCategory;
  String _paymentType = "Cash";
  DateTime _selectedDate = DateTime.now();

  late bool _isEditing;
  bool _isScanning = false; // To show loading indicator during scan

  // ML Kit instances
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingExpense != null;

    _titleController =
        TextEditingController(text: widget.existingExpense?.title ?? '');
    _amountController = TextEditingController(
        text: widget.existingExpense != null
            ? widget.existingExpense!.amount.toStringAsFixed(2)
            : ''); // Format amount
    _descriptionController =
        TextEditingController(text: widget.existingExpense?.description ?? '');
    _merchantController =
        TextEditingController(text: widget.existingExpense?.merchant ?? '');
    _selectedCategory = widget.existingExpense?.category;
    _paymentType = widget.existingExpense?.paymentType ?? 'Cash';
    _selectedDate = widget.existingExpense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    _textRecognizer.close(); // Dispose recognizer
    super.dispose();
  }

  // --- Date Picker ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- Scan Receipt Logic (IMPROVED) ---
  Future<void> _scanReceipt(ImageSource source) async {
    setState(() => _isScanning = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide previous messages

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        if (mounted) {
          _showSnackbar('No image selected.', isError: false);
        }
        setState(() => _isScanning = false);
        return;
      }

      final InputImage inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // --- Enhanced Parsing Logic ---
      String? foundAmount;
      DateTime? foundDate;
      String? foundMerchant;
      double maxAmount = 0.0; // Keep track of the largest amount found

      final totalKeywords = [
        'total',
        'amount due',
        'balance',
        'payment',
        'paid',
        'charge'
      ];
      RegExp amountRegex = RegExp(
          r'[\₹\$£€]?\s?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})|\d+\.\d{1,2})');
      RegExp dateRegex = RegExp(
          r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})');

      debugPrint("--- Recognized Text Blocks ---");
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String lineTextLower = line.text.toLowerCase();
          debugPrint("Line: ${line.text}"); // Log each line

          // 1. Check for Total Amount
          bool lineHasTotalKeyword =
              totalKeywords.any((keyword) => lineTextLower.contains(keyword));

          for (Match match in amountRegex.allMatches(line.text)) {
            String? potentialAmountStr =
                match.group(1)?.replaceAll(',', ''); // Remove commas
            potentialAmountStr = potentialAmountStr
                ?.replaceAll(RegExp(r'[^\d.]'), ''); // Sanitize further

            if (potentialAmountStr != null) {
              double? potentialAmount = double.tryParse(potentialAmountStr);
              if (potentialAmount != null) {
                // Prioritize amount if found on a line with a total keyword
                if (lineHasTotalKeyword) {
                  // Often the total is the largest value on that line
                  if (potentialAmount >
                      (double.tryParse(foundAmount ?? '0.0') ?? 0.0)) {
                    foundAmount = potentialAmountStr;
                    maxAmount = potentialAmount; // Update max if this is the highest on a total line
                    debugPrint(
                        "   Found potential total amount on keyword line: $foundAmount");
                  }
                }
                // Also, keep track of the overall largest amount found
                else if (potentialAmount > maxAmount) {
                  maxAmount = potentialAmount;
                  // Temporarily store this as potential total if no keyword match found yet
                  if (foundAmount == null ||
                      !(totalKeywords.any((kw) =>
                          recognizedText.text.toLowerCase().contains(kw) &&
                          recognizedText.text.contains(foundAmount!)))) {
                    foundAmount = potentialAmountStr;
                    debugPrint("   Found new max potential amount: $foundAmount");
                  }
                }
              }
            }
          }

          // 2. Check for Date (Simple approach - might take first found)
          if (foundDate == null) {
            final dateMatch = dateRegex.firstMatch(line.text);
            if (dateMatch != null) {
              String dateString = dateMatch.group(0)!;
              try {
                if (dateString.contains('/')) {
                  foundDate = DateFormat('dd/MM/yyyy').tryParse(dateString) ??
                      DateFormat('MM/dd/yyyy').tryParse(dateString);
                } else if (dateString.contains('-')) {
                  foundDate = DateFormat('dd-MM-yyyy').tryParse(dateString) ??
                      DateFormat('yyyy-MM-dd').tryParse(dateString);
                }
                if (foundDate != null)
                  debugPrint("   Found potential date: $dateString");
              } catch (e) {
                debugPrint("   Date parsing failed for '$dateString': $e");
              }
            }
          }

          // 3. Attempt to find Merchant (Often in the first few lines)
          // This is highly heuristic and unreliable
          if (foundMerchant == null &&
              recognizedText.blocks.indexOf(block) < 2 &&
              line.text.trim().isNotEmpty) {
            // Assuming merchant is often uppercase or longer single lines at the top
            if (line.text == line.text.toUpperCase() ||
                line.elements.length == 1) {
              foundMerchant = line.text.trim();
              debugPrint("   Found potential merchant: $foundMerchant");
            }
          }
        }
      }
      debugPrint("--- Parsing Complete ---");

      // Use the largest amount found if a keyword-specific one wasn't better
      if (maxAmount > 0 &&
          (double.tryParse(foundAmount ?? '0.0') ?? 0.0) < maxAmount) {
        foundAmount = maxAmount.toStringAsFixed(2); // Format to 2 decimal places
        debugPrint("Using overall max amount as total: $foundAmount");
      }

      // --- Pre-fill Form ---
      setState(() {
        if (foundAmount != null) _amountController.text = foundAmount;
        if (foundDate != null) _selectedDate = foundDate;
        if (foundMerchant != null) _merchantController.text = foundMerchant;
        _descriptionController.text = "Scanned Receipt"; // Keep placeholder
        if (foundMerchant != null && _titleController.text.isEmpty) {
          _titleController.text = foundMerchant;
        }
      });

      if (mounted) {
        _showSnackbar('Text recognized. Please verify details.', isError: false);
      }
    } catch (e) {
      debugPrint("Error scanning receipt: $e");
      if (mounted) {
        _showSnackbar('Error scanning receipt. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  // --- Save Logic ---
  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        _showErrorSnackbar('Please enter a valid positive amount');
        return;
      }
      if (_selectedCategory == null) {
        _showErrorSnackbar('Please select a category');
        return;
      }

      final newExpense = Expense(
        id: widget.existingExpense?.id,
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory!,
        date: _selectedDate,
        paymentType: _paymentType,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        merchant: _merchantController.text.trim().isEmpty
            ? null
            : _merchantController.text.trim(),
      );

      Navigator.pop(context, newExpense);
    }
  }

  // Updated Snackbar helper
  void _showSnackbar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating // Optional: Make it float
          ),
    );
  }

  void _showErrorSnackbar(String message) {
    _showSnackbar(message, isError: true);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final financeController =
        Provider.of<FinanceController>(context, listen: false);
    final categories = financeController.categories;
    final screenWidth = MediaQuery.of(context).size.width;

    // Ensure category selection is valid
    if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
      _selectedCategory = categories.isNotEmpty ? categories.first : null;
    } else if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Expense" : "Create Expense"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context: context,
                      icon: Icons.edit_note,
                      label: "Manual Entry",
                      onPressed: () {},
                      width: screenWidth * 0.4,
                      isActive: true,
                    ),
                    _buildActionButton(
                      context: context,
                      icon: Icons.document_scanner_outlined,
                      label: _isScanning ? "Scanning..." : "Scan Receipt",
                      onPressed:
                          _isScanning ? null : () => _showScanOptions(context),
                      width: screenWidth * 0.4,
                    ),
                  ],
                ),
                if (_isScanning) ...[
                  const SizedBox(height: 10),
                  const Center(child: LinearProgressIndicator()),
                ],
                const SizedBox(height: 24),

                _buildTextFormField(
                  theme: theme,
                  controller: _titleController,
                  label: "Title*",
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? "Enter expense title"
                          : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  theme: theme,
                  controller: _amountController,
                  label: "Amount*",
                  prefixText: "₹ ",
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return "Enter amount";
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0)
                      return "Enter a valid positive amount";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownFormField<String>( // Specify type for Dropdown
                  theme: theme,
                  label: "Category*",
                  value: _selectedCategory,
                  items: categories,
                  onChanged: categories.isEmpty
                      ? null
                      : (String? value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                  validator: (value) =>
                      (value == null || value.isEmpty)
                          ? "Select a category"
                          : null,
                ),
                const SizedBox(height: 16),
                _buildDatePickerField(context, theme),
                const SizedBox(height: 16),
                _buildDropdownFormField<String>( // Specify type for Dropdown
                  theme: theme,
                  label: "Payment Type*",
                  value: _paymentType,
                  items: const ["Cash", "Card", "Online", "Other"],
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _paymentType = value;
                      });
                    }
                  },
                  validator: (value) =>
                      (value == null || value.isEmpty)
                          ? "Select payment type"
                          : null,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  theme: theme,
                  controller: _merchantController,
                  label: "Merchant / Store",
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  theme: theme,
                  controller: _descriptionController,
                  label: "Description / Notes",
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveExpense,
                  child: Text(
                      _isEditing ? "Update Expense" : "Save Expense",
                      style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Reusable Themed Form Field Widgets ---

  Widget _buildTextFormField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.hintColor),
        prefixText: prefixText,
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor ??
            theme.colorScheme.surface.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      validator: validator,
      maxLines: maxLines,
      minLines: maxLines == null ? 1 : maxLines,
      textCapitalization: textCapitalization,
    );
  }

  Widget _buildDropdownFormField<T>({
    required ThemeData theme,
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?>? onChanged,
    String? Function(T?)? validator,
    String hintText = "Select...",
  }) {
    final T? validValue = (items.isNotEmpty && value != null && items.contains(value))
        ? value
        : null;

    return DropdownButtonFormField<T>(
      value: validValue,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.hintColor),
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor ??
            theme.colorScheme.surface.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      validator: validator,
      hint: items.isEmpty
          ? const Text("No options available")
          : Text(hintText),
      isExpanded: true,
      dropdownColor: theme.cardColor,
    );
  }

  Widget _buildDatePickerField(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date*',
          labelStyle: TextStyle(color: theme.hintColor),
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor ??
              theme.colorScheme.surface.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          suffixIcon:
              Icon(Icons.calendar_month_outlined, color: theme.hintColor),
        ),
        child: Text(
          DateFormat.yMMMd().format(_selectedDate),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required double width,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: isActive
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.secondaryContainer,
      foregroundColor: isActive
          ? theme.colorScheme.onPrimaryContainer
          : theme.colorScheme.onSecondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
    );

    return SizedBox(
      width: width.clamp(120, 200),
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        style: buttonStyle,
      ),
    );
  }

  void _showScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _scanReceipt(ImageSource.gallery);
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _scanReceipt(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}