delete_questions = function(doc, req) {
  var import_batch = require('views/lib/import_batch')
  var ids_to_delete = JSON.parse(req.body).ids

  doc.bloom_filter = import_batch(doc.bloom_filter, ids_to_delete)

  return [doc, JSON.stringify({ ok: true })]
}
