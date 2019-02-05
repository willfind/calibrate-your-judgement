/**
 * Map function - use `emit(key, value)1 to generate rows in the output result.
 * @link http://docs.couchdb.org/en/latest/couchapp/ddocs.html#reduce-and-rereduce-functions
 *
 * @param {object} doc - Document Object.
 */
map_by_question_id = function(doc) {
  emit(doc.question_id, { question_id: doc.question_id, _id: doc._id, _rev: doc._rev })
}
