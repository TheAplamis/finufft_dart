import 'dart:ffi' as ffi;

// Define FinufftOpts struct based on finufft_opts.h
final class FinufftOpts extends ffi.Struct {
  @ffi.Int32()
  external int modeord;

  @ffi.Int32()
  external int spreadinterponly;

  @ffi.Int32()
  external int debug;

  @ffi.Int32()
  external int spread_debug;

  @ffi.Int32()
  external int showwarn;

  @ffi.Int32()
  external int nthreads;

  @ffi.Int32()
  external int fftw;

  @ffi.Int32()
  external int spread_sort;

  @ffi.Int32()
  external int spread_kerevalmeth;

  @ffi.Int32()
  external int spread_kerpad;

  @ffi.Double()
  external double upsampfac;

  @ffi.Int32()
  external int spread_thread;

  @ffi.Int32()
  external int maxbatchsize;

  @ffi.Int32()
  external int spread_nthr_atomic;

  @ffi.Int32()
  external int spread_max_sp_size;

  external ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>> fftw_lock_fun;
  external ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>> fftw_unlock_fun;
  external ffi.Pointer<ffi.Void> fftw_lock_data;
}

// Opaque plan types
final class FinufftPlanDouble extends ffi.Opaque {}
final class FinufftPlanSingle extends ffi.Opaque {}

// Typedefs for FINUFFT_BIGINT (int64_t)
typedef FinufftBigint = ffi.Int64;

// --- Double Precision Function Typedefs ---

// finufft_default_opts
typedef FinufftDefaultOptsCNative = ffi.Void Function(ffi.Pointer<FinufftOpts> opts);
typedef FinufftDefaultOptsDart = void Function(ffi.Pointer<FinufftOpts> opts);

// finufft_makeplan
typedef FinufftMakeplanCNative = ffi.Int32 Function(
    ffi.Int32 type,
    ffi.Int32 dim,
    ffi.Pointer<FinufftBigint> n_modes,
    ffi.Int32 iflag,
    ffi.Int32 n_transf,
    ffi.Double tol,
    ffi.Pointer<ffi.Pointer<FinufftPlanDouble>> plan,
    ffi.Pointer<FinufftOpts> opts);
typedef FinufftMakeplanDart = int Function(
    int type,
    int dim,
    ffi.Pointer<FinufftBigint> n_modes,
    int iflag,
    int n_transf,
    double tol,
    ffi.Pointer<ffi.Pointer<FinufftPlanDouble>> plan,
    ffi.Pointer<FinufftOpts> opts);

// finufft_setpts
typedef FinufftSetptsCNative = ffi.Int32 Function(
    ffi.Pointer<FinufftPlanDouble> plan,
    FinufftBigint M,
    ffi.Pointer<ffi.Double> xj,
    ffi.Pointer<ffi.Double> yj,
    ffi.Pointer<ffi.Double> zj,
    FinufftBigint N,
    ffi.Pointer<ffi.Double> s,
    ffi.Pointer<ffi.Double> t,
    ffi.Pointer<ffi.Double> u);
typedef FinufftSetptsDart = int Function(
    ffi.Pointer<FinufftPlanDouble> plan,
    int M, // FINUFFT_BIGINT maps to Dart int
    ffi.Pointer<ffi.Double> xj,
    ffi.Pointer<ffi.Double> yj,
    ffi.Pointer<ffi.Double> zj,
    int N, // FINUFFT_BIGINT maps to Dart int
    ffi.Pointer<ffi.Double> s,
    ffi.Pointer<ffi.Double> t,
    ffi.Pointer<ffi.Double> u);

// finufft_execute
typedef FinufftExecuteCNative = ffi.Int32 Function(
    ffi.Pointer<FinufftPlanDouble> plan,
    ffi.Pointer<ffi.Double> weights,
    ffi.Pointer<ffi.Double> result);
typedef FinufftExecuteDart = int Function(
    ffi.Pointer<FinufftPlanDouble> plan,
    ffi.Pointer<ffi.Double> weights,
    ffi.Pointer<ffi.Double> result);

// finufft_destroy
typedef FinufftDestroyCNative = ffi.Int32 Function(ffi.Pointer<FinufftPlanDouble> plan);
typedef FinufftDestroyDart = int Function(ffi.Pointer<FinufftPlanDouble> plan);

// --- Single Precision Function Typedefs ---

// finufftf_default_opts
typedef FinufftfDefaultOptsCNative = ffi.Void Function(ffi.Pointer<FinufftOpts> opts);
typedef FinufftfDefaultOptsDart = void Function(ffi.Pointer<FinufftOpts> opts);

// finufftf_makeplan
typedef FinufftfMakeplanCNative = ffi.Int32 Function(
    ffi.Int32 type,
    ffi.Int32 dim,
    ffi.Pointer<FinufftBigint> n_modes,
    ffi.Int32 iflag,
    ffi.Int32 n_transf,
    ffi.Float tol, // Single precision
    ffi.Pointer<ffi.Pointer<FinufftPlanSingle>> plan,
    ffi.Pointer<FinufftOpts> opts);
typedef FinufftfMakeplanDart = int Function(
    int type,
    int dim,
    ffi.Pointer<FinufftBigint> n_modes,
    int iflag,
    int n_transf,
    double tol, // Dart double for float tolerance
    ffi.Pointer<ffi.Pointer<FinufftPlanSingle>> plan,
    ffi.Pointer<FinufftOpts> opts);

// finufftf_setpts
typedef FinufftfSetptsCNative = ffi.Int32 Function(
    ffi.Pointer<FinufftPlanSingle> plan,
    FinufftBigint M,
    ffi.Pointer<ffi.Float> xj, // Single precision
    ffi.Pointer<ffi.Float> yj,
    ffi.Pointer<ffi.Float> zj,
    FinufftBigint N,
    ffi.Pointer<ffi.Float> s,
    ffi.Pointer<ffi.Float> t,
    ffi.Pointer<ffi.Float> u);
typedef FinufftfSetptsDart = int Function(
    ffi.Pointer<FinufftPlanSingle> plan,
    int M,
    ffi.Pointer<ffi.Float> xj,
    ffi.Pointer<ffi.Float> yj,
    ffi.Pointer<ffi.Float> zj,
    int N,
    ffi.Pointer<ffi.Float> s,
    ffi.Pointer<ffi.Float> t,
    ffi.Pointer<ffi.Float> u);

// finufftf_execute
typedef FinufftfExecuteCNative = ffi.Int32 Function(
    ffi.Pointer<FinufftPlanSingle> plan,
    ffi.Pointer<ffi.Float> weights,
    ffi.Pointer<ffi.Float> result);
typedef FinufftfExecuteDart = int Function(
    ffi.Pointer<FinufftPlanSingle> plan,
    ffi.Pointer<ffi.Float> weights,
    ffi.Pointer<ffi.Float> result);

// finufftf_destroy
typedef FinufftfDestroyCNative = ffi.Int32 Function(ffi.Pointer<FinufftPlanSingle> plan);
typedef FinufftfDestroyDart = int Function(ffi.Pointer<FinufftPlanSingle> plan);


// Class to load and hold the FINUFFT functions
class FinufftNativeLib {
  late final ffi.DynamicLibrary _dylib;

  // Double precision functions
  late final FinufftDefaultOptsDart finufft_default_opts;
  late final FinufftMakeplanDart finufft_makeplan;
  late final FinufftSetptsDart finufft_setpts;
  late final FinufftExecuteDart finufft_execute;
  late final FinufftDestroyDart finufft_destroy;
  late final ffi.Pointer<ffi.NativeFunction<FinufftDestroyCNative>> finufft_destroy_ptr; // For finalizer

  // Single precision functions
  late final FinufftfDefaultOptsDart finufftf_default_opts;
  late final FinufftfMakeplanDart finufftf_makeplan;
  late final FinufftfSetptsDart finufftf_setpts;
  late final FinufftfExecuteDart finufftf_execute;
  late final FinufftfDestroyDart finufftf_destroy;
  late final ffi.Pointer<ffi.NativeFunction<FinufftfDestroyCNative>> finufftf_destroy_ptr; // For finalizer


  FinufftNativeLib(String libraryPath) {
    _dylib = ffi.DynamicLibrary.open(libraryPath);

    // Load double precision functions
    finufft_default_opts = _dylib
        .lookup<ffi.NativeFunction<FinufftDefaultOptsCNative>>('finufft_default_opts')
        .asFunction<FinufftDefaultOptsDart>();
    finufft_makeplan = _dylib
        .lookup<ffi.NativeFunction<FinufftMakeplanCNative>>('finufft_makeplan')
        .asFunction<FinufftMakeplanDart>();
    finufft_setpts = _dylib
        .lookup<ffi.NativeFunction<FinufftSetptsCNative>>('finufft_setpts')
        .asFunction<FinufftSetptsDart>();
    finufft_execute = _dylib
        .lookup<ffi.NativeFunction<FinufftExecuteCNative>>('finufft_execute')
        .asFunction<FinufftExecuteDart>();
    finufft_destroy = _dylib
        .lookup<ffi.NativeFunction<FinufftDestroyCNative>>('finufft_destroy')
        .asFunction<FinufftDestroyDart>();
    finufft_destroy_ptr = _dylib // Added for finalizer
        .lookup<ffi.NativeFunction<FinufftDestroyCNative>>('finufft_destroy');

    // Load single precision functions
    finufftf_default_opts = _dylib
        .lookup<ffi.NativeFunction<FinufftfDefaultOptsCNative>>('finufftf_default_opts')
        .asFunction<FinufftfDefaultOptsDart>();
    finufftf_makeplan = _dylib
        .lookup<ffi.NativeFunction<FinufftfMakeplanCNative>>('finufftf_makeplan')
        .asFunction<FinufftfMakeplanDart>();
    finufftf_setpts = _dylib
        .lookup<ffi.NativeFunction<FinufftfSetptsCNative>>('finufftf_setpts')
        .asFunction<FinufftfSetptsDart>();
    finufftf_execute = _dylib
        .lookup<ffi.NativeFunction<FinufftfExecuteCNative>>('finufftf_execute')
        .asFunction<FinufftfExecuteDart>();
    finufftf_destroy = _dylib
        .lookup<ffi.NativeFunction<FinufftfDestroyCNative>>('finufftf_destroy')
        .asFunction<FinufftfDestroyDart>();
    finufftf_destroy_ptr = _dylib // Added for finalizer
        .lookup<ffi.NativeFunction<FinufftfDestroyCNative>>('finufftf_destroy');
  }
}
