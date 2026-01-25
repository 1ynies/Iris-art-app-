import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PhotopeaService {
  static final PhotopeaService _instance = PhotopeaService._internal();
  factory PhotopeaService() => _instance;
  PhotopeaService._internal();

  // --- ENGINE CONFIG ---
  static const String photopeaBaseUrl = 'https://www.photopea.com';
  
  // Cleanest possible environment for background processing
  static const String photopeaConfig = '{"environment":{"showpanels":false,"showtools":false,"showinfo":false,"showtop":false,"showmenu":false,"showfooter":false,"v_menu":false,"v_top":false}}';
  
  static String get photopeaUrl => '$photopeaBaseUrl#$photopeaConfig';

  InAppWebViewController? _webViewController;
  Function(String base64Data)? onSaveResult;
  
  bool _isReady = false;
  bool _exportListenerReady = false;
  final List<String> _commandQueue = [];
  Completer<void>? _readyCompleter;

  bool get isReady => _isReady;

  void setController(InAppWebViewController controller) {
    _webViewController = controller;
    _isReady = false; 
    _commandQueue.clear();
    _readyCompleter = Completer<void>();
    debugPrint("🔌 PHOTOPEA SERVICE: Controller attached.");
    
    _setupExportListener();
  }

  void setReady() {
    if (_isReady) return;
    
    // Give it a tiny bit more time for 'app' to initialize globally
    Future.delayed(const Duration(milliseconds: 1000), () {
      _isReady = true;
      debugPrint("✅ PHOTOPEA SERVICE: Engine Ready! Flushing ${_commandQueue.length} commands.");
      
      // Ensure export listener is set up after Photopea is ready
      _setupExportListener();
      
      for (var script in _commandQueue) {
        _webViewController?.evaluateJavascript(source: script);
      }
      _commandQueue.clear();
      
      if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
        _readyCompleter!.complete();
      }
    });
  }

  Future<void> _waitUntilReady() async {
    if (_isReady) return;
    if (_readyCompleter != null) {
      await _readyCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint("⚠️ PHOTOPEA SERVICE: Timeout waiting for ready state");
        },
      );
    }
  }

  Future<void> _setupExportListener() async {
    final script = """
      (function() {
        if (window.flutterExportListenerSetup) {
          console.log('FLUTTER_EXPORT_LISTENER_ALREADY_SETUP');
          return;
        }
        
        console.log('FLUTTER_SETTING_UP_EXPORT_LISTENER');
        
        // ✅ Listen for ArrayBuffer from Photopea's saveToOE
        // Photopea sends ArrayBuffer via postMessage when saveToOE is called
        var messageHandler = function(e) {
          try {
            // Log ALL messages to debug
            var dataType = typeof e.data;
            var isArrayBuffer = e.data instanceof ArrayBuffer;
            var isString = typeof e.data === 'string';
            var isUint8Array = e.data instanceof Uint8Array;
            var dataLength = 'N/A';
            
            if (isArrayBuffer) {
              dataLength = e.data.byteLength;
            } else if (isUint8Array) {
              dataLength = e.data.length;
            } else if (isString) {
              dataLength = e.data.length;
            }
            
            console.log('FLUTTER_MESSAGE_RECEIVED: type=' + dataType + ', isArrayBuffer=' + isArrayBuffer + ', isUint8Array=' + isUint8Array + ', length=' + dataLength);
            
            // Handle ArrayBuffer (from saveToOE)
            if (isArrayBuffer && e.data.byteLength > 100) {
              console.log("PHOTOPEA_DATA_RECEIVED: " + e.data.byteLength + " bytes");
              
              // Fast conversion for large images
              var blob = new Blob([e.data], {type: 'image/png'});
              var reader = new FileReader();
              reader.onloadend = function() {
                var base64 = reader.result.split(',')[1];
                // Send full base64 data to Flutter (Flutter will filter it from console output)
                console.log("FLUTTER_IMAGE_DATA:" + base64);
              };
              reader.onerror = function(err) {
                console.log('FLUTTER_READER_ERROR: ' + err);
              };
              reader.readAsDataURL(blob);
              return; // Don't process further
            }
            
            // Handle Uint8Array (sometimes Photopea sends this instead)
            if (isUint8Array && e.data.length > 100) {
              console.log("PHOTOPEA_DATA_RECEIVED_UINT8: " + e.data.length + " bytes");
              var arrayBuffer = e.data.buffer;
              var blob = new Blob([arrayBuffer], {type: 'image/png'});
              var reader = new FileReader();
              reader.onloadend = function() {
                var base64 = reader.result.split(',')[1];
                console.log("FLUTTER_IMAGE_DATA:" + base64);
              };
              reader.readAsDataURL(blob);
              return;
            }
            
            // Handle string messages
            if (isString) {
              if (e.data === 'done') {
                console.log('PHOTOPEA_OPERATION_DONE');
              } else if (e.data.startsWith('data:image')) {
                // Direct base64 data URL
                var base64 = e.data.split(',')[1];
                console.log("FLUTTER_IMAGE_DATA:" + base64);
              }
            }
          } catch(err) {
            console.log('FLUTTER_MESSAGE_HANDLER_ERROR: ' + err.message);
          }
        };
        
        // Listen on window (main target for postMessage)
        window.addEventListener("message", messageHandler, false);
        
        // Also listen on self (in case Photopea uses self.postMessage)
        if (typeof self !== 'undefined' && self !== window) {
          self.addEventListener("message", messageHandler, false);
        }
        
        // Also try parent if we're in an iframe context
        if (window.parent && window.parent !== window) {
          window.parent.addEventListener("message", messageHandler, false);
        }
        
        window.flutterExportListenerSetup = true;
        console.log('FLUTTER_EXPORT_LISTENER_READY');
      })();
    """;
    
    await Future.delayed(const Duration(milliseconds: 500));
    _webViewController?.evaluateJavascript(source: script);
  }

  Future<void> _sendScript(String script) async {
    if (_webViewController == null) {
      debugPrint("❌ PHOTOPEA SERVICE: No controller available");
      return;
    }

    // Escape the script properly for JavaScript template literal (backticks)
    // Escape backticks, backslashes, and dollar signs
    final escapedScript = script
        .replaceAll('\\', '\\\\')  // Escape backslashes first
        .replaceAll('`', '\\`')    // Escape backticks
        .replaceAll('\$', '\\\$'); // Escape dollar signs
    // Note: template literals preserve newlines, so we don't need to escape \n
    
    // Execute script directly - use template literal for safe embedding
    final executionScript = """
      (function() {
        try {
          console.log('PHOTOPEA_SCRIPT_STARTING');
          
          // Get the script as a string using template literal
          var scriptToExecute = `$escapedScript`;
          console.log('PHOTOPEA_SCRIPT_LOADED: ' + scriptToExecute.substring(0, 50) + '...');
          
          // Check app availability first
          if (typeof app === 'undefined') {
            console.log('PHOTOPEA_ERROR: app undefined, trying postMessage');
            // Send script via postMessage for Photopea to execute
            window.postMessage(scriptToExecute, "*");
            console.log('PHOTOPEA_POSTMESSAGE_SENT');
          } else {
            console.log('PHOTOPEA_APP_AVAILABLE, executing directly...');
            // Execute directly in Photopea's context
            eval(scriptToExecute);
            console.log('PHOTOPEA_SCRIPT_EXECUTED_SUCCESS');
          }
        } catch(e) {
          console.log('PHOTOPEA_EXECUTION_ERROR: ' + e.message);
          console.log('PHOTOPEA_STACK: ' + (e.stack || 'no stack'));
          // Try postMessage as fallback
          try {
            var scriptToExecute = `$escapedScript`;
            window.postMessage(scriptToExecute, "*");
            console.log('PHOTOPEA_FALLBACK_POSTMESSAGE_SENT');
          } catch(e2) {
            console.log('PHOTOPEA_FALLBACK_ERROR: ' + e2.message);
          }
        }
      })();
    """;

    if (_isReady) {
      try {
        await _webViewController!.evaluateJavascript(source: executionScript);
        debugPrint("📤 PHOTOPEA: Script execution attempted");
      } catch (e) {
        debugPrint("❌ PHOTOPEA: Script evaluate error: $e");
      }
    } else {
      debugPrint("⏳ PHOTOPEA SERVICE: Engine not ready, queuing script");
      _commandQueue.add(executionScript);
    }
  }

  Future<void> loadImage(String filePath) async {
    try {
      await _waitUntilReady();
      
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint("❌ Error: File does not exist: $filePath");
        return;
      }
      
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // Sending an ArrayBuffer via postMessage is the official way to open files in Photopea
      final script = """
        (function() {
          try {
            var base64 = '$base64String';
            var binary = atob(base64);
            var len = binary.length;
            var bytes = new Uint8Array(len);
            for (var i = 0; i < len; i++) {
              bytes[i] = binary.charCodeAt(i);
            }
            window.postMessage(bytes.buffer, "*");
            console.log('PHOTOPEA_IMAGE_SENT_AS_BUFFER');
          } catch(e) {
            console.log('PHOTOPEA_LOAD_ERROR: ' + e.message);
          }
        })();
      """;
      
      await _webViewController!.evaluateJavascript(source: script);
      debugPrint("📤 Image sent to Photopea as ArrayBuffer (${bytes.lengthInBytes} bytes)");
    } catch (e) {
      debugPrint("❌ Error loading image: $e");
    }
  }

  Future<void> applyCircling({
    required double x,
    required double y,
    required double width,
    required double height
  }) async {
    await _waitUntilReady();
    
    debugPrint("🔵 Applying circling: x=$x, y=$y, w=$width, h=$height");
    
    // Improved circling script - ensure edits are committed
    final script = """
      (function() {
        try {
          console.log('PHOTOPEA_CIRCLING_START');
          var doc = app.activeDocument;
          if (!doc) {
            console.log('PHOTOPEA_ERROR: No active document');
            return;
          }
          
          var w = doc.width; 
          var h = doc.height;
          console.log('PHOTOPEA_DOC_SIZE: ' + w + 'x' + h);
          
          // Calculate coordinates
          var centerX = ($x + $width / 2) * w;
          var centerY = ($y + $height / 2) * h;
          var radiusX = ($width / 2) * w;
          var radiusY = ($height / 2) * h;
          var left = centerX - radiusX;
          var top = centerY - radiusY;
          var right = centerX + radiusX;
          var bottom = centerY + radiusY;
          
          console.log('PHOTOPEA_CIRCLE_COORDS: ' + left + ',' + top + ' to ' + right + ',' + bottom);
          
          // Ensure we're working with the active layer
          var activeLayer = doc.activeLayer;
          if (!activeLayer) {
            console.log('PHOTOPEA_WARNING: No active layer, using first layer');
            if (doc.layers.length > 0) {
              doc.activeLayer = doc.layers[0];
            }
          }
          
          // Make selection
          doc.selection.selectEllipse(top, left, bottom, right);
          console.log('PHOTOPEA_SELECTION_MADE');
          
          // Invert selection (select everything outside the circle)
          doc.selection.invert();
          console.log('PHOTOPEA_SELECTION_INVERTED');
          
          // Clear the selected area (delete pixels outside circle)
          doc.selection.clear();
          console.log('PHOTOPEA_SELECTION_CLEARED');
          
          // Deselect
          doc.selection.deselect();
          console.log('PHOTOPEA_SELECTION_DESELECTED');
          
          // Refresh to ensure changes are visible
          app.refresh();
          console.log('PHOTOPEA_REFRESHED');
          console.log('PHOTOPEA_CIRCLING_COMPLETE');
        } catch(e) {
          console.log('PHOTOPEA_CIRCLING_ERROR: ' + e.message);
          console.log('PHOTOPEA_CIRCLING_STACK: ' + (e.stack || 'no stack'));
        }
      })();
    """;
    
    await _sendScript(script);
    // Wait longer for the operation to complete
    await Future.delayed(const Duration(milliseconds: 1500));
  }

  Future<void> correctFlashAtPoints(List<Map<String, double>> points, double brushSize) async {
    if (points.isEmpty) return;
    await _waitUntilReady();
    
    final pointsScript = points.map((p) => 
      "doc.selection.selectEllipse((${p['y']}*h)-$brushSize, (${p['x']}*w)-$brushSize, (${p['y']}*h)+$brushSize, (${p['x']}*w)+$brushSize, 1);"
    ).join('');
    
    final script = """
      var doc = app.activeDocument;
      if (doc) {
        var w = doc.width; var h = doc.height;
        doc.selection.deselect();
        $pointsScript
        doc.activeLayer.applyMedianNoise(5);
        doc.selection.deselect();
      }
    """;
    
    await _sendScript(script);
  }

  Future<void> adjustColor({
    double brightness = 0,
    double contrast = 0,
    double saturation = 0,
    double hue = 0
  }) async {
    await _waitUntilReady();
    
    final script = """
      var doc = app.activeDocument;
      if (doc) {
        var layer = doc.activeLayer;
        layer.adjustBrightnessContrast($brightness, $contrast);
        layer.adjustHueSaturation($hue, $saturation, 0);
      }
    """;
    
    await _sendScript(script);
  }

  Future<void> exportImage() async {
    await _waitUntilReady();
    
    // Ensure export listener is set up and ready
    _setupExportListener();
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Give a moment for any pending operations to complete
    await Future.delayed(const Duration(milliseconds: 500));
    
    debugPrint("📤 Starting export...");
    
    // Simplified export: flatten document and use saveToOE
    // This ensures all edits are visible in the exported image
    final exportScript = """
      (function() {
        try {
          var doc = app.activeDocument;
          if (!doc) {
            console.log('PHOTOPEA_EXPORT_ERROR: No active document');
            return;
          }
          
          console.log('PHOTOPEA_EXPORT_STARTING: doc size ' + doc.width + 'x' + doc.height);
          console.log('PHOTOPEA_LAYER_COUNT: ' + doc.layers.length);
          
          // Flatten the document to ensure all edits are visible
          // This merges all layers into one
          try {
            doc.flatten();
            console.log('PHOTOPEA_DOCUMENT_FLATTENED');
          } catch(flattenErr) {
            console.log('PHOTOPEA_FLATTEN_WARNING: ' + flattenErr.message);
            // Continue even if flatten fails
          }
          
          // Refresh to ensure changes are visible
          app.refresh();
          console.log('PHOTOPEA_REFRESHED_BEFORE_EXPORT');
          
          // Wait a moment for refresh to complete, then export
          setTimeout(function() {
            try {
              // Use saveToOE - this sends ArrayBuffer via postMessage
              // According to Photopea API, this should send the image data
              doc.saveToOE('png');
              console.log('PHOTOPEA_SAVETOEO_CALLED');
            } catch(saveErr) {
              console.log('PHOTOPEA_SAVETOEO_ERROR: ' + saveErr.message);
              console.log('PHOTOPEA_SAVETOEO_STACK: ' + (saveErr.stack || 'no stack'));
            }
          }, 300);
          
        } catch(e) {
          console.log('PHOTOPEA_EXPORT_ERROR: ' + e.message + ' | ' + e.stack);
        }
      })();
    """;
    
    await _sendScript(exportScript);
    debugPrint("📤 Export command sent, waiting for ArrayBuffer response...");
  }
}

