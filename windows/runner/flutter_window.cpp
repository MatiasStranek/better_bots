#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <cstdint>
#include <exception>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>
#include <variant>
#include <vector>

#include "flutter/generated_plugin_registrant.h"

namespace {
constexpr char kMaia3ChannelName[] = "better_bots/maia3_windows_onnx";

const flutter::EncodableMap* GetArgumentsMap(
    const flutter::MethodCall<flutter::EncodableValue>& call) {
  const auto* arguments = call.arguments();
  if (arguments == nullptr) {
    return nullptr;
  }
  return std::get_if<flutter::EncodableMap>(arguments);
}

const flutter::EncodableValue* FindMapValue(
    const flutter::EncodableMap& map,
    const std::string& key) {
  const auto iterator = map.find(flutter::EncodableValue(key));
  return iterator == map.end() ? nullptr : &iterator->second;
}

std::vector<double> ReadDoubleList(const flutter::EncodableValue& value) {
  if (const auto* list = std::get_if<flutter::EncodableList>(&value)) {
    std::vector<double> result;
    result.reserve(list->size());

    for (const auto& item : *list) {
      if (const auto* number = std::get_if<double>(&item)) {
        result.push_back(*number);
      } else if (const auto* integer = std::get_if<int32_t>(&item)) {
        result.push_back(static_cast<double>(*integer));
      } else if (const auto* integer64 = std::get_if<int64_t>(&item)) {
        result.push_back(static_cast<double>(*integer64));
      } else {
        throw std::invalid_argument(
            "tokens enthaelt einen nicht numerischen Wert.");
      }
    }

    return result;
  }

  if (const auto* typed = std::get_if<std::vector<double>>(&value)) {
    return *typed;
  }

  throw std::invalid_argument("tokens muss eine Liste aus Zahlen sein.");
}

int64_t ReadInt64(const flutter::EncodableValue& value) {
  if (const auto* number = std::get_if<int32_t>(&value)) {
    return *number;
  }
  if (const auto* number = std::get_if<int64_t>(&value)) {
    return *number;
  }
  throw std::invalid_argument("elo muss eine ganze Zahl sein.");
}
}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() = default;

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterMaia3WindowsChannel();
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::RegisterMaia3WindowsChannel() {
  maia3_onnx_bridge_ = std::make_unique<Maia3OnnxBridge>();
  maia3_onnx_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          kMaia3ChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  maia3_onnx_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<
                 flutter::MethodResult<flutter::EncodableValue>> result) {
        try {
          if (call.method_name() == "initialize") {
            const std::string message = maia3_onnx_bridge_->Initialize();
            result->Success(flutter::EncodableValue(message));
            return;
          }

          if (call.method_name() == "runInference") {
            const auto* arguments = GetArgumentsMap(call);
            if (arguments == nullptr) {
              result->Error("invalid_arguments", "Argumente fehlen.");
              return;
            }

            const auto* token_value = FindMapValue(*arguments, "tokens");
            const auto* elo_value = FindMapValue(*arguments, "elo");
            if (token_value == nullptr || elo_value == nullptr) {
              result->Error(
                  "invalid_arguments", "tokens oder elo fehlen.");
              return;
            }

            const std::vector<double> tokens = ReadDoubleList(*token_value);
            const int64_t elo = ReadInt64(*elo_value);
            const std::vector<double> logits =
                maia3_onnx_bridge_->RunInference(tokens, elo);

            flutter::EncodableList encoded_logits;
            encoded_logits.reserve(logits.size());
            for (const double logit : logits) {
              encoded_logits.emplace_back(logit);
            }

            result->Success(flutter::EncodableValue(encoded_logits));
            return;
          }

          if (call.method_name() == "dispose") {
            maia3_onnx_bridge_->Dispose();
            result->Success(flutter::EncodableValue());
            return;
          }

          result->NotImplemented();
        } catch (const std::exception& error) {
          result->Error("maia3_windows_error", error.what());
        } catch (...) {
          result->Error(
              "maia3_windows_error", "Unbekannter nativer Maia3-Fehler.");
        }
      });
}

void FlutterWindow::OnDestroy() {
  maia3_onnx_channel_.reset();
  maia3_onnx_bridge_.reset();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
