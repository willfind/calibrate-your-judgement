update_bloom_filter = function(doc, req) {
  var import_batch = require('views/lib/import_batch')
  var batch = JSON.parse(req.body).batch

  doc.bloom_filter = import_batch(doc.bloom_filter, batch)
  doc.batch_number = doc.batch_number + 1;

  return [doc, JSON.stringify({ ok: true })]
}
