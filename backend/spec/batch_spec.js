describe('Batch view', function() {

  beforeAll(function() {
    BitArray = require('views/lib/bit_array')
    BloomFilter = require('views/lib/bloom_filter')
    require('views/batch/map')

    this.ids_generated_by_filter = ['batch', 'of', 'ids']
    this.bloom_filter = new BloomFilter({ size_of_bloom_filter: 2 })
    spyOn(this.bloom_filter, 'generate').and.returnValue(this.ids_generated_by_filter)
    spyOn(global, 'BloomFilter').and.returnValue(this.bloom_filter)

    emit = jasmine.createSpy('emit')
    spyOn(Math, 'random').and.returnValue(0.5)

    doc_base = { _id: 'abc123', batch_number: 1, bloom_filter: new BitArray({ size: 100 }).to_base64(), size_of_bloom_filter: 100, type: 'user' }
  });

  it('returns a batch of ids not currently included in the bloom filter for the user', function() {
    var doc = Object.assign({}, doc_base, { batch_size: 99 })

    map_batch(doc)

    expect(global.BloomFilter).toHaveBeenCalledWith({ bloom_filter: doc.bloom_filter })

    expect(this.bloom_filter.generate).toHaveBeenCalledWith({ batch_size: 99 })
    expect(emit).toHaveBeenCalledWith('abc123', { batch: this.ids_generated_by_filter })
  });

  it('uses the default batch size if the user document does not include a batch size', function() {
    var doc = Object.assign({}, doc_base)

    map_batch(doc)

    expect(this.bloom_filter.generate).toHaveBeenCalledWith({ batch_size: require('views/lib/batch_size') })
  });
});
