// Generated by CoffeeScript 1.10.0
(function() {
  module.exports = function(m, n) {
    var remainder;
    if (!(m && n)) {
      return;
    }
    remainder = 0;
    while (n !== 0) {
      remainder = m % n;
      m = n;
      n = remainder;
    }
    return m;
  };

}).call(this);
