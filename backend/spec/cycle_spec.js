describe('Cycle generation', function() {
  beforeAll(function() {
    gcd = require('views/lib/gcd.js')
    cycle = require('views/lib/cycle.js')
  });

  it('can find a random number relatively prime with the given number of questions', function() {
    number_of_questions = 1000

    for(let i = 0; i < 100; i++) {
      cycle_number = cycle(1000)
      expect(gcd(number_of_questions, cycle_number)).toEqual(1)
    }
  });
});
