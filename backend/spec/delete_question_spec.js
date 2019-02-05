describe('Delete question update handler', function() {
  require('updates/delete_questions')

  beforeAll(function() {
    SIZE_OF_BLOOM_FILTER = 100
    NUMBER_OF_QUESTIONS = 12
    NUMBER_OF_HASHES = 4
  })

  describe('updates the bloom filter to include the questions specified', function() {

    beforeAll(function() {
      this.initial_user_doc = { _id: 'user_id', bloom_filter: 'AAAAAAAAAAAAAAAAA=', batch_number: 1, type: 'user' }
      this.request_to_delete = function(ids) {
        return { body: JSON.stringify({ ids: ids }) }
      }
    })

    it('when only deleting one question', function() {
      var request = this.request_to_delete(['3'])
      var result = delete_questions(this.initial_user_doc, request)

      var expected_updated_user_doc = Object.assign({}, this.initial_user_doc, { bloom_filter: 'AAAAAAgAAAAAAIgAg=' })
      expect(result[0]).toEqual(expected_updated_user_doc)
      expect(result[1]).toEqual(JSON.stringify({ ok: true }))
    })

    it('when deleting multiple questions', function() {
      var request = this.request_to_delete(['3', '4', '5'])
      var result = delete_questions(this.initial_user_doc, request)

      var expected_updated_user_doc = Object.assign({}, this.initial_user_doc, { bloom_filter: 'gIAICAgAAAgAgIgAg=' })
      expect(result[0]).toEqual(expected_updated_user_doc)
    })

  })
})
