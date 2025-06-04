#include <iostream>
#include "finufft.h" // Should be accessible via include_directories
#include <vector>
#include <complex>
#include <cmath> // For M_PI
#include <cstdint> // For int64_t

// Define M_PI if not defined (e.g., on Windows with MSVC)
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// FINUFFT's BIGINT is typically int64_t.
// Ensure BIGINT is defined if finufft.h doesn't expose it directly for C++ in this context.
#ifndef BIGINT
typedef int64_t BIGINT;
#endif

int main() {
    int type = 1; // Type 1 NUFFT
    int dim = 1;  // 1D
    BIGINT n_modes[] = {10}; // Number of modes
    int iflag = 1; // Sign of exponent in NUFFT
    int n_transf = 1; // Number of transforms
    double tol = 1e-9; // Requested tolerance
    finufft_plan plan;
    finufft_opts opts;
    finufft_default_opts(&opts);
    opts.debug = 0; // Set to 1 or 2 for more verbose output if needed

    int ier = finufft_makeplan(type, dim, n_modes, iflag, n_transf, tol, &plan, &opts);
    if (ier > 1) { // 1 is a warning, >1 is an error
        std::cerr << "Error creating plan: " << ier << std::endl;
        return 1;
    }
    std::cout << "Plan created successfully." << std::endl;

    BIGINT nj = 5; // Number of non-uniform points
    std::vector<double> xj(nj);
    std::vector<std::complex<double>> cj(nj);

    // Populate non-uniform points and coefficients
    for (BIGINT i = 0; i < nj; ++i) {
        xj[i] = M_PI * ( (double)rand() / RAND_MAX * 2.0 - 1.0); // Random points in [-pi, pi)
        cj[i] = { (double)rand() / RAND_MAX, (double)rand() / RAND_MAX };
    }

    ier = finufft_setpts(plan, nj, xj.data(), nullptr, nullptr, 0, nullptr, nullptr, nullptr);
    if (ier > 1) {
        std::cerr << "Error setting points: " << ier << std::endl;
        finufft_destroy(plan);
        return 1;
    }
    std::cout << "Points set successfully." << std::endl;

    std::vector<std::complex<double>> fk(n_modes[0]);
    ier = finufft_execute(plan, cj.data(), fk.data());
    if (ier > 1) {
        std::cerr << "Error executing NUFFT: " << ier << std::endl;
        finufft_destroy(plan);
        return 1;
    }
    std::cout << "NUFFT executed successfully." << std::endl;

    // Print some results (optional)
    for (BIGINT i = 0; i < n_modes[0]; ++i) {
        std::cout << "fk[" << i << "] = (" << fk[i].real() << ", " << fk[i].imag() << ")" << std::endl;
    }

    ier = finufft_destroy(plan);
    if (ier != 0) {
        std::cerr << "Error destroying plan: " << ier << std::endl;
        return 1;
    }
    std::cout << "Plan destroyed successfully." << std::endl;
    std::cout << "Minimal FINUFFT test completed." << std::endl;

    return 0;
}
