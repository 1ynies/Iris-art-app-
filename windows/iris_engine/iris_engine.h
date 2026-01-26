/**
 * Iris Engine — Native C++ API (2026)
 *
 * Flutter provides the UI; this engine provides:
 * - Iris/pupil detection and cutting (Hough circles + alpha mask)
 * - Flash removal (inpainting)
 * - Color/clarity/presets (CLAHE, LAB, JSON-driven)
 * - Print-accurate export (DPI, physical size, CMYK via LittleCMS)
 *
 * Include this header when implementing engine logic.
 * For Dart FFI, use the C API in iris_engine_ffi.h instead.
 */

#ifndef IRIS_ENGINE_H
#define IRIS_ENGINE_H

#include <cstdint>
#include <cstddef>
#include <vector>
#include <string>

#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/photo.hpp>

namespace iris {

// ---- Circle detection result (pupil / iris) ----
struct CircleResult {
  float center_x;
  float center_y;
  float radius;
  bool valid;
};

// ---- Effect preset (JSON-driven, Phase 4) ----
struct EffectParams {
  float vibrance;   // Saturation shift in LAB (e.g. -1..1)
  float gamma;      // Mid-tone brightness (e.g. 0.8..1.2)
  float sharpness;  // Unsharp masking strength (e.g. 0..2)
  float clarity;    // CLAHE clip limit (e.g. 1..4)
};

// ---- Flash removal params (Phase 3) ----
struct FlashRemovalParams {
  float brightness_threshold;  // L-channel threshold (e.g. 0.95)
  int dilate_pixels;           // Mask dilation, e.g. 2–3
};

// ---- Export params (Phase 5) ----
struct ExportParams {
  int dpi;           // 300 or 600
  float width_cm;    // Physical width in cm (e.g. 20.0)
  bool to_cmyk;      // Use LittleCMS for CMYK conversion
};

/**
 * IrisObject holds the in-memory image, mask, and parameters.
 * Implement as a C++ class; FFI exposes it as an opaque handle.
 */
class IrisObject {
 public:
  IrisObject();
  ~IrisObject();

  // Buffer layout: RGBA, row-major, width * height * 4 bytes
  bool load_from_rgba(const uint8_t* data, int width, int height);
  bool get_rgba(std::vector<uint8_t>& out) const;

  // Phase 2: Iris & pupil circles (Hough + alpha cut)
  bool detect_iris_and_pupil(CircleResult& iris, CircleResult& pupil);
  bool cut_iris_to_alpha(float iris_radius_scale = 1.0f);

  // Phase 3: Flash removal (damage mask + inpaint)
  bool remove_flash(const FlashRemovalParams& params);

  // Phase 4: Color / clarity / presets
  bool apply_effect_params(const EffectParams& params);
  bool apply_clarity(float clip_limit);

  // Phase 5: Export
  bool export_to_file(const char* path, const ExportParams& params) const;

  int width() const { return width_; }
  int height() const { return height_; }

 private:
  int width_ = 0;
  int height_ = 0;
  std::vector<uint8_t> rgba_;
  std::vector<uint8_t> alpha_mask_;  // 1 channel, same size
  CircleResult iris_circle_;
  CircleResult pupil_circle_;

};

/**
 * Standalone functions for use by the FFI layer.
 * These allocate/free IrisObject and wrap the methods.
 */
IrisObject* iris_object_create();
void iris_object_destroy(IrisObject* obj);

}  // namespace iris

#endif  // IRIS_ENGINE_H
