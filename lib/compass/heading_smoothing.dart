/// Low-pass filter on compass degrees with shortest-path wrap at 0/360.
class HeadingSmoother {
  HeadingSmoother({this.alpha = 0.18});

  final double alpha;
  double? _value;

  /// Returns smoothed heading in [0, 360).
  double smooth(double headingDeg) {
    final h = headingDeg % 360;
    if (_value == null) {
      _value = h;
      return _value!;
    }
    double diff = h - _value!;
    while (diff > 180) {
      diff -= 360;
    }
    while (diff < -180) {
      diff += 360;
    }
    _value = (_value! + alpha * diff + 360) % 360;
    return _value!;
  }

  void reset() {
    _value = null;
  }
}
