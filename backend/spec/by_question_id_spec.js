describe('Documents by question_id view', function() {

  require('views/by_question_id/map.js')

  it('maps the document by its question id', function() {
    doc = { type: 'question', question_id: 1, _id: 123, _rev: 'abc' }

    emit = jasmine.createSpy('emit')

    map_by_question_id(doc)

    expect(emit).toHaveBeenCalledWith(1, { question_id: 1, _id: 123, _rev: 'abc' })
  });
});
