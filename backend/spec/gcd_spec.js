describe('Greatest common denominator', function() {
  beforeAll(function() {
    gcd = require('views/lib/gcd.js')
  });

  it('can get the greatest common denominator of two numbers', function() {
    expect(gcd(1, 1)).toEqual(1)
    expect(gcd(10, 20)).toEqual(10)
    expect(gcd(1234, 1236)).toEqual(2)
  })

  it('handles the case when the inputs are invalid', function() {
    expect(function() { return gcd() }).not.toThrow()
  })
})
