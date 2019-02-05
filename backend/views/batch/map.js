map_batch = function(doc) {
  if(typeof BloomFilter == 'undefined') { BloomFilter = require('views/lib/bloom_filter') }

  BATCH_SIZE = require('views/lib/batch_size')

  if(doc.type != 'user') return
  var bloom_filter = new BloomFilter({ bloom_filter: doc.bloom_filter })

  emit(doc._id, { batch: bloom_filter.generate({ batch_size: doc.batch_size || BATCH_SIZE }) })
}
