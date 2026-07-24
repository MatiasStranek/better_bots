cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)


# Windows-only ONNX Runtime for Maia3. The dependency is downloaded as a
# prebuilt Microsoft release and linked directly into the Windows runner. It is
# not a Flutter plugin dependency, so Android keeps its existing native ONNX
# integration unchanged.
include(FetchContent)

set(MAIA3_ONNXRUNTIME_VERSION "1.23.0")
FetchContent_Declare(
  maia3_onnxruntime_windows
  URL "https://github.com/microsoft/onnxruntime/releases/download/v${MAIA3_ONNXRUNTIME_VERSION}/onnxruntime-win-x64-${MAIA3_ONNXRUNTIME_VERSION}.zip"
)
FetchContent_GetProperties(maia3_onnxruntime_windows)
if(NOT maia3_onnxruntime_windows_POPULATED)
  FetchContent_Populate(maia3_onnxruntime_windows)
endif()

file(GLOB_RECURSE MAIA3_ONNXRUNTIME_HEADER
  LIST_DIRECTORIES FALSE
  "${maia3_onnxruntime_windows_SOURCE_DIR}/onnxruntime_cxx_api.h")
file(GLOB_RECURSE MAIA3_ONNXRUNTIME_LIBRARY
  LIST_DIRECTORIES FALSE
  "${maia3_onnxruntime_windows_SOURCE_DIR}/onnxruntime.lib")
file(GLOB_RECURSE MAIA3_ONNXRUNTIME_DLL
  LIST_DIRECTORIES FALSE
  "${maia3_onnxruntime_windows_SOURCE_DIR}/onnxruntime.dll")

list(LENGTH MAIA3_ONNXRUNTIME_HEADER MAIA3_ONNXRUNTIME_HEADER_COUNT)
list(LENGTH MAIA3_ONNXRUNTIME_LIBRARY MAIA3_ONNXRUNTIME_LIBRARY_COUNT)
list(LENGTH MAIA3_ONNXRUNTIME_DLL MAIA3_ONNXRUNTIME_DLL_COUNT)

if(MAIA3_ONNXRUNTIME_HEADER_COUNT EQUAL 0 OR
   MAIA3_ONNXRUNTIME_LIBRARY_COUNT EQUAL 0 OR
   MAIA3_ONNXRUNTIME_DLL_COUNT EQUAL 0)
  message(FATAL_ERROR
    "The Windows ONNX Runtime archive is incomplete or could not be extracted.")
endif()

list(GET MAIA3_ONNXRUNTIME_HEADER 0 MAIA3_ONNXRUNTIME_HEADER_FILE)
list(GET MAIA3_ONNXRUNTIME_LIBRARY 0 MAIA3_ONNXRUNTIME_LIBRARY_FILE)
list(GET MAIA3_ONNXRUNTIME_DLL 0 MAIA3_ONNXRUNTIME_DLL_FILE)
get_filename_component(
  MAIA3_ONNXRUNTIME_INCLUDE_DIR
  "${MAIA3_ONNXRUNTIME_HEADER_FILE}"
  DIRECTORY)

add_library(maia3_onnx_bridge STATIC
  "maia3_onnx_bridge.cpp"
  "maia3_onnx_bridge.h"
)
target_compile_features(maia3_onnx_bridge PUBLIC cxx_std_17)
target_compile_options(maia3_onnx_bridge PRIVATE /W4 /EHsc)
target_compile_definitions(maia3_onnx_bridge PRIVATE NOMINMAX UNICODE _UNICODE)
target_include_directories(maia3_onnx_bridge PRIVATE
  "${MAIA3_ONNXRUNTIME_INCLUDE_DIR}")
target_link_libraries(maia3_onnx_bridge PUBLIC
  "${MAIA3_ONNXRUNTIME_LIBRARY_FILE}")

# Expose the DLL path to the project-level install rules.
set(MAIA3_ONNXRUNTIME_DLL_FILE
  "${MAIA3_ONNXRUNTIME_DLL_FILE}"
  PARENT_SCOPE)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib" "ole32.lib" "uuid.lib")
target_link_libraries(${BINARY_NAME} PRIVATE maia3_onnx_bridge)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
