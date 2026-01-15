import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:iris_designer/Core/Config/Theme.dart'; // Ensure this path is correct

class CustomLabeledDropdownTrigger extends StatefulWidget {
  
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController controller; // 1. Add Controller

  const CustomLabeledDropdownTrigger({
    super.key,
    
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
  });

  @override
  State<CustomLabeledDropdownTrigger> createState() => _CustomLabeledDropdownTriggerState();
}

class _CustomLabeledDropdownTriggerState extends State<CustomLabeledDropdownTrigger> {
  
  // Helper to get text to display (either the selected value or the hint)
  String get _displayText {
    if (widget.controller.text.isNotEmpty) {
      return widget.controller.text;
    }
    return widget.hintText;
  }

  // Helper to determine text color
  Color get _textColor {
    if (widget.controller.text.isNotEmpty) {
      return Colors.white; // Or AppColors.textWhite
    }
    return AppColors.textGrey;
  }

  @override
  Widget build(BuildContext context) {
    return 

        // Dropdown Trigger
        InkWell(
          onTap: () {
            // 2. Open Country Picker
            showCountryPicker(
              context: context,
              showPhoneCode: false, // Optional: hides phone code like +1
              countryListTheme: CountryListThemeData(
                flagSize: 25,
                backgroundColor: AppColors.cardBackground, // Match your theme
                textStyle: const TextStyle(color: Colors.white),
                bottomSheetHeight: 500,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
                inputDecoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Start typing to search',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textGrey.withOpacity(0.2)),
                  ),
                ),
              ),
              onSelect: (Country country) {
                // 3. Store result in controller & Update UI
                setState(() {
                  widget.controller.text = country.displayNameNoCountryCode; 
                  // or just country.name if you prefer
                });
                debugPrint("Selected country: ${country.displayName}");
              },
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              prefixIcon: Icon(widget.prefixIcon, color: AppColors.textGrey, size: 20),
              suffixIcon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
            ),
            // 4. Show the dynamic text
            child: Text(
              _displayText, 
              style: TextStyle(color: _textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        
      
    );
  }
}