cmake_minimum_required(VERSION 3.10)
project(finufft_dart VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Adjust this path if your project structure is different
set(FINUFFT_INCLUDE_DIR ../../include)
set(FINUFFT_SRC_DIR ../../src)
set(FINUFFT_CONTRIB_DIR ../../contrib)

include_directories(${FINUFFT_INCLUDE_DIR})
include_directories(${FINUFFT_CONTRIB_DIR}) # For legendre_rule_fast.h

add_library(finufft_dart SHARED
    ${FINUFFT_SRC_DIR}/c_interface.cpp
    ${FINUFFT_SRC_DIR}/finufft_core.cpp
    ${FINUFFT_SRC_DIR}/spreadinterp.cpp
    ${FINUFFT_SRC_DIR}/fft.cpp
    ${FINUFFT_SRC_DIR}/finufft_utils.cpp
    ${FINUFFT_CONTRIB_DIR}/legendre_rule_fast.cpp
)

# Add FFTW dependency if needed.
# FINUFFT can be compiled to use its own bundled FFTW-compatible routines,
# or link against an external FFTW library.
# For simplicity, this example assumes the bundled routines are used or FFTW is not strictly required for the minimal build.
# If external FFTW is required:
find_package(PkgConfig REQUIRED)
pkg_check_modules(FFTW_DOUBLE REQUIRED fftw3)
pkg_check_modules(FFTW_FLOAT REQUIRED fftw3f)

if (FFTW_DOUBLE_FOUND AND FFTW_FLOAT_FOUND)
  target_link_libraries(finufft_dart PUBLIC ${FFTW_DOUBLE_LIBRARIES} ${FFTW_FLOAT_LIBRARIES})
  target_include_directories(finufft_dart PUBLIC ${FFTW_DOUBLE_INCLUDE_DIRS} ${FFTW_FLOAT_INCLUDE_DIRS})
  message(STATUS "FFTW (double and float) found and linked using pkg-config.")
else()
  message(FATAL_ERROR "FFTW (double and/or float) not found using pkg-config. Ensure fftw3 and fftw3f .pc files are available.")
endif()

# Set properties for the shared library, e.g., output name
set_target_properties(finufft_dart PROPERTIES
    OUTPUT_NAME "finufft_dart"
    # VERSION ${PROJECT_VERSION} # Uncomment if you want to include version in the filename
    # SOVERSION ${PROJECT_VERSION_MAJOR} # Uncomment for Linux versioning
)

# Optional: Add install rules
# install(TARGETS finufft_dart
# LIBRARY DESTINATION lib
# ARCHIVE DESTINATION lib
# RUNTIME DESTINATION bin)
# install(FILES ${FINUFFT_INCLUDE_DIR}/finufft.h DESTINATION include)
# install(FILES ${FINUFFT_INCLUDE_DIR}/finufft_opts.h DESTINATION include)
# install(FILES ${FINUFFT_INCLUDE_DIR}/finufft_errors.h DESTINATION include)
# install(FILES ${FINUFFT_INCLUDE_DIR}/finufft_eitherprec.h DESTINATION include)
# install(FILES ${FINUFFT_INCLUDE_DIR}/finufft/finufft_core.h DESTINATION include/finufft)
# install(FILES ${FINUFFT_INCLUDE_DIR}/finufft/spreadinterp.h DESTINATION include/finufft)
# install(FILES ${FINUFFT_INCLUDE_DIR}/finufft/fft.h DESTINATION include/finufft)
# install(FILES ${FINUFFT_INCLUDE_DIR}/finufft/finufft_utils.hpp DESTINATION include/finufft)
# install(FILES ${FINUFFT_CONTRIB_DIR}/legendre_rule_fast.h DESTINATION include/contrib)

message(STATUS "FINUFFT_INCLUDE_DIR: ${FINUFFT_INCLUDE_DIR}")
message(STATUS "FINUFFT_SRC_DIR: ${FINUFFT_SRC_DIR}")
message(STATUS "FINUFFT_CONTRIB_DIR: ${FINUFFT_CONTRIB_DIR}")

add_executable(test_finufft_minimal test_finufft_minimal.cpp)
target_link_libraries(test_finufft_minimal PRIVATE finufft_dart)
# Ensure the test executable can find the shared library.
# This might require setting RPATH or copying the library next to the executable,
# depending on the OS and CMake version. For simplicity during testing,
# we often run the test from the directory containing the shared library.
set_target_properties(test_finufft_minimal PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
