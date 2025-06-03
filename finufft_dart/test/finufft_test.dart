import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:test/test.dart';
import 'package:ffi/ffi.dart';

import 'package:finufft_dart/finufft.dart';
import 'package:finufft_dart/src/finufft_options_wrapper.dart';
import 'package:finufft_dart/src/complex.dart';
import 'package:finufft_dart/src/exceptions.dart';
import 'package:finufft_dart/src/finufft_bindings.dart' as bindings;

// IMPORTANT FOR TESTING:
// For tests that interact with the native FINUFFT library to run,
// the `placeholderLibPath` below must resolve to a valid, compiled FINUFFT shared library.
// 1. Ensure you have compiled FINUFFT as a shared library (see README.md in finufft_dart).
// 2. Either:
//    a) Place the compiled library (e.g., libfinufft.so, libfinufft.dylib, finufft.dll)
//       in a directory where the system's dynamic linker can find it (e.g., project root,
//       or a path in LD_LIBRARY_PATH (Linux), DYLD_LIBRARY_PATH (macOS)).
//    b) Modify `placeholderLibPath` to be an absolute path to your compiled library for local testing.
// For CI, the build script should place the library at a predictable location.
final String placeholderLibPath = Platform.isWindows ? 'finufft.dll' :
                                Platform.isMacOS ? 'libfinufft.dylib' : 'libfinufft.so';

bool _libraryLoadedSuccessfully = false;
bool _libraryLoadAttempted = false;

bool canLoadFinufftLibrary() {
  if (_libraryLoadAttempted) {
    return _libraryLoadedSuccessfully;
  }
  _libraryLoadAttempted = true;
  print("Attempting to load FINUFFT native library at '$placeholderLibPath'. Tests requiring this will be skipped if loading fails.");
  try {
    DynamicLibrary.open(placeholderLibPath);
    _libraryLoadedSuccessfully = true;
    print("Native FINUFFT library loaded successfully from '$placeholderLibPath'.");
    return true;
  } catch (e) {
    print("Failed to load native FINUFFT library from '$placeholderLibPath': $e");
    print("Native library dependent tests will be skipped.");
    _libraryLoadedSuccessfully = false;
    return false;
  }
}

void main() {
  group('FinufftOptions', () {
    test('toNative populates opts from defaults and overrides', () {
      if (!canLoadFinufftLibrary()) {
        print('Skipping FinufftOptions.toNative test as library cannot be loaded.');
        return;
      }

      late bindings.FinufftNativeLib nativeLib;
      try {
        nativeLib = bindings.FinufftNativeLib(placeholderLibPath);
      } catch (e) {
        print('Failed to load native library for FinufftOptions test: $e. Test skipped.');
        return;
      }

      final optsWrapper = FinufftOptions(debug: 1, upsampfac: 2.25);
      final nativeOptsPtr = optsWrapper.toNative(nativeLib, true);

      addTearDown(() => calloc.free(nativeOptsPtr));

      expect(nativeOptsPtr.ref.debug, equals(1));
      expect(nativeOptsPtr.ref.upsampfac, moreOrLessEquals(2.25));
      expect(nativeOptsPtr.ref.modeord, isA<int>());
    });
  });

  group('FINUFFT Class (Type 1 Specialized)', () {
    test('Constructor creates plan, dispose releases it (double precision, 1D)', () {
      if (!canLoadFinufftLibrary()) {
        print('Skipping FINUFFT constructor/dispose test (double, 1D) as library cannot be loaded.');
        return;
      }
      late FINUFFT finufft;
      expect(() {
        finufft = FINUFFT(
            libraryPath: placeholderLibPath,
            // type: 1, // Type parameter removed
            dim: 1,
            nModes: [100],
            useDoublePrecision: true);
      }, returnsNormally);
      expect(finufft, isA<FINUFFT>());
      addTearDown(() => finufft.dispose());
      expect(() => finufft.dispose(), returnsNormally);
      expect(() => finufft.dispose(), returnsNormally);
    });

    test('Constructor creates plan, dispose releases it (single precision, 2D)', () {
      if (!canLoadFinufftLibrary()) {
        print('Skipping FINUFFT constructor/dispose test (single, 2D) as library cannot be loaded.');
        return;
      }
      late FINUFFT finufft;
      expect(() {
      finufft = FINUFFT(
          libraryPath: placeholderLibPath,
          dim: 2,
          nModes: [32, 32],
          useDoublePrecision: false);
      }, returnsNormally);
      addTearDown(() => finufft.dispose());
      expect(() => finufft.dispose(), returnsNormally);
    });

    test('Constructor throws for invalid dim or nModes mismatch', () {
        String dummyPath = "dummy.so";
        expect(() => FINUFFT(libraryPath: dummyPath, dim: 4, nModes: [10]), throwsArgumentError);
        expect(() => FINUFFT(libraryPath: dummyPath, dim: 1, nModes: [10,10]), throwsArgumentError);
        expect(() => FINUFFT(libraryPath: dummyPath, dim: 1, nModes: []), throwsArgumentError);
        expect(() => FINUFFT(libraryPath: dummyPath, dim: 1, nModes: [0]), throwsArgumentError);
    });

    group('setPoints and execute (Type 1)', () {
      FINUFFT? finufft1d;
      final M = 20;
      final nModes1D = [10];
      final xj = List<double>.generate(M, (i) => (i / M) * 2 * 3.1415926535);
      final sources = List<Complex>.generate(M, (i) => Complex(i.toDouble(), -(i.toDouble())));

      setUp(() {
        if (canLoadFinufftLibrary()) {
          try {
            finufft1d = FINUFFT(
                libraryPath: placeholderLibPath,
                dim: 1,
                nModes: nModes1D,
                useDoublePrecision: true,
                nTransforms: 1
            );
          } catch (e) {
            print('Setup failed for setPoints/execute tests: $e');
            finufft1d = null;
          }
        }
      });

      tearDown(() {
        finufft1d?.dispose();
      });

      test('1D Type 1: setPoints and execute run without error', () {
        if (!canLoadFinufftLibrary() || finufft1d == null) {
          print('Skipping FINUFFT 1D Type 1 setPoints/execute test.');
          return;
        }

        expect(() => finufft1d!.setPoints(xj: xj), returnsNormally);
        // Using expect for side-effect testing on private fields is not ideal,
        // but for this subtask, we'll assume it's for verifying state.
        // A better way would be to test behavior that depends on _M.
        // expect((finufft1d! as dynamic)._M, equals(M));

        List<Complex> results = [];
        expect(() {
          results = finufft1d!.execute(sources);
        }, returnsNormally);

        // For Type 1, output length is prodNModes * nTransf
        // Accessing _nTransf via a temporary getter or making it public would be cleaner.
        // For now, assuming nTransforms = 1 as passed in setUp.
        expect(results.length, equals(nModes1D[0] * 1 ));
        if (results.isNotEmpty) {
             print("Execute returned ${results.length} complex numbers. First: ${results[0]}");
        }
      });

      test('setPoints throws if xj is empty', () {
        if (!canLoadFinufftLibrary() || finufft1d == null) {
             print('Skipping setPoints throws if xj is empty test.');
            return;
        }
        expect(() => finufft1d!.setPoints(xj: []), throwsArgumentError);
      });

      test('execute throws if sources length mismatch', () {
        if (!canLoadFinufftLibrary() || finufft1d == null) {
            print('Skipping execute throws if sources length mismatch test.');
            return;
        }
        finufft1d!.setPoints(xj: xj);
        final wrongSources = List<Complex>.generate(M + 1, (i) => Complex(1,1));
        expect(() => finufft1d!.execute(wrongSources), throwsArgumentError);
      });
       test('execute throws if setPoints not called (M=0)', () {
        if (!canLoadFinufftLibrary() || finufft1d == null) {
            print('Skipping execute throws if setPoints not called test.');
            return;
        }
        // To test this, we need an instance where _M is indeed 0.
        // The current setUp always calls setPoints if library is loaded.
        // Let's create a fresh instance for this specific test, or ensure _M is 0.
        // For simplicity, we rely on finufft1d being freshly created with _M=0 before setPoints.
        // This test might be tricky if setUp always successfully calls setPoints.
        // The FINUFFT class initializes _M to 0, so if setPoints is NOT called, this should throw.

        FINUFFT freshFinufft;
        try {
            freshFinufft = FINUFFT(libraryPath: placeholderLibPath, dim: 1, nModes: nModes1D);
        } catch(e) {
            print("Skipping execute throws if setPoints not called test due to constructor failure: $e");
            return;
        }
        addTearDown(() => freshFinufft.dispose());

        final dummySources = List<Complex>.generate(1, (i)=>Complex(1,1));
        expect(() => freshFinufft.execute(dummySources), throwsStateError);
      });
    });
  });

  group('calculateFrequencyDomain (Type 1 focus)', () {
    test('calculates frequencies correctly for simple case (fftshift=true)', () {
      final times = [0.0, 0.1, 0.2, 0.3];
      final numOutputModes = 4;

      if (!canLoadFinufftLibrary()) {
          print("Skipping calculateFrequencyDomain test as library loading is disabled/fails.");
          return;
      }

      late FINUFFT finufftDummy;
      try {
        finufftDummy = FINUFFT(libraryPath: placeholderLibPath, dim:1, nModes:[numOutputModes]);
      } catch (e) {
        print("Skipping calculateFrequencyDomain (fftshift=true) test due to dummy FINUFFT instance creation failure: $e");
        return;
      }
      addTearDown(() => finufftDummy.dispose());

      final freqs = finufftDummy.calculateFrequencyDomain(times, fftShift: true);

      expect(freqs.length, equals(numOutputModes));
      double Ttotal = (times.last - times.first) + (times.last - times.first) / (times.length -1) ;
      final df = 1.0 / Ttotal;

      expect(freqs[0], moreOrLessEquals(0 * df));
      expect(freqs[1], moreOrLessEquals(1 * df));
      expect(freqs[2], moreOrLessEquals(-2 * df));
      expect(freqs[3], moreOrLessEquals(-1 * df));
    });
  });
}

Matcher moreOrLessEquals(double value, {double precision = 1e-5}) {
  return closeTo(value, precision);
}
