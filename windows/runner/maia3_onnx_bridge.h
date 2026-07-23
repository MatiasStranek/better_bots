#ifndef RUNNER_MAIA3_ONNX_BRIDGE_H_
#define RUNNER_MAIA3_ONNX_BRIDGE_H_

#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace Ort {
class Env;
class Session;
}  // namespace Ort

// Owns the Windows-only ONNX Runtime session used by Maia3.
//
// This class deliberately lives in the Windows runner instead of a Flutter
// package dependency. Android therefore continues to use its existing Kotlin
// MethodChannel implementation and does not package a second ONNX Runtime.
class Maia3OnnxBridge {
 public:
  Maia3OnnxBridge();
  ~Maia3OnnxBridge();

  Maia3OnnxBridge(const Maia3OnnxBridge&) = delete;
  Maia3OnnxBridge& operator=(const Maia3OnnxBridge&) = delete;

  // Loads the model once. Repeated calls are cheap and keep the existing
  // session alive.
  std::string Initialize();

  // Runs the Maia policy model and returns all 4352 move logits.
  std::vector<double> RunInference(const std::vector<double>& tokens,
                                   int64_t elo);

  void Dispose();
  bool IsInitialized() const;

 private:
  std::wstring ResolveModelPath() const;

  mutable std::mutex mutex_;
  std::unique_ptr<Ort::Env> environment_;
  std::unique_ptr<Ort::Session> session_;
  std::wstring model_path_;
};

#endif  // RUNNER_MAIA3_ONNX_BRIDGE_H_
