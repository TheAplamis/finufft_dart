import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart'; // This should provide calloc

import 'finufft_bindings.dart' as bindings;

// Wrapper for finufft_opts for easier usage in Dart.
class FinufftOptions {
  int? modeord;
  int? spreadinterponly;
  int? debug;
  int? spread_debug;
  int? showwarn;
  int? nthreads;
  int? fftw; // FFTW planner flags (e.g., 64 for FFTW_ESTIMATE)
  int? spread_sort;
  int? spread_kerevalmeth;
  int? spread_kerpad;
  double? upsampfac; // (sigma) upsampling factor
  int? spread_thread;
  int? maxbatchsize;
  int? spread_nthr_atomic;
  int? spread_max_sp_size;

  FinufftOptions({
    this.modeord,
    this.spreadinterponly,
    this.debug,
    this.spread_debug,
    this.showwarn,
    this.nthreads,
    this.fftw,
    this.spread_sort,
    this.spread_kerevalmeth,
    this.spread_kerpad,
    this.upsampfac,
    this.spread_thread,
    this.maxbatchsize,
    this.spread_nthr_atomic,
    this.spread_max_sp_size,
  });

  ffi.Pointer<bindings.FinufftOpts> toNative(bindings.FinufftNativeLib nativeLib, bool isDoublePrecision) {
    final nativeOpts = calloc<bindings.FinufftOpts>();

    if (isDoublePrecision) {
      nativeLib.finufft_default_opts(nativeOpts);
    } else {
      nativeLib.finufftf_default_opts(nativeOpts);
    }

    if (modeord != null) nativeOpts.ref.modeord = modeord!;
    if (spreadinterponly != null) nativeOpts.ref.spreadinterponly = spreadinterponly!;
    if (debug != null) nativeOpts.ref.debug = debug!;
    if (spread_debug != null) nativeOpts.ref.spread_debug = spread_debug!;
    if (showwarn != null) nativeOpts.ref.showwarn = showwarn!;
    if (nthreads != null) nativeOpts.ref.nthreads = nthreads!;
    if (fftw != null) nativeOpts.ref.fftw = fftw!;
    if (spread_sort != null) nativeOpts.ref.spread_sort = spread_sort!;
    if (spread_kerevalmeth != null) nativeOpts.ref.spread_kerevalmeth = spread_kerevalmeth!;
    if (spread_kerpad != null) nativeOpts.ref.spread_kerpad = spread_kerpad!;
    if (upsampfac != null) nativeOpts.ref.upsampfac = upsampfac!;
    if (spread_thread != null) nativeOpts.ref.spread_thread = spread_thread!;
    if (maxbatchsize != null) nativeOpts.ref.maxbatchsize = maxbatchsize!;
    if (spread_nthr_atomic != null) nativeOpts.ref.spread_nthr_atomic = spread_nthr_atomic!;
    if (spread_max_sp_size != null) nativeOpts.ref.spread_max_sp_size = spread_max_sp_size!;

    return nativeOpts;
  }
}
