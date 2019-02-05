gcd = require('views/lib/gcd')

module.exports = (upper_bound) ->
  current = Math.floor(Math.random() * upper_bound)

  while gcd(upper_bound, current) != 1
   current += 1

  current
