// Generated by CoffeeScript 1.10.0
(function() {
  var RandomQuestionIDs, cycle;

  cycle = require('views/lib/cycle');

  module.exports = RandomQuestionIDs = (function() {
    function RandomQuestionIDs(arg) {
      this.number_of_questions = arg.number_of_questions;
      this.start = this._random_starting_number();
      this.cycle_step = cycle(this.number_of_questions);
    }

    RandomQuestionIDs.prototype.next = function() {
      return this._more_values() && this._next_value_in_sequence();
    };

    RandomQuestionIDs.prototype._next_value_in_sequence = function() {
      var next_value_in_sequence;
      this.next_value_to_return || (this.next_value_to_return = this.start);
      next_value_in_sequence = this.next_value_to_return;
      this._advance_to_next_value();
      return next_value_in_sequence;
    };

    RandomQuestionIDs.prototype._more_values = function() {
      return !(this.next_value_to_return === this.start);
    };

    RandomQuestionIDs.prototype._random_starting_number = function() {
      return Math.max(this._random_question_number(), 1);
    };

    RandomQuestionIDs.prototype._random_question_number = function() {
      return Math.floor(Math.random() * this.number_of_questions);
    };

    RandomQuestionIDs.prototype._advance_to_next_value = function() {
      return this.next_value_to_return = this._next_number_in_sequence();
    };

    RandomQuestionIDs.prototype._next_number_in_sequence = function() {
      return (this.next_value_to_return + this.cycle_step) % this.number_of_questions || this.number_of_questions;
    };

    return RandomQuestionIDs;

  })();

}).call(this);
