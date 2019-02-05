RandomQuestionIDs = require('views/lib/random_question_ids.js')

describe('RandomQuestionIDs', function() {

  it('produces a nonrepeating stream of numbers less than a given number and stops when it has given every number', function() {
    var number_of_questions = 5000
    var ids = new RandomQuestionIDs({ number_of_questions: number_of_questions })

    var ids_generated_so_far = []

    let i = 0
    while (i <  number_of_questions) {
      id = ids.next()

      expect(id >= 0).toEqual(true)
      expect(id <= number_of_questions).toEqual(true)
      expect(ids_generated_so_far.includes(id)).toEqual(false)

      ids_generated_so_far.push(id)
      i += 1
    }

    expect(ids.next()).toEqual(false)
  })

  describe('does not produce zero', function() {

    it('at the start of the sequence', function() {
      spyOn(Math, 'random').and.returnValue(0.001)

      var ids = new RandomQuestionIDs({ number_of_questions: 10 })

      var ids_generated = new Array(3).fill(0).map(function() { return ids.next() })

      expect(ids_generated.includes(0)).toEqual(false)
      expect(ids_generated).toEqual([1, 2, 3])
    })

    it('past the start of the sequence', function() {
      spyOn(Math, 'random').and.returnValue(0.6)
      var ids = new RandomQuestionIDs({ number_of_questions: 10 })

      var ids_generated = new Array(5).fill(0).map(function() { return ids.next() })

      expect(ids_generated.includes(0)).toEqual(false)
      expect(ids_generated).toEqual([6, 3, 10, 7, 4])
    })

  })

});
