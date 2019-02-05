(function() {
  sha1 = require('views/lib/sha1.min')
  BitArray = require('views/lib/bit_array')
  RandomQuestionIDs = require('views/lib/random_question_ids')
  NUMBER_OF_QUESTIONS = require('views/lib/number_of_questions')
  NUMBER_OF_HASHES = require('views/lib/number_of_hashes')
  SIZE_OF_BLOOM_FILTER = require('views/lib/size_of_bloom_filter')

  function Batch(options) {
    this.batch_size = options.batch_size;
    this.ids = []

    this.push = function(id) {
      this.ids.push(String(id))
    }

    this.export = function() {
      return this.ids
    }

    this.full = function() {
      return this.ids.length >= this.batch_size
    }
  }

  BloomFilter = function BloomFilter(options) {
    if(!options) options = {}

    this.id = Math.random()
    this.size_of_bloom_filter = options.size_of_bloom_filter || SIZE_OF_BLOOM_FILTER
    this.number_of_hashes = options.number_of_hashes || NUMBER_OF_HASHES
    this.number_of_questions = options.number_of_questions || NUMBER_OF_QUESTIONS

    this.bit_array = new BitArray({ base64: options.bloom_filter, size: this.size_of_bloom_filter })

    this.updated_bloom_filter = function() {
      return this.bit_array.to_base64()
    }

    this.generate = function(options) {
      this.batch = new Batch(options)
      this._generate_batch_ids()
      return this.batch.export()
    }

    this.import = function(ids) {
      ids.forEach(this._add_to_bloom_filter, this)
    }

    this._generate_batch_ids = function() {
      while(!this._batch_complete()) this._include_next_question_id_in_batch()
    }

    this._batch_complete = function() {
      return this.batch.full() || this.no_more_ids
    }

    this._include_next_question_id_in_batch = function() {
      this._include_in_batch(this._random_unused_question_id())
    }

    this._include_in_batch = function(id) {
      if(id) {
        this._add_to_bloom_filter(id)
        this.batch.push(id)
      } else {
        this.no_more_ids = true
      }
    }

    this._add_to_bloom_filter = function(question_id) {
      this._hash_functions().forEach(function(hash_function) {
        this.bit_array.value({ position: hash_function(question_id), value: 1 })
      }.bind(this))
    }

    this._random_unused_question_id = function() {
      while(true) {
        var question_id = this._random_question_id()
        if (!this._question_already_in_bloom_filter(question_id)) return question_id;
      }
    }

    this._question_already_in_bloom_filter = function(question_id) {
      return this._hash_functions().every(function(hash_function) {
        var index_provided_by_hash = hash_function(question_id)
        return this.bit_array.value({ position: index_provided_by_hash })
      }.bind(this))
    }

    this._random_question_id = function() {
      this.random_question_ids = this.random_question_ids || new RandomQuestionIDs({ number_of_questions: this.number_of_questions })
      return this.random_question_ids.next()
    }

    this._hash_functions = function() {
      if(this.saved_hash_functions) { return this.saved_hash_functions }
      this._generate_hash_functions()
      return this.saved_hash_functions
    }

    this._generate_hash_functions = function() {
      this.saved_hash_functions = []
      for(var i = 0; i < this.number_of_hashes; i++) { this._add_hash_function_with_salt(i) }
    }

    this._add_hash_function_with_salt = function(salt) {
      this.saved_hash_functions.push(this._hash_function_with_salt(salt))
    }

    this._hash_function_with_salt = function(salt) {
      return function(input) {
        var hashed =  this._hashed_with_salt(input, salt)
        var as_decimal = parseInt(hashed, 16)
        return as_decimal % this.size_of_bloom_filter
      }.bind(this)
    }

    this._hashed_with_salt = function(input, salt) {
      return sha1.hex(salt + '_' + input)
    }
  }

  module.exports = BloomFilter;

}).call(this)
