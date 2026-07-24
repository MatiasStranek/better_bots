#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>
#include <shobjidl_core.h>

#include <algorithm>
#include <cstdint>

#include "resource.h"

namespace {

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr const wchar_t kGetPreferredBrightnessRegKey[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
constexpr const wchar_t kGetPreferredBrightnessRegValue[] =
    L"AppsUseLightTheme";

constexpr const wchar_t kWindowStateRegKey[] =
    L"Software\\BetterBots\\Window";
constexpr const wchar_t kWindowStateRegValue[] = L"PlacementV2";
constexpr DWORD kWindowStateVersion = 2;
constexpr LONG kMinimumLogicalWindowWidth = 760;
constexpr LONG kMinimumLogicalWindowHeight = 560;

// Some Windows SDK versions declare IVirtualDesktopManager but do not expose
// CLSID_VirtualDesktopManager. Define the documented COM class ID locally so
// the runner builds consistently across supported Visual Studio/SDK versions.
constexpr CLSID kVirtualDesktopManagerClsid = {
    0xaa509086,
    0x5ca9,
    0x4c25,
    {0x8f, 0x95, 0x58, 0x9d, 0x3c, 0x07, 0xb4, 0x8a},
};

struct PersistedWindowState {
  DWORD version = kWindowStateVersion;
  LONG left = 0;
  LONG top = 0;
  LONG right = 0;
  LONG bottom = 0;
  DWORD show_command = SW_SHOWNORMAL;
  DWORD dpi = 96;
  GUID virtual_desktop_id = GUID_NULL;
  BOOL has_virtual_desktop_id = FALSE;
};

static int g_active_window_count = 0;

using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

int Scale(int source, double scale_factor) {
  return static_cast<int>(source * scale_factor);
}

void EnableFullDpiSupportIfAvailable(HWND hwnd) {
  HMODULE user32_module = LoadLibraryA("User32.dll");
  if (!user32_module) {
    return;
  }
  auto enable_non_client_dpi_scaling =
      reinterpret_cast<EnableNonClientDpiScaling*>(
          GetProcAddress(user32_module, "EnableNonClientDpiScaling"));
  if (enable_non_client_dpi_scaling != nullptr) {
    enable_non_client_dpi_scaling(hwnd);
  }
  FreeLibrary(user32_module);
}

bool ReadPersistedWindowState(PersistedWindowState* state) {
  if (state == nullptr) {
    return false;
  }

  DWORD data_size = sizeof(PersistedWindowState);
  PersistedWindowState loaded{};
  const LSTATUS result = RegGetValueW(
      HKEY_CURRENT_USER, kWindowStateRegKey, kWindowStateRegValue,
      RRF_RT_REG_BINARY, nullptr, &loaded, &data_size);

  if (result != ERROR_SUCCESS ||
      data_size != sizeof(PersistedWindowState) ||
      loaded.version != kWindowStateVersion) {
    return false;
  }

  const LONG width = loaded.right - loaded.left;
  const LONG height = loaded.bottom - loaded.top;
  if (width <= 0 || height <= 0) {
    return false;
  }

  *state = loaded;
  return true;
}

void WritePersistedWindowState(const PersistedWindowState& state) {
  HKEY key = nullptr;
  const LSTATUS create_result = RegCreateKeyExW(
      HKEY_CURRENT_USER, kWindowStateRegKey, 0, nullptr,
      REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &key, nullptr);
  if (create_result != ERROR_SUCCESS || key == nullptr) {
    return;
  }

  RegSetValueExW(key, kWindowStateRegValue, 0, REG_BINARY,
                 reinterpret_cast<const BYTE*>(&state), sizeof(state));
  RegCloseKey(key);
}

RECT ClampRectToVisibleWorkArea(RECT rect, DWORD saved_dpi) {
  HMONITOR monitor = MonitorFromRect(&rect, MONITOR_DEFAULTTONEAREST);
  MONITORINFO monitor_info{};
  monitor_info.cbSize = sizeof(MONITORINFO);
  if (!GetMonitorInfoW(monitor, &monitor_info)) {
    return rect;
  }

  const UINT current_dpi = FlutterDesktopGetDpiForMonitor(monitor);
  LONG width = rect.right - rect.left;
  LONG height = rect.bottom - rect.top;

  if (saved_dpi > 0 && current_dpi > 0 && saved_dpi != current_dpi) {
    const double scale = static_cast<double>(current_dpi) / saved_dpi;
    width = std::max<LONG>(1, static_cast<LONG>(width * scale));
    height = std::max<LONG>(1, static_cast<LONG>(height * scale));
  }

  const RECT work = monitor_info.rcWork;
  const LONG work_width = work.right - work.left;
  const LONG work_height = work.bottom - work.top;
  const double dpi_scale = current_dpi / 96.0;
  const LONG minimum_width = Scale(kMinimumLogicalWindowWidth, dpi_scale);
  const LONG minimum_height = Scale(kMinimumLogicalWindowHeight, dpi_scale);

  width = std::min(std::max(width, minimum_width), work_width);
  height = std::min(std::max(height, minimum_height), work_height);

  const LONG maximum_left = work.right - width;
  const LONG maximum_top = work.bottom - height;
  const LONG left = std::clamp(rect.left, work.left, maximum_left);
  const LONG top = std::clamp(rect.top, work.top, maximum_top);

  return RECT{left, top, left + width, top + height};
}

bool GetVirtualDesktopId(HWND window, GUID* desktop_id) {
  if (window == nullptr || desktop_id == nullptr) {
    return false;
  }

  IVirtualDesktopManager* manager = nullptr;
  const HRESULT create_result = CoCreateInstance(
      kVirtualDesktopManagerClsid, nullptr, CLSCTX_INPROC_SERVER,
      IID_PPV_ARGS(&manager));
  if (FAILED(create_result) || manager == nullptr) {
    return false;
  }

  const HRESULT result = manager->GetWindowDesktopId(window, desktop_id);
  manager->Release();
  return SUCCEEDED(result) && !IsEqualGUID(*desktop_id, GUID_NULL);
}

void MoveToVirtualDesktop(HWND window, const GUID& desktop_id) {
  if (window == nullptr || IsEqualGUID(desktop_id, GUID_NULL)) {
    return;
  }

  IVirtualDesktopManager* manager = nullptr;
  const HRESULT create_result = CoCreateInstance(
      kVirtualDesktopManagerClsid, nullptr, CLSCTX_INPROC_SERVER,
      IID_PPV_ARGS(&manager));
  if (FAILED(create_result) || manager == nullptr) {
    return;
  }

  // If the saved desktop no longer exists, Windows rejects this request and
  // the window simply remains on the current desktop.
  manager->MoveWindowToDesktop(window, desktop_id);
  manager->Release();
}

}  // namespace

class WindowClassRegistrar {
 public:
  ~WindowClassRegistrar() = default;

  static WindowClassRegistrar* GetInstance() {
    if (!instance_) {
      instance_ = new WindowClassRegistrar();
    }
    return instance_;
  }

  const wchar_t* GetWindowClass();
  void UnregisterWindowClass();

 private:
  WindowClassRegistrar() = default;

  static WindowClassRegistrar* instance_;
  bool class_registered_ = false;
};

WindowClassRegistrar* WindowClassRegistrar::instance_ = nullptr;

const wchar_t* WindowClassRegistrar::GetWindowClass() {
  if (!class_registered_) {
    WNDCLASS window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
    window_class.hbrBackground = 0;
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = Win32Window::WndProc;
    RegisterClass(&window_class);
    class_registered_ = true;
  }
  return kWindowClassName;
}

void WindowClassRegistrar::UnregisterWindowClass() {
  UnregisterClass(kWindowClassName, nullptr);
  class_registered_ = false;
}

Win32Window::Win32Window() {
  ++g_active_window_count;
}

Win32Window::~Win32Window() {
  --g_active_window_count;
  Destroy();
}

bool Win32Window::Create(const std::wstring& title,
                         const Point& origin,
                         const Size& size) {
  Destroy();
  window_state_saved_ = false;
  initial_show_command_ = SW_SHOWNORMAL;
  has_last_normal_window_rect_ = false;

  const wchar_t* window_class =
      WindowClassRegistrar::GetInstance()->GetWindowClass();

  PersistedWindowState saved_state{};
  const bool has_saved_state = ReadPersistedWindowState(&saved_state);

  int window_x = 0;
  int window_y = 0;
  int window_width = 0;
  int window_height = 0;

  if (has_saved_state) {
    RECT restored = RECT{saved_state.left, saved_state.top, saved_state.right,
                         saved_state.bottom};
    restored = ClampRectToVisibleWorkArea(restored, saved_state.dpi);
    window_x = restored.left;
    window_y = restored.top;
    window_width = restored.right - restored.left;
    window_height = restored.bottom - restored.top;
    initial_show_command_ =
        saved_state.show_command == SW_SHOWMAXIMIZED ? SW_SHOWMAXIMIZED
                                                      : SW_SHOWNORMAL;
  } else {
    const POINT target_point = {static_cast<LONG>(origin.x),
                                static_cast<LONG>(origin.y)};
    HMONITOR monitor =
        MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
    const UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
    const double scale_factor = dpi / 96.0;
    window_x = Scale(origin.x, scale_factor);
    window_y = Scale(origin.y, scale_factor);
    window_width = Scale(size.width, scale_factor);
    window_height = Scale(size.height, scale_factor);
  }

  HWND window = CreateWindow(
      window_class, title.c_str(), WS_OVERLAPPEDWINDOW, window_x, window_y,
      window_width, window_height, nullptr, nullptr, GetModuleHandle(nullptr),
      this);

  if (!window) {
    return false;
  }

  if (has_saved_state) {
    last_normal_window_rect_ = RECT{window_x, window_y,
                                    window_x + window_width,
                                    window_y + window_height};
    has_last_normal_window_rect_ = true;
  } else {
    UpdateNormalWindowRect();
  }

  if (has_saved_state && saved_state.has_virtual_desktop_id) {
    MoveToVirtualDesktop(window, saved_state.virtual_desktop_id);
  }

  UpdateTheme(window);
  return OnCreate();
}

bool Win32Window::Show() {
  if (window_handle_ == nullptr) {
    return false;
  }
  ShowWindow(window_handle_, initial_show_command_);
  return true;
}

LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<Win32Window*>(window_struct->lpCreateParams);
    EnableFullDpiSupportIfAvailable(window);
    that->window_handle_ = window;
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT Win32Window::MessageHandler(HWND hwnd,
                                    UINT const message,
                                    WPARAM const wparam,
                                    LPARAM const lparam) noexcept {
  switch (message) {
    case WM_CLOSE:
      SaveWindowState();
      break;

    case WM_QUERYENDSESSION:
      SaveWindowState();
      return TRUE;

    case WM_DESTROY:
      SaveWindowState();
      window_handle_ = nullptr;
      Destroy();
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;

    case WM_GETMINMAXINFO: {
      auto* min_max_info = reinterpret_cast<MINMAXINFO*>(lparam);
      const HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
      const UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
      const double scale_factor = dpi / 96.0;
      min_max_info->ptMinTrackSize.x =
          Scale(kMinimumLogicalWindowWidth, scale_factor);
      min_max_info->ptMinTrackSize.y =
          Scale(kMinimumLogicalWindowHeight, scale_factor);
      return 0;
    }

    case WM_DPICHANGED: {
      auto new_rect = reinterpret_cast<RECT*>(lparam);
      const LONG new_width = new_rect->right - new_rect->left;
      const LONG new_height = new_rect->bottom - new_rect->top;

      SetWindowPos(hwnd, nullptr, new_rect->left, new_rect->top, new_width,
                   new_height, SWP_NOZORDER | SWP_NOACTIVATE);
      UpdateNormalWindowRect();
      return 0;
    }

    case WM_MOVE:
      UpdateNormalWindowRect();
      return 0;

    case WM_SIZE: {
      UpdateNormalWindowRect();
      RECT rect = GetClientArea();
      if (child_content_ != nullptr) {
        MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
                   rect.bottom - rect.top, TRUE);
      }
      return 0;
    }

    case WM_ACTIVATE:
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      return 0;

    case WM_DWMCOLORIZATIONCOLORCHANGED:
      UpdateTheme(hwnd);
      return 0;
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void Win32Window::SaveWindowState() {
  if (window_handle_ == nullptr || window_state_saved_) {
    return;
  }

  UpdateNormalWindowRect();
  if (!has_last_normal_window_rect_) {
    return;
  }

  WINDOWPLACEMENT placement{};
  placement.length = sizeof(WINDOWPLACEMENT);
  GetWindowPlacement(window_handle_, &placement);

  const RECT normal_rect = last_normal_window_rect_;
  PersistedWindowState state{};
  state.left = normal_rect.left;
  state.top = normal_rect.top;
  state.right = normal_rect.right;
  state.bottom = normal_rect.bottom;
  state.show_command = IsZoomed(window_handle_) ||
                               placement.showCmd == SW_SHOWMAXIMIZED
                           ? SW_SHOWMAXIMIZED
                           : SW_SHOWNORMAL;

  const HMONITOR monitor =
      MonitorFromWindow(window_handle_, MONITOR_DEFAULTTONEAREST);
  state.dpi = FlutterDesktopGetDpiForMonitor(monitor);
  state.has_virtual_desktop_id =
      GetVirtualDesktopId(window_handle_, &state.virtual_desktop_id) ? TRUE
                                                                     : FALSE;

  WritePersistedWindowState(state);
  window_state_saved_ = true;
}

void Win32Window::UpdateNormalWindowRect() {
  if (window_handle_ == nullptr || IsIconic(window_handle_) ||
      IsZoomed(window_handle_)) {
    return;
  }

  RECT rect{};
  if (GetWindowRect(window_handle_, &rect) && rect.right > rect.left &&
      rect.bottom > rect.top) {
    last_normal_window_rect_ = rect;
    has_last_normal_window_rect_ = true;
  }
}

void Win32Window::Destroy() {
  if (window_handle_) {
    SaveWindowState();
  }

  OnDestroy();

  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  if (g_active_window_count == 0) {
    WindowClassRegistrar::GetInstance()->UnregisterWindowClass();
  }
}

Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame = GetClientArea();

  MoveWindow(content, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, true);

  SetFocus(child_content_);
}

RECT Win32Window::GetClientArea() {
  RECT frame{};
  GetClientRect(window_handle_, &frame);
  return frame;
}

HWND Win32Window::GetHandle() {
  return window_handle_;
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate() {
  return true;
}

void Win32Window::OnDestroy() {}

void Win32Window::UpdateTheme(HWND const window) {
  DWORD light_mode;
  DWORD light_mode_size = sizeof(light_mode);
  const LSTATUS result = RegGetValueW(
      HKEY_CURRENT_USER, kGetPreferredBrightnessRegKey,
      kGetPreferredBrightnessRegValue, RRF_RT_REG_DWORD, nullptr, &light_mode,
      &light_mode_size);

  if (result == ERROR_SUCCESS) {
    const BOOL enable_dark_mode = light_mode == 0;
    DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE,
                          &enable_dark_mode, sizeof(enable_dark_mode));
  }
}
