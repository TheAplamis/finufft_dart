import 'package:finufft_dart/finufft_dart.dart';
import 'dart:math'; // For Random and sin/cos

void main() {
  // IMPORTANT: Replace this with the actual path to your compiled FINUFFT shared library.
  // Examples:
  // - Linux:   '/path/to/your/finufft/install/lib/libfinufft.so'
  // - macOS:   '/path/to/your/finufft/install/lib/libfinufft.dylib'
  // - Windows: 'C:/path/to/your/finufft/install/bin/finufft.dll' (or libfinufft.dll)
  // Ensure the library is compiled as a SHARED library.
  final String libraryPath = 'libfinufft.so'; // Placeholder - user MUST change this
  final bool useDouble = true;
  final double tol = 1e-6;

  try {
    // Example: 1D Type 1 NUFFT (non-uniform points to uniform grid)
    final int dim = 1;
    final List<int> nModes = [100]; // Number of modes in each dimension
    final int nTransforms = 1;    // Number of transforms to compute

    // Initialize FINUFFT
    final finufft = FINUFFT(
      libraryPath: libraryPath,
      dim: dim,
      nModes: nModes,
      nTransforms: nTransforms,
      useDoublePrecision: useDouble,
      tolerance: tol,
      // iflag: 1,        // Optional: sign of Fourier transform
    );

    print('FINUFFT plan created successfully for 1D Type 1.');
    print('  Dimension: $dim');
    print('  Number of modes: $nModes');
    print('  Requested Tolerance: $tol');
    print('  Requested Precision: ${useDouble ? "double" : "single"}');

    // Generate some non-uniform points
    final int M = 20; // Number of non-uniform points
    final random = Random();
    final List<double> xj = List.generate(M, (i) => pi * (2 * random.nextDouble() - 1));

    // Set the non-uniform points in the plan
    finufft.setPoints(xj: xj);
    print('Set $M non-uniform points.');

    // Generate some source strengths (complex values) at these points
    final List<Complex> sources = List.generate(M, (i) {
      return Complex(cos(10 * xj[i]), sin(5 * xj[i]));
    });
    print('Generated $M source strengths.');

    // Execute the NUFFT
    print('Executing NUFFT...');
    final List<Complex> fourierCoeffs = finufft.execute(sources);
    print('NUFFT execution complete.');

    // Print some results
    print('Computed ${fourierCoeffs.length} Fourier coefficients:');
    for (int i = 0; i < min(5, fourierCoeffs.length); i++) {
      print('  Coeff[$i]: ${fourierCoeffs[i].re.toStringAsFixed(4)} + ${fourierCoeffs[i].im.toStringAsFixed(4)}i');
    }
    if (fourierCoeffs.length > 5) {
      print('  ...');
    }

    // Clean up the FINUFFT plan
    finufft.dispose();
    print('FINUFFT plan disposed.');

  } on FinufftException catch (e) {
    print('A FINUFFT Exception occurred:');
    print('  Message: ${e.message}');
    if (e.errorCode != null) print('  Error Code: ${e.errorCode}');
    if (e.details != null) print('  Details: ${e.details}');
  } on ArgumentError catch (e) {
    print('An ArgumentError occurred: ${e.message}');
  } catch (e, s) {
    print('An unexpected error occurred: $e');
    print('Stack trace: $s');
    print('Make sure the `libraryPath` ("$libraryPath") is correct and the native FINUFFT library is accessible.');
  }
}
