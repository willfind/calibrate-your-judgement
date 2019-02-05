describe('Users view', function() {

  require('views/users/map');

  beforeEach(function() {
    emit = jasmine.createSpy('emit')
  })

  it('ignores documents that are not users', function() {
    var random_doc = { _id: '1', a: 1, b: 2 }
    map_user(random_doc)

    expect(emit).not.toHaveBeenCalled()
  })

  it('maps the _id attribute of each user to its master_key', function() {
    var user_doc = { _id: 'abc123', _rev: '2-abcdef', type: 'user', master_key: 'randomly_generated_master_key' }

    map_user(user_doc)

    expect(emit).toHaveBeenCalledWith('abc123', { rev: '2-abcdef', master_key: 'randomly_generated_master_key' })
  })

})
