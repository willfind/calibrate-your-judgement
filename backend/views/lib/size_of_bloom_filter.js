// SIZE_OF_BLOOM_FILTER should not be a multiple of ten as the way javascript
// parses large integers from hex values leads to a lot of trailing zeroes, which
// means that modding by a multiple of ten yields unexpected repeat values
module.exports = 500002
