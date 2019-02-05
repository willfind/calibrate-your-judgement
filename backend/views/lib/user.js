var User = function(request) {
  this.request = request;

  this.initialize = function() {
    this.request_body = JSON.parse(this.request.body)
    this.user_doc = this._generate_doc();
  }

  this.doc = function() {
    return this.user_doc;
  }

  this.summary = function() {
    return "{ \"id\": \"" + this.user_doc._id + "\", " + "\"master_key\": \"" + this.user_doc.master_key + "\" }"
  }

  this._generate_doc = function() {
    if (this._initial_bloom_filter()) return this._user_doc()
    return this._base_user_doc()
  }

  this._user_doc = function(options) {
    var doc = {
      _id: this.request.uuid,
      type: 'user',
      batch_number: 0,
      bloom_filter: this._initial_bloom_filter(),
      batch_size: this._batch_size(),
      master_key: this._master_key()
    }

    for (var attribute in options) doc[attribute] = options[attribute]

    return doc;
  }

  this._base_user_doc = function() {
    return this._user_doc({ _id: 'base_user', bloom_filter: this._empty_bloom_filter_base(), batch_size: 1, master_key: 'base_user' })
  }

  this._empty_bloom_filter_base = function() {
    var BloomFilter = require('views/lib/bloom_filter')
    return new BloomFilter().updated_bloom_filter()
  }

  this._initial_bloom_filter = function() {
    return this._request_param('initial_bloom_filter')
  }

  this._batch_size = function() {
    return this._request_param('batch_size')
  }

  this._master_key = function() {
    return this._request_param('master_key') || this.request.uuid
  }

  this._request_param = function(key) {
    return this.request_body[key]
  }
}

module.exports = {
  from: function(request) {
    var user = new User(request);
    user.initialize();

    return user;
  }
};
