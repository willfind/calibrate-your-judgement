map_user = function(doc) {
  if (doc.type != 'user') return
  emit(doc._id, { rev: doc._rev, master_key: doc.master_key })
}
