/**
 * Iris Engine — FFI C wrappers for Dart.
 *
 * Implements the C API in iris_engine_ffi.h by calling the C++ engine.
 * IRIS_ENGINE_DLL_EXPORT is set by CMake for this target.
 */
#include "iris_engine_ffi.h"
#include "iris_engine.h"
#include "iris_cut.h"
#include <cstdint>
#include <cstdlib>
#include <cstring>

static uint8_t grayscale_byte(uint8_t r, uint8_t g, uint8_t b) {
  // Rec. 601 luma
  int y = (77 * r + 150 * g + 29 * b) >> 8;
  if (y < 0) return 0;
  if (y > 255) return 255;
  return static_cast<uint8_t>(y);
}

extern "C" {

IRIS_FFI_API int iris_engine_grayscale(uint8_t* rgba, int width, int height) {
  if (!rgba || width <= 0 || height <= 0) return 0;
  size_t n = static_cast<size_t>(width) * static_cast<size_t>(height) * 4;
  for (size_t i = 0; i < n; i += 4) {
    uint8_t g = grayscale_byte(rgba[i], rgba[i + 1], rgba[i + 2]);
    rgba[i] = rgba[i + 1] = rgba[i + 2] = g;
  }
  return 1;
}

IRIS_FFI_API IrisEngineHandle iris_engine_create(void) {
  return static_cast<IrisEngineHandle>(iris::iris_object_create());
}

IRIS_FFI_API void iris_engine_destroy(IrisEngineHandle handle) {
  iris::iris_object_destroy(static_cast<iris::IrisObject*>(handle));
}

IRIS_FFI_API int iris_engine_load_rgba(IrisEngineHandle handle,
                                       const uint8_t* rgba,
                                       int width,
                                       int height) {
  auto* obj = static_cast<iris::IrisObject*>(handle);
  if (!obj || !rgba) return 0;
  return obj->load_from_rgba(rgba, width, height) ? 1 : 0;
}

IRIS_FFI_API int iris_engine_get_rgba(IrisEngineHandle handle,
                                      uint8_t* out_rgba,
                                      int width,
                                      int height) {
  auto* obj = static_cast<iris::IrisObject*>(handle);
  if (!obj || !out_rgba) return 0;
  std::vector<uint8_t> vec;
  if (!obj->get_rgba(vec)) return 0;
  size_t expect = static_cast<size_t>(width) * static_cast<size_t>(height) * 4;
  if (vec.size() != expect) return 0;
  std::memcpy(out_rgba, vec.data(), expect);
  return 1;
}

IRIS_FFI_API void iris_engine_free(void* ptr) {
  std::free(ptr);
}

IRIS_FFI_API int iris_engine_cut_iris(IrisEngineHandle handle) {
  auto* obj = static_cast<iris::IrisObject*>(handle);
  if (!obj) return 0;
  return obj->cut_iris_to_alpha(1.0f) ? 1 : 0;
}

IRIS_FFI_API int iris_engine_remove_flash(IrisEngineHandle handle,
                                          float brightness_threshold,
                                          int dilate_pixels) {
  auto* obj = static_cast<iris::IrisObject*>(handle);
  if (!obj) return 0;
  iris::FlashRemovalParams params;
  params.brightness_threshold = brightness_threshold;
  params.dilate_pixels = dilate_pixels;
  return obj->remove_flash(params) ? 1 : 0;
}

IRIS_FFI_API int iris_engine_apply_effects(IrisEngineHandle handle,
                                           float vibrance,
                                           float gamma,
                                           float sharpness,
                                           float clarity) {
  auto* obj = static_cast<iris::IrisObject*>(handle);
  if (!obj) return 0;
  iris::EffectParams params;
  params.vibrance = vibrance;
  params.gamma = gamma <= 0.01f ? 1.0f : gamma;
  params.sharpness = sharpness;
  params.clarity = clarity;
  return obj->apply_effect_params(params) ? 1 : 0;
}

IRIS_FFI_API int iris_engine_has_opencv(void) {
#if defined(IRIS_ENGINE_OPENCV_AVAILABLE)
  return 1;
#else
  return 0;
#endif
}

IRIS_FFI_API int iris_engine_process_iris_cut(
  const char* image_path_utf8,
  double iris_cx, double iris_cy, double iris_r,
  double pupil_cx, double pupil_cy, double pupil_r,
  uint8_t** out_rgba,
  int32_t* out_width,
  int32_t* out_height
) {
  if (!image_path_utf8 || !out_rgba || !out_width || !out_height) return 0;
  return iris::process_iris_cut(
    image_path_utf8,
    iris_cx, iris_cy, iris_r,
    pupil_cx, pupil_cy, pupil_r,
    out_rgba, out_width, out_height
  ) ? 1 : 0;
}

IRIS_FFI_API int iris_engine_process_iris_cut_from_view(
  const char* image_path_utf8,
  double view_w, double view_h,
  double outer_r, double inner_r,
  double outer_dx, double outer_dy,
  double inner_dx, double inner_dy,
  uint8_t** out_rgba,
  int32_t* out_width,
  int32_t* out_height
) {
  if (!image_path_utf8 || !out_rgba || !out_width || !out_height) return 0;
  return iris::process_iris_cut_from_view(
    image_path_utf8,
    view_w, view_h,
    outer_r, inner_r,
    outer_dx, outer_dy, inner_dx, inner_dy,
    out_rgba, out_width, out_height
  ) ? 1 : 0;
}

}  // extern "C"
