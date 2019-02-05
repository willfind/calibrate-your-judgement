describe('Update bloom filter update', function() {
  require('updates/bloom_filter')

  beforeAll(function() {
    SIZE_OF_BLOOM_FILTER = 100
    NUMBER_OF_QUESTIONS = 1000
    NUMBER_OF_HASHES = 5
  })

  it('can update the bloom filter of a user document with a batch of ids', function() {
    var batch_of_questions = ['100', '200', '300', '400', '500']
    var request = { id: 'user_id', body: JSON.stringify({ batch: batch_of_questions }) }

    var user_doc = { _id: 'user_id', batch_number: 0, type: 'user' }

    var expected_document = { _id: 'user_id', bloom_filter: 'gIgIiAiAiIgACIiIg=', batch_number: 1, type: 'user' }
    expect(update_bloom_filter(user_doc, request)).toEqual([expected_document, JSON.stringify({ ok: true })])
  });
});
