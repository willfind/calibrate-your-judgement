module.exports = (m, n) ->
  return unless m && n
  remainder = 0
  while n != 0
    remainder = m % n
    m = n
    n = remainder
  m
