require('updates/create_user.js')

describe('Create user update', function() {

  beforeAll(function() {
    SIZE_OF_BLOOM_FILTER = 50
  })

  it('creates a base user doc if no initial bloom filter specified', function() {
    var request = { uuid: 'id_generated_by_request', body: JSON.stringify({ batch_size: 10 }) }

    var empty_bloom_filter_base = new BloomFilter({ size_of_bloom_filter: 50 }).updated_bloom_filter()

    var expected_document = {
      _id: 'base_user',
      type: 'user',
      batch_size: 1,
      batch_number: 0,
      bloom_filter: empty_bloom_filter_base,
      master_key: 'base_user'
    }

    expect(create_user(undefined, request)).toEqual([expected_document, '{ "id": "base_user", "master_key": "base_user" }'])
  })

  it('can create a new user document given an initial bloom filter', function() {
    var request = { uuid: 'id_generated_by_request', body: JSON.stringify({ batch_size: 10, initial_bloom_filter: 'AAAAAAAAAA' }) }

    var expected_document = {
      _id: 'id_generated_by_request',
      type: 'user',
      bloom_filter: 'AAAAAAAAAA',
      batch_number: 0,
      batch_size: 10,
      master_key: 'id_generated_by_request'
    }

    expect(create_user(undefined, request)).toEqual([expected_document, "{ \"id\": \"id_generated_by_request\", \"master_key\": \"id_generated_by_request\" }"])
  });

  it('handles the case when no batch size is specified', function() {
    var request = { uuid: 'id_generated_by_request', body: JSON.stringify({ initial_bloom_filter: 'AAAAAAAAAA' }) }

    var expected_document = {
      _id: 'id_generated_by_request',
      bloom_filter: 'AAAAAAAAAA',
      batch_number: 0,
      type: 'user',
      batch_size: undefined,
      master_key: 'id_generated_by_request'
    }

    expect(create_user(undefined, request)).toEqual([expected_document, "{ \"id\": \"id_generated_by_request\", \"master_key\": \"id_generated_by_request\" }"])
  });

  it('can specify a master key when creating a user', function() {
    var request = { uuid: 'id_generated_by_request', body: JSON.stringify({ master_key: 'some_other_key', initial_bloom_filter: 'AAAAAAAAAA' }) }

    var expected_document = {
      _id: 'id_generated_by_request',
      bloom_filter: 'AAAAAAAAAA',
      batch_number: 0,
      type: 'user',
      batch_size: undefined,
      master_key: 'some_other_key'
    }

    expect(create_user(undefined, request)).toEqual([expected_document, "{ \"id\": \"id_generated_by_request\", \"master_key\": \"some_other_key\" }"])
  })

});
