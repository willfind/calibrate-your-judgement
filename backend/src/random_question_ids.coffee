cycle = require('views/lib/cycle')

module.exports = class RandomQuestionIDs
  constructor: ({ number_of_questions: @number_of_questions })->
    @start = @_random_starting_number()
    @cycle_step = cycle(@number_of_questions)

  next: -> @_more_values() && @_next_value_in_sequence()

  _next_value_in_sequence: ->
    @next_value_to_return ||= @start

    next_value_in_sequence = @next_value_to_return
    @_advance_to_next_value()
    next_value_in_sequence

  _more_values: -> !(@next_value_to_return is @start)

  _random_starting_number: -> Math.max(@_random_question_number(), 1)

  _random_question_number: -> Math.floor(Math.random() * @number_of_questions)

  _advance_to_next_value: ->
    @next_value_to_return = @_next_number_in_sequence()

  _next_number_in_sequence: ->
    (@next_value_to_return + @cycle_step) % @number_of_questions || @number_of_questions
