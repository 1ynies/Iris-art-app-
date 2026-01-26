/**
 * Phase 1: Circling & Cutting — implementation.
 * Radial stretch maps [pupil_r, iris_r] -> [0.5*pupil_r, iris_r]; circular alpha mask; crop to iris box.
 */

#if !defined(IRIS_ENGINE_OPENCV_AVAILABLE)
// Stub when OpenCV not available
#include "iris_cut.h"
#include <cstdlib>

namespace iris {

bool process_iris_cut(const char*, double, double, double, double, double, double,
                      uint8_t**, int*, int*) { return false; }
bool process_iris_cut_from_view(const char*, double, double, double, double,
                                double, double, double, double,
                                uint8_t**, int*, int*) { return false; }

}  // namespace iris

#else

#include "iris_cut.h"
#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <cmath>
#include <cstdlib>
#include <algorithm>

namespace iris {

namespace {

constexpr double PUPIL_SHRINK = 0.5;  // final pupil = 50% of original

inline double clamp0(double v) { return v < 0 ? 0 : v; }

/** Bilinear sample RGBA at (x,y); (x,y) in [0,w), [0,h). Returns (r,g,b,a). */
void sample_rgba(const cv::Mat& m, double x, double y, uint8_t* out) {
  const int w = m.cols, h = m.rows;
  if (w <= 0 || h <= 0) { out[0]=out[1]=out[2]=0; out[3]=0; return; }
  int x0 = static_cast<int>(std::floor(x)), y0 = static_cast<int>(std::floor(y));
  double fx = x - x0, fy = y - y0;
  int x1 = std::min(x0 + 1, w - 1), y1 = std::min(y0 + 1, h - 1);
  x0 = std::max(0, x0); y0 = std::max(0, y0);
  auto at = [&m, w](int ix, int iy, int c) -> double {
    return static_cast<double>(m.at<cv::Vec4b>(iy, ix)[c]);
  };
  for (int c = 0; c < 4; ++c) {
    double v00 = at(x0, y0, c), v10 = at(x1, y0, c);
    double v01 = at(x0, y1, c), v11 = at(x1, y1, c);
    double v = (1 - fx) * (1 - fy) * v00 + fx * (1 - fy) * v10
             + (1 - fx) * fy * v01 + fx * fy * v11;
    int iv = static_cast<int>(std::round(v));
    out[c] = static_cast<uint8_t>(std::clamp(iv, 0, 255));
  }
}

}  // namespace

/** Internal: work on preloaded RGBA. */
static bool process_iris_cut_impl(
  const cv::Mat& rgba,
  double iris_cx, double iris_cy, double iris_r,
  double pupil_r,
  uint8_t** out_data, int* out_width, int* out_height
) {
  const int iw = rgba.cols, ih = rgba.rows;
  const double icx = iris_cx, icy = iris_cy, ir = iris_r;
  const double pr = pupil_r;
  const double pr_half = PUPIL_SHRINK * pr;
  const double annulus_src = ir - pr;   // source radial span
  const double annulus_dst = ir - pr_half;  // destination radial span
  if (annulus_dst <= 0) return false;

  // Crop to square bounding box of iris (clamped to image)
  int crop_x = static_cast<int>(std::floor(icx - ir));
  int crop_y = static_cast<int>(std::floor(icy - ir));
  int side = static_cast<int>(std::ceil(2 * ir));
  crop_x = std::clamp(crop_x, 0, iw - 1);
  crop_y = std::clamp(crop_y, 0, ih - 1);
  int crop_w = std::min(side, iw - crop_x);
  int crop_h = std::min(side, ih - crop_y);
  if (crop_w <= 0 || crop_h <= 0) return false;
  side = std::min(crop_w, crop_h);

  size_t buf_len = static_cast<size_t>(side) * static_cast<size_t>(side) * 4;
  uint8_t* buf = static_cast<uint8_t*>(std::malloc(buf_len));
  if (!buf) return false;

  // For each output pixel: r_dst from iris center; map to r_src; sample; set alpha by mask.
  for (int dy = 0; dy < side; ++dy) {
    for (int dx = 0; dx < side; ++dx) {
      double gx = crop_x + dx + 0.5;
      double gy = crop_y + dy + 0.5;
      double dx_c = gx - icx, dy_c = gy - icy;
      double r_dst = std::sqrt(dx_c * dx_c + dy_c * dy_c);
      double theta = std::atan2(dy_c, dx_c);

      if (r_dst > ir || r_dst < pr_half) {
        buf[(dy * side + dx) * 4 + 0] = 0;
        buf[(dy * side + dx) * 4 + 1] = 0;
        buf[(dy * side + dx) * 4 + 2] = 0;
        buf[(dy * side + dx) * 4 + 3] = 0;
        continue;
      }

      // Map r_dst in [pr_half, ir] -> r_src in [pr, ir]
      double t = (r_dst - pr_half) / annulus_dst;
      t = std::clamp(t, 0.0, 1.0);
      double r_src = pr + t * annulus_src;
      double sx = icx + r_src * std::cos(theta);
      double sy = icy + r_src * std::sin(theta);

      uint8_t px[4];
      sample_rgba(rgba, sx, sy, px);
      buf[(dy * side + dx) * 4 + 0] = px[0];
      buf[(dy * side + dx) * 4 + 1] = px[1];
      buf[(dy * side + dx) * 4 + 2] = px[2];
      buf[(dy * side + dx) * 4 + 3] = px[3];
    }
  }

  *out_data = buf;
  *out_width = side;
  *out_height = side;
  return true;
}

bool process_iris_cut(
  const char* image_path,
  double iris_cx, double iris_cy, double iris_r,
  double pupil_cx, double pupil_cy, double pupil_r,
  uint8_t** out_data, int* out_width, int* out_height
) {
  if (!image_path || !out_data || !out_width || !out_height ||
      iris_r <= 0 || pupil_r < 0 || pupil_r >= iris_r) {
    return false;
  }
  *out_data = nullptr;
  *out_width = 0;
  *out_height = 0;
  cv::Mat src = cv::imread(image_path);
  if (src.empty()) return false;
  cv::Mat rgba;
  if (src.channels() == 3)
    cv::cvtColor(src, rgba, cv::COLOR_BGR2RGBA);
  else if (src.channels() == 4)
    rgba = src.clone();
  else
    return false;
  return process_iris_cut_impl(rgba, iris_cx, iris_cy, iris_r, pupil_r,
                               out_data, out_width, out_height);
}

bool process_iris_cut_from_view(
  const char* image_path,
  double view_w, double view_h,
  double outer_r, double inner_r,
  double outer_dx, double outer_dy,
  double inner_dx, double inner_dy,
  uint8_t** out_data, int* out_width, int* out_height
) {
  if (!image_path || view_w <= 0 || view_h <= 0) return false;

  cv::Mat src = cv::imread(image_path);
  if (src.empty()) return false;
  const int w = src.cols, h = src.rows;
  if (w <= 0 || h <= 0) return false;

  double scale = std::min(view_w / w, view_h / h);
  double shortest = std::min(view_w, view_h);

  double iris_cx = w / 2.0 + (view_w * outer_dx) / scale;
  double iris_cy = h / 2.0 + (view_h * outer_dy) / scale;
  double iris_r = (outer_r * shortest / 2.0) / scale;
  double pupil_cx = w / 2.0 + (view_w * inner_dx) / scale;
  double pupil_cy = h / 2.0 + (view_h * inner_dy) / scale;
  double pupil_r = (inner_r * shortest / 2.0) / scale;
  cv::Mat rgba;
  if (src.channels() == 3)
    cv::cvtColor(src, rgba, cv::COLOR_BGR2RGBA);
  else
    rgba = src.clone();
  return process_iris_cut_impl(rgba, iris_cx, iris_cy, iris_r, pupil_r,
                               out_data, out_width, out_height);
}

}  // namespace iris

#endif  // IRIS_ENGINE_OPENCV_AVAILABLE
