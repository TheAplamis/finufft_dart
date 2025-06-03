/// Dart wrapper for the FINUFFT library, providing access to Non-uniform Fast Fourier Transforms.
///
/// This library allows you to create FINUFFT plans, set points, execute transforms,
/// and manage options for the underlying native FINUFFT C++ library.
library finufft_dart;

export 'finufft.dart' show FINUFFT;
export 'src/complex.dart' show Complex;
export 'src/exceptions.dart' show FinufftException;
export 'src/finufft_options_wrapper.dart' show FinufftOptions;
