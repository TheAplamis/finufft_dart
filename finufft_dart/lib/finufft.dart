import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart'; // This should provide calloc

import 'src/finufft_bindings.dart' as bindings;
import 'src/complex.dart';
import 'src/finufft_options_wrapper.dart';
import 'src/exceptions.dart';

class FINUFFT implements ffi.Finalizable {
  late final bindings.FinufftNativeLib _nativeLib;
  late final ffi.Pointer _plan;

  final bool _isDoublePrecision;
  final int _dim;
  final int _type;
  final int _nTransf;

  final List<int> _nModes;


  static final _finalizerToken = Expando<ffi.NativeFinalizer>();

  FINUFFT({
    required String libraryPath,
    required int type,
    required int dim,
    required List<int> nModes,
    int iflag = 1,
    double tolerance = 1e-6,
    bool useDoublePrecision = true,
    FinufftOptions? options,
    int nTransforms = 1,
  }) : _isDoublePrecision = useDoublePrecision,
       _dim = dim,
       _type = type,
       _nTransf = nTransforms,
       _nModes = List.from(nModes) {

    if (dim < 1 || dim > 3) {
      throw ArgumentError('Dimension (dim) must be 1, 2, or 3.');
    }
    if (nModes.length != dim) {
      throw ArgumentError('nModes length must match dimension (dim).');
    }
    if (type < 1 || type > 3) {
      throw ArgumentError('NUFFT type must be 1, 2, or 3.');
    }

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
          _type, _dim, nModesPtr, iflag, _nTransf, tolerance, planPtrPtr, nativeOptsPtr);
      if (planPtrPtr.value == ffi.nullptr && retCode == 0) {
          calloc.free(nModesPtr);
          if (nativeOptsPtr != ffi.nullptr) calloc.free(nativeOptsPtr);
          calloc.free(planPtrPtr);
          throw FinufftException('finufft_makeplan returned success code but null plan (double)');
      }
      _plan = planPtrPtr.value;
      calloc.free(planPtrPtr);
      if (retCode != 0) {
         calloc.free(nModesPtr);
         if (nativeOptsPtr != ffi.nullptr) calloc.free(nativeOptsPtr);
         throw FinufftException('Failed to create FINUFFT plan (double)', errorCode: retCode);
      }
    } else {
      final planPtrPtr = calloc<ffi.Pointer<bindings.FinufftPlanSingle>>();
      retCode = _nativeLib.finufftf_makeplan(
          _type, _dim, nModesPtr, iflag, _nTransf, tolerance.toFloat(), planPtrPtr, nativeOptsPtr);
      if (planPtrPtr.value == ffi.nullptr && retCode == 0) {
          calloc.free(nModesPtr);
          if (nativeOptsPtr != ffi.nullptr) calloc.free(nativeOptsPtr);
          calloc.free(planPtrPtr);
          throw FinufftException('finufftf_makeplan returned success code but null plan (single)');
      }
      _plan = planPtrPtr.value;
      calloc.free(planPtrPtr);
       if (retCode != 0) {
         calloc.free(nModesPtr);
         if (nativeOptsPtr != ffi.nullptr) calloc.free(nativeOptsPtr);
         throw FinufftException('Failed to create FINUFFT plan (single)', errorCode: retCode);
      }
    }

    if (nativeOptsPtr != ffi.nullptr) calloc.free(nativeOptsPtr);
    calloc.free(nModesPtr);


    ffi.NativeFinalizer finalizer;
    if (_isDoublePrecision) {
      finalizer = ffi.NativeFinalizer(_nativeLib.finufft_destroy_ptr.cast<ffi.NativeFinalizerFunction>());
    } else {
      finalizer = ffi.NativeFinalizer(_nativeLib.finufftf_destroy_ptr.cast<ffi.NativeFinalizerFunction>());
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


  void setPoints({
    required List<double> xj,
    List<double>? yj,
    List<double>? zj,
    List<double>? s,
    List<double>? t,
    List<double>? u,
  }) {
    final M = xj.length;
    final N = (_type == 3) ? (s?.length ?? 0) : 0;

    if (_dim >= 2 && yj == null) throw ArgumentError("yj is required for dim >= 2");
    if (_dim == 3 && zj == null) throw ArgumentError("zj is required for dim == 3");
    if (_type == 3 && s == null) throw ArgumentError("s is required for type 3 transform");
    if (_type == 3 && _dim >= 2 && t == null) throw ArgumentError("t is required for type 3, dim >= 2");
    if (_type == 3 && _dim == 3 && u == null) throw ArgumentError("u is required for type 3, dim == 3");

    ffi.Pointer<ffi.NativeType> xj_ptr = ffi.nullptr, yj_ptr = ffi.nullptr, zj_ptr = ffi.nullptr;
    ffi.Pointer<ffi.NativeType> s_ptr = ffi.nullptr, t_ptr = ffi.nullptr, u_ptr = ffi.nullptr;

    try {
      if (_isDoublePrecision) {
        xj_ptr = _listToNativeArray<ffi.Double>(xj, (count) => calloc<ffi.Double>(count));
        if (yj != null) yj_ptr = _listToNativeArray<ffi.Double>(yj, (count) => calloc<ffi.Double>(count));
        if (zj != null) zj_ptr = _listToNativeArray<ffi.Double>(zj, (count) => calloc<ffi.Double>(count));
        if (s != null) s_ptr = _listToNativeArray<ffi.Double>(s, (count) => calloc<ffi.Double>(count));
        if (t != null) t_ptr = _listToNativeArray<ffi.Double>(t, (count) => calloc<ffi.Double>(count));
        if (u != null) u_ptr = _listToNativeArray<ffi.Double>(u, (count) => calloc<ffi.Double>(count));

        final ret = _nativeLib.finufft_setpts(
            _plan.cast<bindings.FinufftPlanDouble>(), M,
            xj_ptr.cast<ffi.Double>(), yj_ptr.cast<ffi.Double>(), zj_ptr.cast<ffi.Double>(),
            N,
            s_ptr.cast<ffi.Double>(), t_ptr.cast<ffi.Double>(), u_ptr.cast<ffi.Double>()
        );
        if (ret != 0) throw FinufftException("finufft_setpts failed (double)", errorCode: ret);

      } else {
        xj_ptr = _listToNativeArray<ffi.Float>(xj, (count) => calloc<ffi.Float>(count));
        if (yj != null) yj_ptr = _listToNativeArray<ffi.Float>(yj, (count) => calloc<ffi.Float>(count));
        if (zj != null) zj_ptr = _listToNativeArray<ffi.Float>(zj, (count) => calloc<ffi.Float>(count));
        if (s != null) s_ptr = _listToNativeArray<ffi.Float>(s, (count) => calloc<ffi.Float>(count));
        if (t != null) t_ptr = _listToNativeArray<ffi.Float>(t, (count) => calloc<ffi.Float>(count));
        if (u != null) u_ptr = _listToNativeArray<ffi.Float>(u, (count) => calloc<ffi.Float>(count));

        final ret = _nativeLib.finufftf_setpts(
            _plan.cast<bindings.FinufftPlanSingle>(), M,
            xj_ptr.cast<ffi.Float>(), yj_ptr.cast<ffi.Float>(), zj_ptr.cast<ffi.Float>(),
            N,
            s_ptr.cast<ffi.Float>(), t_ptr.cast<ffi.Float>(), u_ptr.cast<ffi.Float>()
        );
        if (ret != 0) throw FinufftException("finufftf_setpts failed (single)", errorCode: ret);
      }
    } finally {
      if (xj_ptr != ffi.nullptr) calloc.free(xj_ptr);
      if (yj_ptr != ffi.nullptr) calloc.free(yj_ptr);
      if (zj_ptr != ffi.nullptr) calloc.free(zj_ptr);
      if (s_ptr != ffi.nullptr) calloc.free(s_ptr);
      if (t_ptr != ffi.nullptr) calloc.free(t_ptr);
      if (u_ptr != ffi.nullptr) calloc.free(u_ptr);
    }
  }

  List<Complex> execute(List<Complex> sources) {
    final numSourceElements = sources.length * _nTransf;

    int numResultElements;
    if (_type == 1 || _type == 3) {
        numResultElements = _nModes.reduce((a, b) => a * b) * _nTransf;
         if (_type == 3) {
             numResultElements = sources.length * _nTransf;
        }

    } else {
        numResultElements = numSourceElements;
    }


    ffi.Pointer<ffi.NativeType> weightsPtr = ffi.nullptr;
    ffi.Pointer<ffi.NativeType> resultsPtr = ffi.nullptr;
    List<Complex> resultList = [];

    try {
      if (_isDoublePrecision) {
        weightsPtr = _complexListToNativeArray<ffi.Double>(sources, (count) => calloc<ffi.Double>(count));
        resultsPtr = calloc.allocate<ffi.Double>(numResultElements * 2);

        final ret = _nativeLib.finufft_execute(
            _plan.cast<bindings.FinufftPlanDouble>(),
            weightsPtr.cast<ffi.Double>(),
            resultsPtr.cast<ffi.Double>()
        );
        if (ret != 0) throw FinufftException("finufft_execute failed (double)", errorCode: ret);
        resultList = _nativeComplexArrayToList<ffi.Double>(resultsPtr.cast<ffi.Double>(), numResultElements);

      } else {
        weightsPtr = _complexListToNativeArray<ffi.Float>(sources, (count) => calloc<ffi.Float>(count));
        resultsPtr = calloc.allocate<ffi.Float>(numResultElements * 2);

        final ret = _nativeLib.finufftf_execute(
            _plan.cast<bindings.FinufftPlanSingle>(),
            weightsPtr.cast<ffi.Float>(),
            resultsPtr.cast<ffi.Float>()
        );
        if (ret != 0) throw FinufftException("finufftf_execute failed (single)", errorCode: ret);
        resultList = _nativeComplexArrayToList<ffi.Float>(resultsPtr.cast<ffi.Float>(), numResultElements);
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

    Map<String, List<Complex>> results = {};

    List<Complex> processSignal(List<double> signalValues) {
        final complexSignal = signalValues.map((val) => Complex(val, 0.0)).toList();
        if (_type == 1) {
            this.setPoints(xj: t);
            return this.execute(complexSignal);
        } else if (_type == 2) {
            this.setPoints(xj: t);
            return this.execute(complexSignal);
        } else {
            throw StateError("performNUFFT1D requires Type 1 or Type 2 plan.");
        }
    }

    if (xSignal != null) results['fx'] = processSignal(xSignal);
    if (ySignal != null) results['fy'] = processSignal(ySignal);
    if (zSignal != null) results['fz'] = processSignal(zSignal);

    if (xSignal != null && ySignal != null && zSignal != null) {
        final sumSignal = List<double>.generate(t.length, (i) => xSignal[i] + ySignal[i] + zSignal[i]);
        results['fsum'] = processSignal(sumSignal);
    }
    return results;
  }

  List<double> calculateFrequencyDomain(List<double> timeVector, int numModes, {bool fftShift = true}) {
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
    if (tTotal <= 0) throw ArgumentError("Time vector must span a positive duration.");

    final df = 1.0 / tTotal;
    final freqs = List<double>.filled(numModes, 0.0);

    if (fftShift) {
        for (int i = 0; i < numModes; i++) {
            freqs[i] = (i <= numModes / 2 -1) ? i * df : (i - numModes) * df;
        }
    } else {
        for (int i = 0; i < numModes; i++) {
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
  double toFloat() {
    return this;
  }
}
