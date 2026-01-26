/**
 * Phase 1: Circling & Cutting — Radial warp and alpha mask (2026).
 * User-defined iris/pupil circles, 50% pupil shrink via radial stretch.
 * Only built when IRIS_ENGINE_OPENCV_AVAILABLE.
 */

#ifndef IRIS_ENGINE_IRIS_CUT_H
#define IRIS_ENGINE_IRIS_CUT_H

#include <cstdint>
#include <cstddef>

namespace iris {

/**
 * Process iris cut with radial warp (pupil 50% smaller).
 * All coordinates and radii in image pixel space.
 * On success: *out_data = malloc'd RGBA (caller frees), *out_width/out_height set.
 * Returns true on success, false on failure.
 */
bool process_iris_cut(
  const char* image_path,
  double iris_cx, double iris_cy, double iris_r,
  double pupil_cx, double pupil_cy, double pupil_r,
  uint8_t** out_data, int* out_width, int* out_height
);

/**
 * Same as process_iris_cut but takes view-space params; converts to image space
 * using loaded image dimensions. view_w/h = layout size; outer_r/inner_r in [0,1];
 * outer_dx/dy, inner_dx/dy = normalized center offsets (fraction of view).
 */
bool process_iris_cut_from_view(
  const char* image_path,
  double view_w, double view_h,
  double outer_r, double inner_r,
  double outer_dx, double outer_dy,
  double inner_dx, double inner_dy,
  uint8_t** out_data, int* out_width, int* out_height
);

}  // namespace iris

#endif  // IRIS_ENGINE_IRIS_CUT_H
