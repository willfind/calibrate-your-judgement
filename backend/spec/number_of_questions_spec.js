describe('Questions view', function() {

  beforeEach(function() {
    require('views/number_of_questions/map.js')
    emit = jasmine.createSpy('emit')
  });

  it('counts questions', function() {
    map_number_of_questions({ type: 'number', questionID: 1 })
    expect(emit).toHaveBeenCalledWith(null, 1)

    map_number_of_questions({ type: 'true-false', questionID: 1231 })
    expect(emit).toHaveBeenCalledWith(null, 1)
  })

  it('counts questions regardless of their type', function() {
    map_number_of_questions({ type: 'defined in the future', questionID: 5435 })

    expect(emit).toHaveBeenCalledWith(null, 1)
  })

  it('does not count users', function() {
    map_number_of_questions({ type: 'user', user_id: 1 })

    expect(emit).toHaveBeenCalledWith(null, 0)
  });

  it('does not count docs that do not look like questions', function() {
    map_number_of_questions({ a: 1, b: 2 })

    expect(emit).toHaveBeenCalledWith(null, 0)
  })

});
