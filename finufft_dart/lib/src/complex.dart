// A simple complex number class for Dart.
class Complex {
  double re;
  double im;

  Complex(this.re, this.im);

  @override
  String toString() => '(\$re \$im\i)';

  // Example:
  // static Complex from(double real, [double imag = 0.0]) => Complex(real, imag);
}
