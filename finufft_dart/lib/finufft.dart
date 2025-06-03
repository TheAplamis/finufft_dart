import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

import 'src/finufft_bindings.dart' as bindings;
import 'src/complex.dart';
import 'src/finufft_options_wrapper.dart';
import 'src/exceptions.dart';

class FINUFFT implements ffi.Finalizable {
  late final bindings.FinufftNativeLib _nativeLib;
  late final ffi.Pointer _plan;

  final bool _isDoublePrecision;
  final int _dim;
  // final int _type; // Type is now fixed to 1
  final int _nTransf;

  late final int _prodNModes;
  int _M = 0;
  // int _Nk = 0; // _Nk is only for Type 3, can be removed.

  static final _finalizerToken = Expando<ffi.NativeFinalizer>();

  FINUFFT({
    required String libraryPath,
    // required int type, // Removed, will be hardcoded to 1
    required int dim,
    required List<int> nModes,
    int iflag = 1,
    double tolerance = 1e-6,
    bool useDoublePrecision = true, // Changed from this.useDoublePrecision for clarity
    FinufftOptions? options,
    int nTransforms = 1,
  }) : _isDoublePrecision = useDoublePrecision,
       _dim = dim,
       // _type = type, // type is now 1
       _nTransf = nTransforms {

    const int type1Nufft = 1; // Hardcoded for Type 1

    if (dim < 1 || dim > 3) {
      throw ArgumentError('Dimension (dim) must be 1, 2, or 3.');
    }
    if (nModes.isEmpty) {
        throw ArgumentError('nModes list cannot be empty.');
    }
    if (nModes.length != dim) {
      throw ArgumentError('nModes length must match dimension (dim).');
    }
    // No longer need to check _type public parameter

    _prodNModes = nModes.reduce((value, element) => value * element);
    if (_prodNModes == 0) throw ArgumentError("Product of nModes cannot be zero.");

    _nativeLib = bindings.FinufftNativeLib(libraryPath);

    ffi.Pointer<bindings.FinufftOpts> nativeOptsPtr = ffi.nullptr;
    if (options != null) {
      nativeOptsPtr = options.toNative(_nativeLib, _isDoublePrecision);
    } else {
      nativeOptsPtr = calloc<bindings.FinufftOpts>();
      if (_isDoublePrecision) {
        _nativeLib.finufft_default_opts(nativeOptsPtr);
      } else {
        _nativeLib.finufftf_default_opts(nativeOptsPtr);
      }
    }

    final nModesPtr = calloc<bindings.FinufftBigint>(nModes.length);
    for (int i = 0; i < nModes.length; i++) {
      nModesPtr[i] = nModes[i];
    }

    int retCode;
    if (_isDoublePrecision) {
      final planPtrPtr = calloc<ffi.Pointer<bindings.FinufftPlanDouble>>();
      retCode = _nativeLib.finufft_makeplan(
          type1Nufft, _dim, nModesPtr, iflag, _nTransf, tolerance, planPtrPtr, nativeOptsPtr); // Use type1Nufft
      if (planPtrPtr.value == ffi.nullptr && retCode == 0) {
          calloc.free(nModesPtr);
          if (nativeOptsPtr != ffi.nullptr) calloc.free(nativeOptsPtr);
          calloc.free(planPtrPtr);
          throw FinufftException('finufft_makeplan returned success code but null plan (double, type 1)');
      }
      _plan = planPtrPtr.value;
      calloc.free(planPtrPtr);
      if (retCode != 0) {
         calloc.free(nModesPtr);
         if (nativeOptsPtr != ffi.nullptr) calloc.free(nativeOptsPtr);
         throw FinufftException('Failed to create FINUFFT plan (double, type 1)', errorCode: retCode);
      }
    } else {
      final planPtrPtr = calloc<ffi.Pointer<bindings.FinufftPlanSingle>>();
      retCode = _nativeLib.finufftf_makeplan(
          type1Nufft, _dim, nModesPtr, iflag, _nTransf, tolerance.toFloat(), planPtrPtr, nativeOptsPtr); // Use type1Nufft
      if (planPtrPtr.value == ffi.nullptr && retCode == 0) {
          calloc.free(nModesPtr);
          if (nativeOptsPtr != ffi.nullptr) calloc.free(nativeOptsPtr);
          calloc.free(planPtrPtr);
          throw FinufftException('finufftf_makeplan returned success code but null plan (single, type 1)');
      }
      _plan = planPtrPtr.value;
      calloc.free(planPtrPtr);
       if (retCode != 0) {
         calloc.free(nModesPtr);
         if (nativeOptsPtr != ffi.nullptr) calloc.free(nativeOptsPtr);
         throw FinufftException('Failed to create FINUFFT plan (single, type 1)', errorCode: retCode);
      }
    }

    if (nativeOptsPtr != ffi.nullptr) calloc.free(nativeOptsPtr);
    calloc.free(nModesPtr);

    ffi.NativeFinalizer finalizer;
    if (_isDoublePrecision) {
      finalizer = ffi.NativeFinalizer(_nativeLib.finufft_destroy_ptr.cast());
    } else {
      finalizer = ffi.NativeFinalizer(_nativeLib.finufftf_destroy_ptr.cast());
    }
    finalizer.attach(this, _plan.cast(), detach: this);
    _finalizerToken[this] = finalizer;
  }

  ffi.Pointer<T> _listToNativeArray<T extends ffi.NativeType>(List<double> list, ffi.Pointer<T> Function(int count) allocator) {
      final ptr = allocator(list.length);
      if (T == ffi.Double) {
          final doublePtr = ptr.cast<ffi.Double>();
          for (int i = 0; i < list.length; i++) {
            doublePtr[i] = list[i];
          }
      } else if (T == ffi.Float) {
          final floatPtr = ptr.cast<ffi.Float>();
           for (int i = 0; i < list.length; i++) {
            floatPtr[i] = list[i].toFloat();
          }
      } else {
          calloc.free(ptr);
          throw ArgumentError("Unsupported type for _listToNativeArray: \$T");
      }
      return ptr;
  }

  ffi.Pointer<T> _complexListToNativeArray<T extends ffi.NativeType>(List<Complex> list, ffi.Pointer<T> Function(int count) allocator) {
      final ptr = allocator(list.length * 2);
      if (T == ffi.Double) {
          final doublePtr = ptr.cast<ffi.Double>();
          for (int i = 0; i < list.length; i++) {
            doublePtr[i * 2] = list[i].re;
            doublePtr[i * 2 + 1] = list[i].im;
          }
      } else if (T == ffi.Float) {
          final floatPtr = ptr.cast<ffi.Float>();
          for (int i = 0; i < list.length; i++) {
            floatPtr[i * 2] = list[i].re.toFloat();
            floatPtr[i * 2 + 1] = list[i].im.toFloat();
          }
      } else {
          calloc.free(ptr);
          throw ArgumentError("Unsupported type for _complexListToNativeArray: \$T");
      }
      return ptr;
  }

  List<Complex> _nativeComplexArrayToList<T extends ffi.NativeType>(ffi.Pointer<T> ptr, int numComplexNumbers) {
    final result = List<Complex>.generate(numComplexNumbers, (i) => Complex(0,0), growable: false);
    if (T == ffi.Double) {
        final doublePtr = ptr.cast<ffi.Double>();
        for (int i = 0; i < numComplexNumbers; i++) {
            result[i] = Complex(doublePtr[i * 2], doublePtr[i * 2 + 1]);
        }
    } else if (T == ffi.Float) {
        final floatPtr = ptr.cast<ffi.Float>();
        for (int i = 0; i < numComplexNumbers; i++) {
            result[i] = Complex(floatPtr[i * 2].toDouble(), floatPtr[i * 2 + 1].toDouble());
        }
    } else {
        throw ArgumentError("Unsupported type for _nativeComplexArrayToList: \$T");
    }
    return result;
  }

  // Simplified setPoints for Type 1 NUFFT
  void setPoints({
    required List<double> xj,
    List<double>? yj,
    List<double>? zj,
  }) {
    _M = xj.length;
    if (_M == 0) throw ArgumentError("xj (non-uniform points) cannot be empty.");

    if (_dim >= 2 && yj == null) throw ArgumentError("yj is required for dim >= 2");
    if (_dim == 3 && zj == null) throw ArgumentError("zj is required for dim == 3");
    if (_dim >= 2 && yj != null && yj.length != _M) throw ArgumentError("yj length must match xj length.");
    if (_dim == 3 && zj != null && zj.length != _M) throw ArgumentError("zj length must match xj length.");


    ffi.Pointer<ffi.NativeType> xj_ptr = ffi.nullptr, yj_ptr = ffi.nullptr, zj_ptr = ffi.nullptr;

    try {
      if (_isDoublePrecision) {
        xj_ptr = _listToNativeArray<ffi.Double>(xj, (count) => calloc<ffi.Double>(count));
        if (yj != null) yj_ptr = _listToNativeArray<ffi.Double>(yj, (count) => calloc<ffi.Double>(count));
        if (zj != null) zj_ptr = _listToNativeArray<ffi.Double>(zj, (count) => calloc<ffi.Double>(count));

        final ret = _nativeLib.finufft_setpts(
            _plan.cast<bindings.FinufftPlanDouble>(), _M,
            xj_ptr.cast<ffi.Double>(),
            yj_ptr.cast<ffi.Double>(),
            zj_ptr.cast<ffi.Double>(),
            0,                         // N (number of Type 3 targets) is 0 for Type 1
            ffi.nullptr, ffi.nullptr, ffi.nullptr // s, t, u are null for Type 1
        );
        if (ret != 0) throw FinufftException("finufft_setpts failed (double, type 1)", errorCode: ret);

      } else { // Single precision
        xj_ptr = _listToNativeArray<ffi.Float>(xj, (count) => calloc<ffi.Float>(count));
        if (yj != null) yj_ptr = _listToNativeArray<ffi.Float>(yj, (count) => calloc<ffi.Float>(count));
        if (zj != null) zj_ptr = _listToNativeArray<ffi.Float>(zj, (count) => calloc<ffi.Float>(count));

        final ret = _nativeLib.finufftf_setpts(
            _plan.cast<bindings.FinufftPlanSingle>(), _M,
            xj_ptr.cast<ffi.Float>(),
            yj_ptr.cast<ffi.Float>(),
            zj_ptr.cast<ffi.Float>(),
            0,                         // N is 0 for Type 1
            ffi.nullptr, ffi.nullptr, ffi.nullptr // s, t, u are null for Type 1
        );
        if (ret != 0) throw FinufftException("finufftf_setpts failed (single, type 1)", errorCode: ret);
      }
    } finally {
      if (xj_ptr != ffi.nullptr) calloc.free(xj_ptr);
      if (yj_ptr != ffi.nullptr) calloc.free(yj_ptr);
      if (zj_ptr != ffi.nullptr) calloc.free(zj_ptr);
    }
  }

  // Simplified execute for Type 1 NUFFT
  List<Complex> execute(List<Complex> sources) {
    // For Type 1: input sources are M strengths, output results are prodNModes Fourier coefficients.
    final int numInputComplexPerTransf = _M;
    final int numOutputComplexPerTransf = _prodNModes;

    if (_M == 0) {
        throw StateError("Number of non-uniform points (M) is 0. Call setPoints first.");
    }
    if (sources.length != numInputComplexPerTransf * _nTransf) {
      throw ArgumentError(
        "Sources length (\${sources.length}) does not match expected input size (M * nTransf = \${numInputComplexPerTransf * _nTransf}) for Type 1 transform."
      );
    }

    ffi.Pointer<ffi.NativeType> weightsPtr = ffi.nullptr;
    ffi.Pointer<ffi.NativeType> resultsPtr = ffi.nullptr;
    List<Complex> resultList = [];

    final totalOutputComplexNumbers = numOutputComplexPerTransf * _nTransf;

    try {
      if (_isDoublePrecision) {
        weightsPtr = _complexListToNativeArray<ffi.Double>(sources, (count) => calloc<ffi.Double>(count));
        resultsPtr = calloc.allocate<ffi.Double>(totalOutputComplexNumbers * 2);

        final ret = _nativeLib.finufft_execute(
            _plan.cast<bindings.FinufftPlanDouble>(),
            weightsPtr.cast<ffi.Double>(),
            resultsPtr.cast<ffi.Double>()
        );
        if (ret != 0) throw FinufftException("finufft_execute failed (double, type 1)", errorCode: ret);
        resultList = _nativeComplexArrayToList<ffi.Double>(resultsPtr.cast<ffi.Double>(), totalOutputComplexNumbers);

      } else { // Single precision
        weightsPtr = _complexListToNativeArray<ffi.Float>(sources, (count) => calloc<ffi.Float>(count));
        resultsPtr = calloc.allocate<ffi.Float>(totalOutputComplexNumbers * 2);

        final ret = _nativeLib.finufftf_execute(
            _plan.cast<bindings.FinufftPlanSingle>(),
            weightsPtr.cast<ffi.Float>(),
            resultsPtr.cast<ffi.Float>()
        );
        if (ret != 0) throw FinufftException("finufftf_execute failed (single, type 1)", errorCode: ret);
        resultList = _nativeComplexArrayToList<ffi.Float>(resultsPtr.cast<ffi.Float>(), totalOutputComplexNumbers);
      }
    } finally {
      if (weightsPtr != ffi.nullptr) calloc.free(weightsPtr);
      if (resultsPtr != ffi.nullptr) calloc.free(resultsPtr);
    }
    return resultList;
  }

  Map<String, List<Complex>> performNUFFT1D({
      required List<double> t,
      List<double>? xSignal,
      List<double>? ySignal,
      List<double>? zSignal,
  }) {
    if (_dim != 1) {
        throw StateError("performNUFFT1D is for 1D configured FINUFFT instances.");
    }

    this.setPoints(xj:t);

    Map<String, List<Complex>> resultsMap = {};

    List<Complex> _doNufftForSignal(List<double> signalValues, String signalName) {
        if (signalValues.length != _M) { // Class instance is already Type 1
            throw ArgumentError("Signal '\$signalName' length (\${signalValues.length}) must match number of time points M (\$_M) set by setPoints(xj:t).");
        }
        final complexSignal = signalValues.map((val) => Complex(val, 0.0)).toList();
        return this.execute(complexSignal);
    }

    if (xSignal != null) resultsMap['fx'] = _doNufftForSignal(xSignal, "xSignal");
    if (ySignal != null) resultsMap['fy'] = _doNufftForSignal(ySignal, "ySignal");
    if (zSignal != null) resultsMap['fz'] = _doNufftForSignal(zSignal, "zSignal");

    if (xSignal != null && ySignal != null && zSignal != null) {
        if (xSignal.length == _M && ySignal.length == _M && zSignal.length == _M) {
            final sumSignal = List<double>.generate(_M, (i) => xSignal[i] + ySignal[i] + zSignal[i]);
            resultsMap['fsum'] = _doNufftForSignal(sumSignal, "sumSignal");
        } else {
            print("Warning: x, y, z signals have different lengths than M (\$_M), cannot compute sum spectrum robustly this way.");
        }
    }
    return resultsMap;
  }

  List<double> calculateFrequencyDomain(List<double> timeVector, {bool fftShift = true}) {
    final int numModesToUse = _prodNModes;
    if (numModesToUse == 0) throw StateError("Number of modes (_prodNModes) is not initialized (was zero).");

    if (timeVector.isEmpty) return [];
    double tTotal;
    if (timeVector.length == 1) {
        tTotal = timeVector[0];
    } else {
        tTotal = timeVector.last - timeVector.first;
        if (timeVector.length > 1) {
            tTotal += (timeVector.last - timeVector.first) / (timeVector.length -1) ;
        }
    }
    if (tTotal <= 0) throw ArgumentError("Time vector must span a positive duration for frequency calculation.");

    final df = 1.0 / tTotal;
    final freqs = List<double>.filled(numModesToUse, 0.0);

    if (fftShift) {
        for (int i = 0; i < numModesToUse; i++) {
            if (i < (numModesToUse + 1) / 2) {
                freqs[i] = i * df;
            } else {
                freqs[i] = (i - numModesToUse) * df;
            }
        }
    } else {
        for (int i = 0; i < numModesToUse; i++) {
            freqs[i] = i * df;
        }
    }
    return freqs;
  }


  void dispose() {
    final finalizer = _finalizerToken[this];
    if (finalizer != null) {
      finalizer.detach(this);
      if (_isDoublePrecision) {
        _nativeLib.finufft_destroy(_plan.cast<bindings.FinufftPlanDouble>());
      } else {
        _nativeLib.finufftf_destroy(_plan.cast<bindings.FinufftPlanSingle>());
      }
      _finalizerToken[this] = null;
    }
  }
}

extension FloatConversion on double {
  double toFloat() => this;
}
