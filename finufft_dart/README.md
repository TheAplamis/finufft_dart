# finufft_dart

Dart FFI bindings for the [FINUFFT](https://github.com/flatironinstitute/finufft) library, enabling high-performance Non-Uniform Fast Fourier Transforms directly in your Dart and Flutter applications.

This package provides a Dart-friendly interface to the underlying C++ FINUFFT library, allowing you to perform Type 1, 2, and (eventually) Type 3 NUFFTs in 1, 2, or 3 dimensions.

**Current Focus:** The Dart API primarily supports Type 1 transforms but is designed to be extensible.

## Prerequisites

1.  **C++ Compiler:** A compiler that supports C++17 (e.g., GCC, Clang, MSVC).
2.  **CMake:** Version 3.19 or higher.
3.  **FINUFFT Source Code:** You'll need to clone the [official FINUFFT repository](https://github.com/flatironinstitute/finufft).
4.  **(Optional) FFTW3:** While FINUFFT can use its bundled DUCC0 FFT, you might choose to link against a system-installed FFTW3. If so, ensure `fftw3` and its development libraries are installed. CMake typically handles finding FFTW3 if present, or uses DUCC0 otherwise.

## Step 1: Build the Native FINUFFT Shared Library

This Dart package requires a **shared** native FINUFFT library (`.so` on Linux, `.dylib` on macOS, `.dll` on Windows).

1.  **Clone the FINUFFT repository:**
    ```bash
    git clone https://github.com/flatironinstitute/finufft.git
    cd finufft
    ```

2.  **Configure and build FINUFFT using CMake:**
    Create a build directory and run CMake. It's crucial to build a **shared library** and specify an **install prefix**.

    ```bash
    # Create a build directory
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
                      -DFINUFFT_USE_CPU=ON \
                      -DFINUFFT_SHARED_LINKING=ON \
                      -DFINUFFT_BUILD_TESTS=OFF \
                      -DFINUFFT_BUILD_EXAMPLES=OFF \
                      -DCMAKE_INSTALL_PREFIX=./finufft_install
    # (Adjust CMAKE_INSTALL_PREFIX to your desired location)
    # (On Windows, you might need to specify a generator, e.g., -G "Visual Studio 17 2022")

    # Build the library
    cmake --build build --config Release

    # Install the library
    cmake --install build --config Release
    ```

    *   `-DFINUFFT_SHARED_LINKING=ON`: This is essential for creating a shared library. (Alternatively, `-DFINUFFT_STATIC_LINKING=OFF`).
    *   `-DCMAKE_INSTALL_PREFIX=./finufft_install`: This tells CMake where to install the compiled library and headers. You can choose any path; this example installs it into a `finufft_install` directory inside the cloned `finufft` repo.
    *   The library will typically be found in a subdirectory like `finufft_install/lib/` (Linux/macOS) or `finufft_install/bin/` (Windows). The exact name will be `libfinufft.so` (Linux), `libfinufft.dylib` (macOS), or `finufft.dll` (Windows).

## Step 2: Using `finufft_dart` in Your Project

1.  **Add `finufft_dart` to your `pubspec.yaml`:**

    Since this package is likely being developed locally or not yet on pub.dev, you'll use a path dependency. Place the `finufft_dart` package directory relative to your project, then add:

    ```yaml
    dependencies:
      flutter:
        sdk: flutter
      # ... other dependencies

      finufft_dart:
        path: ../finufft_dart # Adjust path as necessary
    ```

2.  **Provide the Native Library Path to `FINUFFT` Class:**

    When you create an instance of the `FINUFFT` class, you **must** provide the path to the compiled native shared library you built in Step 1.

    ```dart
    import 'package:finufft_dart/finufft_dart.dart';
    import 'dart:io' show Platform;

    void main() {
      String libraryPath;
      // Determine the correct library path based on the OS and your install location
      if (Platform.isLinux) {
        libraryPath = '/path/to/your/cloned/finufft/finufft_install/lib/libfinufft.so';
      } else if (Platform.isMacOS) {
        libraryPath = '/path/to/your/cloned/finufft/finufft_install/lib/libfinufft.dylib';
      } else if (Platform.isWindows) {
        libraryPath = 'C:/path/to/your/cloned/finufft/finufft_install/bin/finufft.dll';
      } else {
        throw Exception('Unsupported OS for FINUFFT library path.');
      }

      // Example: 1D Type 1 NUFFT
      final finufft = FINUFFT(
        libraryPath: libraryPath, // CRITICAL: Path to the compiled native library
        dim: 1,
        nModes: [100],
      );

      // ... use finufft object ...

      finufft.dispose();
    }
    ```
    **Important:** Replace `/path/to/your/cloned/finufft/` with the actual path where you cloned and built FINUFFT and installed it (based on your `CMAKE_INSTALL_PREFIX`).

## Basic Usage Example

See the `example/finufft_dart_example.dart` file for a runnable example. Here's a snippet:

```dart
import 'package:finufft_dart/finufft_dart.dart';
import 'dart:math'; // For Random

void main() {
  // User must provide this path based on their FINUFFT native library build
  final String libraryPath = 'YOUR_PATH_TO_LIBFINUFFT_SHARED_LIBRARY';

  try {
    final finufft = FINUFFT(
      libraryPath: libraryPath,
      dim: 1,
      nModes: [100],
      tolerance: 1e-5,
      useDoublePrecision: true,
    );

    final M = 50; // Number of non-uniform points
    final xj = List.generate(M, (i) => pi * (2 * Random().nextDouble() - 1));
    final sources = List.generate(M, (i) => Complex(cos(xj[i]), sin(xj[i])));

    finufft.setPoints(xj: xj);
    final results = finufft.execute(sources);

    print('First 5 Fourier coefficients:');
    for (int i = 0; i < min(5, results.length); i++) {
      print(results[i]);
    }

    finufft.dispose();
  } on FinufftException catch (e) {
    print('FINUFFT Error: ${e.message} (Code: ${e.errorCode})');
  } catch (e) {
    print('Error: $e. Ensure `libraryPath` is correct.');
  }
}
```

## API Overview

### `FINUFFT` Class
The main class for creating and managing NUFFT plans.

-   **Constructor:**
    ```dart
    FINUFFT({
      required String libraryPath,
      required int dim,
      required List<int> nModes,
      int type = 1, // Currently only Type 1 is fully implemented in this wrapper
      int iflag = 1,
      double tolerance = 1e-6,
      bool useDoublePrecision = true,
      FinufftOptions? options,
      int nTransforms = 1,
    })
    ```

-   **Methods:**
    -   `void setPoints({required List<double> xj, List<double>? yj, List<double>? zj})`: Sets the non-uniform points.
    -   `List<Complex> execute(List<Complex> sourcesOrTargets)`: Executes the transform. For Type 1, `sourcesOrTargets` are the source strengths.
    -   `void dispose()`: Frees the native plan resources. Essential to call when done.

### `Complex` Class
Represents a complex number with `re` (real) and `im` (imaginary) properties.

### `FinufftOptions` Class
Allows setting advanced options for the FINUFFT plan. See `finufft.h` or the official FINUFFT documentation for details on these options.

### `FinufftException`
Custom exception thrown for errors originating from the native FINUFFT library.

## Contributing

Contributions are welcome! If you extend the wrapper (e.g., add full support for Type 2/3 transforms, improve error handling, add more examples), please feel free to open a pull request.

Make sure to update tests and documentation accordingly.
