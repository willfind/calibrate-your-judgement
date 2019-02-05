module.exports = function(initial_filter, batch) {
  var BloomFilter = require('views/lib/bloom_filter')

  var bloom_filter = new BloomFilter({
    bloom_filter: initial_filter
  })

  bloom_filter.import(batch)
  return bloom_filter.updated_bloom_filter()
}
