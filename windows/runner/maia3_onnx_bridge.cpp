#include "maia3_onnx_bridge.h"

#include <windows.h>

#include <array>
#include <cstdint>
#include <filesystem>
#include <stdexcept>
#include <utility>

#include <onnxruntime_cxx_api.h>

namespace {
constexpr size_t kMaiaTokenCount = 64u * 97u;
constexpr size_t kMaiaMoveLogitCount = 4352u;
}  // namespace

Maia3OnnxBridge::Maia3OnnxBridge() = default;

Maia3OnnxBridge::~Maia3OnnxBridge() { Dispose(); }

std::wstring Maia3OnnxBridge::ResolveModelPath() const {
  std::wstring executable_path(32768, L'\0');
  const DWORD length = GetModuleFileNameW(
      nullptr, executable_path.data(), static_cast<DWORD>(executable_path.size()));

  if (length == 0 || length >= executable_path.size()) {
    throw std::runtime_error(
        "Der Pfad der gestarteten Windows-App konnte nicht ermittelt werden.");
  }

  executable_path.resize(length);
  const std::filesystem::path executable(executable_path);
  return (executable.parent_path() / L"engines" / L"maia3" /
          L"maia3-5m.onnx")
      .wstring();
}

std::string Maia3OnnxBridge::Initialize() {
  std::lock_guard<std::mutex> lock(mutex_);

  if (session_) {
    return "Maia3 Windows ONNX ist bereits bereit.";
  }

  model_path_ = ResolveModelPath();
  if (!std::filesystem::exists(model_path_)) {
    throw std::runtime_error(
        "Das gebuendelte Maia3-Modell wurde neben der App nicht gefunden.");
  }

  environment_ = std::make_unique<Ort::Env>(
      ORT_LOGGING_LEVEL_WARNING, "better_bots_maia3_windows");

  Ort::SessionOptions options;
  options.SetIntraOpNumThreads(1);
  options.SetInterOpNumThreads(1);
  options.SetGraphOptimizationLevel(GraphOptimizationLevel::ORT_ENABLE_ALL);

  session_ = std::make_unique<Ort::Session>(
      *environment_, model_path_.c_str(), options);

  return "Maia3 Windows ONNX bereit.";
}

std::vector<double> Maia3OnnxBridge::RunInference(
    const std::vector<double>& tokens,
    int64_t elo) {
  std::lock_guard<std::mutex> lock(mutex_);

  if (!session_) {
    throw std::runtime_error("Maia3 Windows ONNX ist nicht initialisiert.");
  }

  if (tokens.size() != kMaiaTokenCount) {
    throw std::invalid_argument(
        "Maia3 erwartet genau 6208 Token-Werte.");
  }

  std::vector<float> float_tokens;
  float_tokens.reserve(tokens.size());
  for (const double value : tokens) {
    float_tokens.push_back(static_cast<float>(value));
  }

  const std::array<int64_t, 3> token_shape{1, 64, 97};
  const std::array<int64_t, 1> elo_shape{1};
  std::array<int64_t, 1> self_elo{elo};
  std::array<int64_t, 1> opponent_elo{elo};

  Ort::MemoryInfo memory_info = Ort::MemoryInfo::CreateCpu(
      OrtArenaAllocator, OrtMemTypeDefault);

  std::array<Ort::Value, 3> input_values{
      Ort::Value::CreateTensor<float>(
          memory_info,
          float_tokens.data(),
          float_tokens.size(),
          token_shape.data(),
          token_shape.size()),
      Ort::Value::CreateTensor<int64_t>(
          memory_info,
          self_elo.data(),
          self_elo.size(),
          elo_shape.data(),
          elo_shape.size()),
      Ort::Value::CreateTensor<int64_t>(
          memory_info,
          opponent_elo.data(),
          opponent_elo.size(),
          elo_shape.data(),
          elo_shape.size()),
  };

  constexpr std::array<const char*, 3> input_names{
      "tokens", "self_elos", "oppo_elos"};
  constexpr std::array<const char*, 1> output_names{"logits_move"};

  auto output_values = session_->Run(
      Ort::RunOptions{nullptr},
      input_names.data(),
      input_values.data(),
      input_values.size(),
      output_names.data(),
      output_names.size());

  if (output_values.size() != 1 || !output_values.front().IsTensor()) {
    throw std::runtime_error(
        "Maia3 hat keine gueltige logits_move-Ausgabe geliefert.");
  }

  const auto tensor_info = output_values.front().GetTensorTypeAndShapeInfo();
  const size_t element_count = tensor_info.GetElementCount();
  if (element_count != kMaiaMoveLogitCount) {
    throw std::runtime_error(
        "Maia3 logits_move hat nicht die erwartete Laenge 4352.");
  }

  const float* output_data = output_values.front().GetTensorData<float>();
  std::vector<double> logits;
  logits.reserve(element_count);
  for (size_t index = 0; index < element_count; ++index) {
    logits.push_back(static_cast<double>(output_data[index]));
  }

  return logits;
}

void Maia3OnnxBridge::Dispose() {
  std::lock_guard<std::mutex> lock(mutex_);
  session_.reset();
  environment_.reset();
  model_path_.clear();
}

bool Maia3OnnxBridge::IsInitialized() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return session_ != nullptr;
}
