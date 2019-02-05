describe('Bloom Filter', function() {

  beforeAll(function() {
    BloomFilter = require('views/lib/bloom_filter.js')
  })

  beforeEach(function() {
    this.mock_random_sequence = function(...sequence) {
      random_ids = new RandomQuestionIDs({ number_of_questions: 1000 })
      spyOn(random_ids, 'next').and.returnValues(...sequence)
      spyOn(global, 'RandomQuestionIDs').and.returnValue(random_ids)
    }
  })

  it('can generate a batch of question ids', function() {
    this.mock_random_sequence(100, 100, 200, 200, 300, 300, 400, 400, 500, 500)

    var bit_array = new BitArray({ size: 100 }).to_base64()
    var bloom_filter = new BloomFilter({ number_of_questions: 1000, number_of_hashes: 5, size_of_bloom_filter: 100, bloom_filter: bit_array })

    var expected_batch = ["100", "200", "300", "400", "500"]

    expect(bloom_filter.generate({ batch_size: 5 })).toEqual(expected_batch)
    expected_bloom_filter = 'gIgIiAiAiIgACIiIg='
    expect(bloom_filter.updated_bloom_filter()).toEqual(expected_bloom_filter)
  });

  it('stops generating batch when it gets a false question ID', function() {
    this.mock_random_sequence(100, 200, 300, false, 400)

    var bloom_filter = new BloomFilter({ number_of_questions: 1000, number_of_hashes: 5, size_of_bloom_filter: 100 })

    expect(bloom_filter.generate({ batch_size: 5 })).toEqual(["100", "200", "300"])
  })

  it('correctly imports an exported bloom filter', function() {
    this.mock_random_sequence(100, 200, 300, 400, 500, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950)

    var bloom_filter_1 = new BloomFilter({ number_of_questions: 1000, number_of_hashes: 5, size_of_bloom_filter: 1002 })

    bloom_filter_1.generate({ batch_size: 5 })

    var exported_bloom_filter = bloom_filter_1.updated_bloom_filter()

    var bloom_filter_2 = new BloomFilter({ number_of_questions: 1000, number_of_hashes: 5, size_of_bloom_filter: 1002, bloom_filter: exported_bloom_filter })

    expect(bloom_filter_2.generate({ batch_size: 5 })).toEqual(['600', '700', '800', '900', '950'])
  });

  it('can import a batch of ids', function() {
    var ids = ["100", "200", "300", "400", "500"]

    var bloom_filter = new BloomFilter({ number_of_questions: 1000, number_of_hashes: 5, size_of_bloom_filter: 100 })

    bloom_filter.import(ids)

    var expected_bloom_filter = 'gIgIiAiAiIgACIiIg='

    expect(bloom_filter.updated_bloom_filter()).toEqual(expected_bloom_filter)
  })

  it('prematurely ends the batch if the sequence of new random ids ends', function() {
    this.mock_random_sequence(100, 200, 300, false)

    var bloom_filter = new BloomFilter({ number_of_questions: 1000, number_of_hashes: 5, size_of_bloom_filter: 100 })

    var expected_bit_array = 'AIgIiAAAAIAACIiIg='

    expect(bloom_filter.generate({ batch_size: 5 })).toEqual(['100', '200', '300'])
    expect(bloom_filter.updated_bloom_filter()).toEqual(expected_bit_array)
  })

})
