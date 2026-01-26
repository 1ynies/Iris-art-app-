/**
 * Iris Engine — Core implementation.
 * Phase 2–4 require OpenCV (IRIS_ENGINE_OPENCV_AVAILABLE).
 */

#include "iris_engine.h"
#include <algorithm>
#include <cmath>
#include <cstring>

#if defined(IRIS_ENGINE_OPENCV_AVAILABLE)
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/photo.hpp>
#endif

namespace iris {

namespace {

inline uint8_t clamp(int v) {
  if (v < 0) return 0;
  if (v > 255) return 255;
  return static_cast<uint8_t>(v);
}

}  // namespace

IrisObject::IrisObject() = default;

IrisObject::~IrisObject() = default;

bool IrisObject::load_from_rgba(const uint8_t* data, int w, int h) {
  if (!data || w <= 0 || h <= 0) return false;
  size_t n = static_cast<size_t>(w) * static_cast<size_t>(h) * 4;
  rgba_.assign(data, data + n);
  width_ = w;
  height_ = h;
  alpha_mask_.resize(static_cast<size_t>(w) * static_cast<size_t>(h), 255);
  return true;
}

bool IrisObject::get_rgba(std::vector<uint8_t>& out) const {
  out = rgba_;
  return !rgba_.empty();
}

bool IrisObject::detect_iris_and_pupil(CircleResult& iris, CircleResult& pupil) {
#if defined(IRIS_ENGINE_OPENCV_AVAILABLE)
  if (rgba_.empty() || width_ <= 0 || height_ <= 0) return false;
  cv::Mat mat_rgba(height_, width_, CV_8UC4, rgba_.data());
  cv::Mat gray;
  cv::cvtColor(mat_rgba, gray, cv::COLOR_RGBA2GRAY);
  cv::GaussianBlur(gray, gray, cv::Size(5, 5), 1.5, 1.5);
  std::vector<cv::Vec3f> circles;
  int minR = std::min(width_, height_) / 20;
  int maxR = std::min(width_, height_) / 2;
  cv::HoughCircles(gray, circles, cv::HOUGH_GRADIENT, 1.0,
                   static_cast<double>(std::max(width_, height_)) / 4.0,
                   100, 30, minR, maxR);
  if (circles.size() < 2) {
    if (circles.size() == 1) {
      float r = circles[0][2];
      iris.center_x = circles[0][0];
      iris.center_y = circles[0][1];
      iris.radius = r;
      iris.valid = true;
      pupil.center_x = circles[0][0];
      pupil.center_y = circles[0][1];
      pupil.radius = r * 0.3f;
      pupil.valid = true;
      return true;
    }
    return false;
  }
  std::sort(circles.begin(), circles.end(),
            [](const cv::Vec3f& a, const cv::Vec3f& b) { return a[2] < b[2]; });
  pupil.center_x = circles[0][0];
  pupil.center_y = circles[0][1];
  pupil.radius = circles[0][2];
  pupil.valid = true;
  iris.center_x = circles[1][0];
  iris.center_y = circles[1][1];
  iris.radius = circles[1][2];
  iris.valid = true;
  iris_circle_ = iris;
  pupil_circle_ = pupil;
  return true;
#else
  (void)iris;
  (void)pupil;
  return false;
#endif
}

bool IrisObject::cut_iris_to_alpha(float iris_radius_scale) {
#if defined(IRIS_ENGINE_OPENCV_AVAILABLE)
  CircleResult ir, pu;
  if (!detect_iris_and_pupil(ir, pu)) return false;
  float cx = ir.center_x;
  float cy = ir.center_y;
  float R = ir.radius * iris_radius_scale;
  float px = pu.center_x, py = pu.center_y, pr = pu.radius;
  size_t idx = 0;
  for (int y = 0; y < height_; ++y) {
    for (int x = 0; x < width_; ++x) {
      float dx = static_cast<float>(x) - cx;
      float dy = static_cast<float>(y) - cy;
      float r2 = dx * dx + dy * dy;
      float inside_iris = (r2 <= R * R);
      float inside_pupil = (static_cast<float>(x) - px) * (static_cast<float>(x) - px) +
                            (static_cast<float>(y) - py) * (static_cast<float>(y) - py) <= pr * pr;
      if (!inside_iris || inside_pupil)
        rgba_[idx + 3] = 0;
      idx += 4;
    }
  }
  return true;
#else
  (void)iris_radius_scale;
  return false;
#endif
}

bool IrisObject::remove_flash(const FlashRemovalParams& params) {
#if defined(IRIS_ENGINE_OPENCV_AVAILABLE)
  if (rgba_.empty() || width_ <= 0 || height_ <= 0) return false;
  cv::Mat mat_rgba(height_, width_, CV_8UC4, rgba_.data());
  cv::Mat bgr;
  cv::cvtColor(mat_rgba, bgr, cv::COLOR_RGBA2BGR);
  cv::Mat lab;
  cv::cvtColor(bgr, lab, cv::COLOR_BGR2Lab);
  std::vector<cv::Mat> planes(3);
  cv::split(lab, planes);
  double thresh = params.brightness_threshold * 255.0;
  if (thresh > 255) thresh = 255;
  if (thresh < 0) thresh = 0;
  cv::Mat mask;
  cv::threshold(planes[0], mask, thresh, 255, cv::THRESH_BINARY);
  if (params.dilate_pixels > 0) {
    int k = (params.dilate_pixels * 2) | 1;
    cv::dilate(mask, mask, cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(k, k)));
  }
  cv::Mat bgr_inpainted;
  cv::inpaint(bgr, mask, bgr_inpainted, 3.0, cv::INPAINT_TELEA);
  cv::Mat out_rgba;
  cv::cvtColor(bgr_inpainted, out_rgba, cv::COLOR_BGR2RGBA);
  const size_t n = static_cast<size_t>(width_) * static_cast<size_t>(height_) * 4;
  std::vector<uint8_t> alpha_backup(width_ * height_);
  for (size_t i = 0, j = 0; i < n; i += 4, ++j) alpha_backup[j] = rgba_[i + 3];
  std::memcpy(rgba_.data(), out_rgba.data, n);
  for (size_t i = 0, j = 0; i < n; i += 4, ++j) rgba_[i + 3] = alpha_backup[j];
  return true;
#else
  (void)params;
  return false;
#endif
}

bool IrisObject::apply_effect_params(const EffectParams& params) {
#if defined(IRIS_ENGINE_OPENCV_AVAILABLE)
  if (rgba_.empty() || width_ <= 0 || height_ <= 0) return false;
  cv::Mat mat_rgba(height_, width_, CV_8UC4, rgba_.data());
  cv::Mat bgr;
  cv::cvtColor(mat_rgba, bgr, cv::COLOR_RGBA2BGR);
  cv::Mat lab;
  cv::cvtColor(bgr, lab, cv::COLOR_BGR2Lab);
  std::vector<cv::Mat> planes(3);
  cv::split(lab, planes);
  if (params.clarity > 0.1f) {
    cv::Ptr<cv::CLAHE> clahe = cv::createCLAHE(params.clarity, cv::Size(8, 8));
    clahe->apply(planes[0], planes[0]);
  }
  if (std::fabs(params.vibrance) > 0.01f) {
    float s = 1.0f + params.vibrance;
    planes[1].convertTo(planes[1], -1, s, 0);
    planes[2].convertTo(planes[2], -1, s, 0);
  }
  cv::merge(planes, lab);
  cv::cvtColor(lab, bgr, cv::COLOR_Lab2BGR);
  if (std::fabs(params.gamma - 1.0f) > 0.01f) {
    cv::Mat lut(1, 256, CV_8UC1);
    for (int i = 0; i < 256; ++i)
      lut.at<uchar>(i) = clamp(static_cast<int>(255.0 * std::pow(i / 255.0, 1.0 / params.gamma)));
    cv::LUT(bgr, lut, bgr);
  }
  if (params.sharpness > 0.01f) {
    cv::Mat blurred;
    cv::GaussianBlur(bgr, blurred, cv::Size(0, 0), 1.0);
    cv::addWeighted(bgr, 1.0 + params.sharpness, blurred, -params.sharpness, 0, bgr);
  }
  cv::Mat out_rgba;
  cv::cvtColor(bgr, out_rgba, cv::COLOR_BGR2RGBA);
  const size_t n = static_cast<size_t>(width_) * static_cast<size_t>(height_) * 4;
  std::vector<uint8_t> alpha_backup(width_ * height_);
  for (size_t i = 0, j = 0; i < n; i += 4, ++j) alpha_backup[j] = rgba_[i + 3];
  std::memcpy(rgba_.data(), out_rgba.data, n);
  for (size_t i = 0, j = 0; i < n; i += 4, ++j) rgba_[i + 3] = alpha_backup[j];
  return true;
#else
  (void)params;
  return false;
#endif
}

bool IrisObject::apply_clarity(float clip_limit) {
  EffectParams p{};
  p.vibrance = 0;
  p.gamma = 1.0f;
  p.sharpness = 0;
  p.clarity = clip_limit;
  return apply_effect_params(p);
}

bool IrisObject::export_to_file(const char*, const ExportParams&) const {
  return false;
}

IrisObject* iris_object_create() {
  return new IrisObject();
}

void iris_object_destroy(IrisObject* obj) {
  delete obj;
}

}  // namespace iris
