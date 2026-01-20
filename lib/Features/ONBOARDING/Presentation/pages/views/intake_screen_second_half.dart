import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris_designer/Core/Config/Theme.dart';
import 'package:iris_designer/Core/Services/hive_service.dart'; 
import 'package:iris_designer/Core/Shared/Widgets/global_submit_button_widget.dart';
import 'package:iris_designer/Core/Utils/toast_service.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/bloc/onboarding_bloc.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/widgets/custom_dropdown.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/widgets/session-history-dialog.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/widgets/text_field_widget.dart';

class RightIntakeFormView extends StatefulWidget {
  final ClientSession? existingSession;
  const RightIntakeFormView({super.key, this.existingSession});

  @override
  State<RightIntakeFormView> createState() => _RightIntakeFormViewState();
}

class _RightIntakeFormViewState extends State<RightIntakeFormView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _countryController = TextEditingController();
  late var _nameController = TextEditingController();
  late var _emailController = TextEditingController();
  String? _countryError;
  
  // ✅ NEW: State to track if we found a match
  bool _canResume = false;
  ClientSession? _matchedSession;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.existingSession?.clientName ?? '',
    );
    _emailController = TextEditingController(
      text: widget.existingSession?.email ?? '',
    );
    _countryController = TextEditingController(
      text: widget.existingSession?.country ?? '',
    );

    // ✅ ADD LISTENERS: Check for existing session on every keystroke
    _nameController.addListener(_onNameChanged);
    _emailController.addListener(_checkSessionMatch);
    _countryController.addListener(_checkSessionMatch);
  }

  void _onNameChanged() {
    // Keep the capitalization logic
    final String text = _nameController.text;
    if (text.isNotEmpty && text[0] != text[0].toUpperCase()) {
      final String newText = text[0].toUpperCase() + text.substring(1);
      _nameController.value = _nameController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: _nameController.selection.baseOffset),
        composing: TextRange.empty,
      );
    }
    // Also check for match
    _checkSessionMatch();
  }

  // ✅ LOGIC: Scan Hive for matching Name + Email + Country
  void _checkSessionMatch() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final country = _countryController.text.trim();

    if (name.isEmpty || email.isEmpty || country.isEmpty) {
      if (_canResume) setState(() => _canResume = false);
      return;
    }

    final activeSessions = HiveService.getActiveSessions();
    try {
      final match = activeSessions.firstWhere(
        (s) => s.clientName.toLowerCase() == name.toLowerCase() &&
               s.email.toLowerCase() == email.toLowerCase() &&
               s.country.toLowerCase() == country.toLowerCase()
      );
      
      if (!_canResume) {
        setState(() {
          _canResume = true;
          _matchedSession = match;
        });
      }
    } catch (e) {
      if (_canResume) {
        setState(() {
          _canResume = false;
          _matchedSession = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final isCountryValid = _countryController.text.isNotEmpty;

    setState(() {
      _countryError = !isCountryValid ? "Please select a country" : null;
    });

    if (isFormValid && isCountryValid) {
      // ✅ IF MATCH FOUND: Jump directly
      if (_canResume && _matchedSession != null) {
        // Show loading simulation for UX
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
        
        await Future.delayed(const Duration(milliseconds: 800)); // Small delay for UX
        if (mounted) {
          Navigator.pop(context); // Close loader
          ToastService.showSuccess(
            context,
            title: "Welcome Back",
            message: "Resumed session for ${_matchedSession!.clientName}",
          );
          context.goNamed('image-prep', extra: _matchedSession);
        }
      } 
      // ❌ ELSE: Create New
      else {
        context.read<OnboardingBloc>().add(
          StartSessionPressed(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            country: _countryController.text.trim(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingSuccess) {
          ToastService.showSuccess(
            context,
            title: "Success",
            message: "Session started successfully!",
          );
          context.goNamed('image-prep', extra: state.session);
        }
      },
      child: Container(
        color: AppColors.backgroundDark,
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 46),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Client intake",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const SessionHistoryDialog(),
                            );
                          },
                          tooltip: "View History (24h)",
                          icon: const Icon(Icons.history, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please enter the client details to start a new session",
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF687890),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Inputs (Name, Email, Country - Unchanged UI)
                    _buildLabel("Name"),
                    const Gap(8),
                    TextFieldWidget(
                      label: 'eg Jane Doe ',
                      prefixicon: 'assets/Icons/user-mini.svg',
                      autofocus: false,
                      controller: _nameController,
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a client name' : null,
                    ),
                    const SizedBox(height: 5),

                    _buildLabel("Email"),
                    const Gap(8),
                    TextFieldWidget(
                      label: "e.g Jane@example.com",
                      prefixicon: 'assets/Icons/envelope-solid.svg',
                      autofocus: false,
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter an email';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 2),

                    _buildLabel("Country"),
                    const Gap(8),
                    CustomLabeledDropdownTrigger(
                      hintText: "Select a country",
                      prefixIcon: Icons.public,
                      controller: _countryController,
                    ),
                    if (_countryError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 12),
                        child: Text(_countryError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),

                    const SizedBox(height: 32),

                    // ==== SUBMIT BUTTON (DYNAMIC TEXT) ====
                    Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<OnboardingBloc, OnboardingState>(
                            builder: (context, state) {
                              final bool isLoading = state is OnboardingLoading;
                              
                              // ✅ Dynamic Button Text Logic
                              String buttonTitle = "Start session";
                              if (isLoading) {
                                buttonTitle = "Starting session...";
                              } else if (_canResume) {
                                buttonTitle = "Jump back in"; // ✨ Dynamic change
                              }

                              return Opacity(
                                opacity: isLoading ? 0.6 : 1.0,
                                child: GlobalSubmitButtonWidget(
                                  title: buttonTitle,
                                  onPressed: isLoading ? () {} : _submitForm,
                                  // Change icon if resuming
                                  icon: _canResume ? 'assets/Icons/arrow_right.svg' : 'assets/Icons/chevron.svg', 
                                  // Fallback icon if you don't have arrow_right: just keep chevron
                                  svgColor: isLoading ? Colors.white : Colors.white38,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showIntakeHelpDialog(context),
                        child: Text(
                          "Need help?",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF687890),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper for consistent labels
  Widget _buildLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
        children: const [TextSpan(text: ' *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))],
      ),
    );
  }

  // Help Dialog (Unchanged)
  void _showIntakeHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.all(24),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.all(24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.tips_and_updates, color: Colors.blueAccent, size: 20),
              ),
              const Gap(12),
              Text("Intake Guide", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpStep(number: "1", title: "Client Details", description: "Fill in the client's name, email, and location."),
                const Gap(24),
                _buildHelpStep(number: "2", title: "Start Session", description: "Click 'Start Session' to proceed to image upload."),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text("Got it", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpStep({required String number, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24, alignment: Alignment.center, margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.5))),
          child: Text(number, style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              const Gap(4),
              Text(description, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}