/**
 * Iris Engine — C API for Dart FFI (2026)
 *
 * All symbols use extern "C" for predictable names and no C++ name mangling.
 * Pass image data as raw pointers + dimensions (no disk round-trip).
 *
 * Memory contract:
 * - Input buffers are read-only; ownership stays with Dart.
 * - Output buffers are allocated by the engine; caller must call iris_engine_free().
 */

#ifndef IRIS_ENGINE_FFI_H
#define IRIS_ENGINE_FFI_H

#include <stdint.h>

#ifdef _WIN32
  #ifdef IRIS_ENGINE_DLL_EXPORT
    #define IRIS_FFI_API __declspec(dllexport)
  #else
    #define IRIS_FFI_API __declspec(dllimport)
  #endif
#else
  #define IRIS_FFI_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/** Opaque handle to an IrisObject. */
typedef void* IrisEngineHandle;

/**
 * Step 1 — Grayscale proof of concept.
 * Takes RGBA bytes, writes grayscale RGB back into the same buffer (R=G=B, A unchanged).
 * Returns 1 on success, 0 on failure.
 *
 * Layout: row-major RGBA, size = width * height * 4.
 */
IRIS_FFI_API int iris_engine_grayscale(
  uint8_t* rgba,
  int width,
  int height
);

/**
 * Create/destroy engine object (for future Phase 2–5).
 */
IRIS_FFI_API IrisEngineHandle iris_engine_create(void);
IRIS_FFI_API void iris_engine_destroy(IrisEngineHandle handle);

/**
 * Load image from raw RGBA. Returns 1 on success, 0 on failure.
 */
IRIS_FFI_API int iris_engine_load_rgba(
  IrisEngineHandle handle,
  const uint8_t* rgba,
  int width,
  int height
);

/**
 * Write current image to preallocated RGBA buffer.
 * Buffer must be at least width*height*4 bytes.
 * Returns 1 on success, 0 on failure.
 */
IRIS_FFI_API int iris_engine_get_rgba(
  IrisEngineHandle handle,
  uint8_t* out_rgba,
  int width,
  int height
);

/**
 * Free a buffer returned by the engine (for APIs that allocate).
 */
IRIS_FFI_API void iris_engine_free(void* ptr);

/**
 * Phase 2: Detect iris/pupil (Hough) and set alpha to 0 outside iris.
 * Requires loaded image (iris_engine_load_rgba). Returns 1 on success, 0 if not implemented or failure.
 */
IRIS_FFI_API int iris_engine_cut_iris(IrisEngineHandle handle);

/**
 * Phase 3: Remove flash/specular (L>threshold mask, dilate, inpaint).
 * threshold: 0..1 (e.g. 0.95). dilate_px: 2–3.
 */
IRIS_FFI_API int iris_engine_remove_flash(
  IrisEngineHandle handle,
  float brightness_threshold,
  int dilate_pixels
);

/**
 * Phase 4: Apply vibrance, gamma, sharpness, clarity.
 * Slider-style: vibrance/gamma in ~0..2 (1=no change); sharpness/clarity in 0..4.
 */
IRIS_FFI_API int iris_engine_apply_effects(
  IrisEngineHandle handle,
  float vibrance,
  float gamma,
  float sharpness,
  float clarity
);

/**
 * Returns 1 if the engine was built with OpenCV support, otherwise 0.
 */
IRIS_FFI_API int iris_engine_has_opencv(void);

/**
 * Phase 1: Circling & cutting with user-defined circles and 50% pupil shrink.
 * Radial stretch: [pupil_r, iris_r] -> [0.5*pupil_r, iris_r]; circular alpha; crop to iris box.
 * Allocates *out_rgba (caller must iris_engine_free). Returns 1 on success, 0 on failure.
 */
IRIS_FFI_API int iris_engine_process_iris_cut(
  const char* image_path_utf8,
  double iris_cx, double iris_cy, double iris_r,
  double pupil_cx, double pupil_cy, double pupil_r,
  uint8_t** out_rgba,
  int32_t* out_width,
  int32_t* out_height
);

/**
 * Same as iris_engine_process_iris_cut but takes view-space params.
 * view_w, view_h = layout size; outer_r, inner_r in [0,1]; *_dx, *_dy = normalized center offset.
 */
IRIS_FFI_API int iris_engine_process_iris_cut_from_view(
  const char* image_path_utf8,
  double view_w, double view_h,
  double outer_r, double inner_r,
  double outer_dx, double outer_dy,
  double inner_dx, double inner_dy,
  uint8_t** out_rgba,
  int32_t* out_width,
  int32_t* out_height
);

#ifdef __cplusplus
}
#endif

#endif  // IRIS_ENGINE_FFI_H
