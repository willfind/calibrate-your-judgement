map_number_of_questions = function(doc) {
  emit(null, Number(doc.questionID != null));
}
