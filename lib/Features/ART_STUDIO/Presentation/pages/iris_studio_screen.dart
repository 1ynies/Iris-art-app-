import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// ✅ ONE PACKAGE FOR ALL PLATFORMS
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; 

import 'package:iris_designer/Core/Config/Theme.dart';
import 'package:iris_designer/Core/Shared/Widgets/global_custom_navbar.dart';
import 'package:iris_designer/Core/Utils/toast_service.dart';
import 'package:iris_designer/Features/ART_STUDIO/Presentation/views/case1_view.dart';
import 'package:iris_designer/Features/ART_STUDIO/Presentation/views/case2_view.dart';
import 'package:iris_designer/Features/ART_STUDIO/Presentation/views/case3_view.dart';
import 'package:iris_designer/Features/ART_STUDIO/Presentation/views/case4_view.dart';
import 'package:iris_designer/Features/ART_STUDIO/Presentation/views/case5_view.dart';
import 'package:iris_designer/Features/ART_STUDIO/Presentation/views/case6_view.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ArtStudioScreen extends StatefulWidget {
  final ClientSession session;
  final List<String> irisImages;

  const ArtStudioScreen({super.key, required this.irisImages, required this.session});

  @override
  State<ArtStudioScreen> createState() => _ArtStudioScreenState();
}

class _ArtStudioScreenState extends State<ArtStudioScreen> {
  int _currentTabIndex = 0;
  Map<String, dynamic>? _generationConfig;

  void _switchToPhotopea(Map<String, dynamic> config) {
    setState(() {
      _generationConfig = config;
      _currentTabIndex = 1; // Switch to Preview Tab
    });
  }

  void _backToEditor() {
    setState(() => _currentTabIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      appBar: CustomNavBar(
        title: 'Iris Designer',
        onArrowPressed: () {
          if (_currentTabIndex == 1) {
            _backToEditor();
          } else {
            context.goNamed('image-prep-2', extra: {'session': widget.session, 'imageUrls': widget.irisImages});
          }
        },
        subtitle: widget.session.clientName,
        helpDialogNum: '5',
      ),
      body: Column(
        children: [
          _buildTabHeader(),
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: [
                // TAB 1: STUDIO EDITOR
                StudioEditorTab(
                  session: widget.session,
                  irisImages: widget.irisImages,
                  onGenerateRequest: _switchToPhotopea,
                ),
                // TAB 2: UNIFIED PREVIEW (Windows/Mac/Linux)
                _generationConfig != null
                    ? PhotopeaPreviewTab(config: _generationConfig!, onReset: _backToEditor)
                    : const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader() {
    return Container(
      height: 60,
      width: double.infinity,
      color: const Color(0xFF161B22),
      child: Center(
        child: Container(
          width: 300,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1116),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              _buildTabBtn("Studio", 0),
              _buildTabBtn("Preview & Print", 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBtn(String label, int index) {
    final bool isActive = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 1 && _generationConfig == null) {
            ToastService.showError(context, title: "Action Required", message: "Please configure your art first.");
            return;
          }
          setState(() => _currentTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 1: STUDIO EDITOR (Logic Unchanged)
// ============================================================================
class StudioEditorTab extends StatefulWidget {
  final ClientSession session;
  final List<String> irisImages;
  final Function(Map<String, dynamic>) onGenerateRequest;

  const StudioEditorTab({super.key, required this.session, required this.irisImages, required this.onGenerateRequest});

  @override
  State<StudioEditorTab> createState() => _StudioEditorTabState();
}

class _StudioEditorTabState extends State<StudioEditorTab> {
  String selectedEffect = 'Pure';
  String? selectedSize;
  String? selectedAlignment;

  final List<Map<String, dynamic>> soloEffects = [
    {'name': 'Pure', 'color': Colors.blue}, {'name': 'Halo', 'color': Colors.amber},
    {'name': 'Dust', 'color': Colors.grey}, {'name': 'Sun', 'color': Colors.orange},
    {'name': 'Explosion', 'color': Colors.red},
  ];
  final List<String> sizesSquare = ['20x20', '30x30', '40x40'];
  final List<String> sizesRow = ['40x20', '60x20', '80x20', '100x20', '90x30', '120x30', '80x40', '120x40'];
  final List<String> sizesCol = ['20x40', '20x60', '20x80', '20x100', '30x90', '30x120', '40x80', '40x120'];
  final List<String> sizesRect = ['A4 (20x30)'];

  @override
  void initState() {
    super.initState();
    if (widget.irisImages.length == 1) selectedAlignment = 'Square';
    if (widget.irisImages.length == 2) selectedAlignment = 'Row';
  }

  void _handleShowPressed() async {
    List<String> base64Images = [];
    for (String path in widget.irisImages) {
      File file = File(path);
      if (await file.exists()) {
        List<int> bytes = await file.readAsBytes();
        base64Images.add(base64Encode(bytes));
      }
    }

    String safeEffect = selectedEffect.replaceAll(" ", "");
    String safeSize = selectedSize!.split(" ").first;
    String filename = "${safeEffect}_${safeSize}_${selectedAlignment ?? 'Square'}".toLowerCase();

    widget.onGenerateRequest({
      "images": base64Images,
      "templateName": filename,
      "effect": selectedEffect,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 220,
          decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white10))),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemCount: soloEffects.length,
            separatorBuilder: (_, __) => const Gap(16),
            itemBuilder: (context, index) {
              final effect = soloEffects[index];
              final bool isSelected = selectedEffect == effect['name'];
              return GestureDetector(
                onTap: () => setState(() => selectedEffect = effect['name']),
                child: Column(
                  children: [
                    Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        color: effect['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : null,
                      ),
                      child: Icon(Icons.blur_on, color: effect['color'], size: 40),
                    ),
                    const Gap(8),
                    Text(effect['name'].toUpperCase(), style: GoogleFonts.poppins(color: isSelected ? Colors.blueAccent : Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Padding(padding: const EdgeInsets.all(40), child: Center(child: _buildCorrectLayoutView())),
              Positioned(
                bottom: 32, right: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.irisImages.length == 2) ...[
                      _buildDropdown("Alignment", selectedAlignment, ['Row', 'Column', 'Square'], (v) => setState(() => selectedAlignment = v)),
                      const Gap(12),
                    ],
                    _buildDropdown("Sizes", selectedSize, _getAvailableSizes(), (v) => setState(() => selectedSize = v)),
                    const Gap(12),
                    ElevatedButton(
                      onPressed: selectedSize != null ? _handleShowPressed : null,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, fixedSize: const Size(160, 50)),
                      child: const Text("Show", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCorrectLayoutView() {
    switch (widget.irisImages.length) {
      case 1: return Case1View(effect: selectedEffect, images: widget.irisImages);
      case 2: return Case2View(effect: selectedEffect, images: widget.irisImages, duoEffects: [], onEffectSelected: (v){});
      default: return const Text("Select Layout", style: TextStyle(color: Colors.white));
    }
  }

  List<String> _getAvailableSizes() => widget.irisImages.length == 1 ? sizesSquare : sizesRow;

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Container(
      height: 50, width: 160, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, hint: Text(label, style: const TextStyle(color: Colors.grey)), dropdownColor: const Color(0xFF1E293B),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 2: PREVIEW (All Platforms Unified)
// ============================================================================
class PhotopeaPreviewTab extends StatefulWidget {
  final Map<String, dynamic> config;
  final VoidCallback onReset;

  const PhotopeaPreviewTab({
    super.key,
    required this.config,
    required this.onReset,
  });

  @override
  State<PhotopeaPreviewTab> createState() => _PhotopeaPreviewTabState();
}

class _PhotopeaPreviewTabState extends State<PhotopeaPreviewTab> {
  InAppWebViewController? webViewController;
  bool isProcessing = true;
  
  // URL Construction (Shared logic)
  String _buildPhotopeaUrl() {
    Map<String, dynamic> photopeaData = {
      "files": widget.config['images'].map((b64) => "data:image/png;base64,$b64").toList(),
      "environment": {
        "vmode": 2,
        "intro": false,
        "theme": 2,
        "bg": "0F1116",
        "customMenu": []
      },
      "script": "app.echoToOE('Init');"
    };
    return "https://www.photopea.com#${jsonEncode(photopeaData)}";
  }

  @override
  Widget build(BuildContext context) {
    // 🐧 LINUX FALLBACK: Stop here if Linux!
    if (!kIsWeb && Platform.isLinux) {
      return _buildLinuxFallback();
    }

    // 🪟 WINDOWS & MAC: Continue with Embedded WebView
    return Stack(
      children: [
        InAppWebView(
          initialSettings: InAppWebViewSettings(
            isInspectable: kDebugMode,
            transparentBackground: true,
          ),
          onWebViewCreated: (controller) async {
            webViewController = controller;
            controller.addJavaScriptHandler(handlerName: 'ProcessingComplete', callback: (args) {
              if (mounted) {
                setState(() => isProcessing = false);
                _showCompletionDialog();
              }
            });

            String url = _buildPhotopeaUrl();
            await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
            
            // Auto-check timeout for UX
            Future.delayed(const Duration(seconds: 8), () {
               if (mounted && isProcessing) setState(() => isProcessing = false);
            });
          },
        ),

        if (isProcessing) _buildLoadingOverlay(),
      ],
    );
  }

  // 🐧 The Linux UI Widget
  Widget _buildLinuxFallback() {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.web_asset_off, size: 50, color: Colors.orangeAccent),
            const Gap(20),
            Text(
              "External Editor Required",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Gap(12),
            Text(
              "Embedded design tools are currently limited on Linux. Please open the studio in your browser.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
            const Gap(30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text("Open in Browser"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final Uri url = Uri.parse(_buildPhotopeaUrl());
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    debugPrint("Could not launch $url");
                  }
                },
              ),
            ),
            const Gap(16),
            TextButton(
              onPressed: widget.onReset, // Go back to Tab 1
              child: const Text("Back to Settings", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for loading state (Win/Mac)
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.blueAccent),
              const Gap(24),
              Text("Designing Art...", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an action
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 60),
              const Gap(20),
              Text(
                "Masterpiece Ready",
                style: GoogleFonts.poppins(
                  color: Colors.white, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const Gap(10),
              Text(
                "The iris replacement is complete. You can now tweak the design or export it for printing.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              const Gap(30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                       Navigator.pop(ctx); // Close dialog, stay in editor
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white, 
                      side: const BorderSide(color: Colors.white30)
                    ),
                    child: const Text("Edit Manually"),
                  ),
                  const Gap(16),
                  ElevatedButton(
                    onPressed: () {
                      // 1. Trigger the download script in Photopea
                      webViewController?.evaluateJavascript(source: "app.activeDocument.saveToOE('png');");
                      // 2. Close the dialog
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, // Use your AppColors.primaryBlue
                      foregroundColor: Colors.white
                    ),
                    child: const Text("Download / Print"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}