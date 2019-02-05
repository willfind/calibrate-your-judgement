class BitArray
  constructor: (options) ->
    @_validate_length(options)
    @base64 = @_load_base64(options)

  bits: -> Base64Utilities.to_binary(@base64.base64)

  to_base64: -> @base64.base64

  value: ({ position: position, value: value }) -> 
    return @base64.get_value(position) unless value?

    @_validate_input(value)
    @base64.set_value(position: position, value: Number(value))

  _load_base64: (options) ->
    new Base64(@_base64_string(options))

  _base64_string: ({ base64: base64,  bits: bits, size: size }) ->
    base64 || Base64Utilities.from_binary(bits || @_empty_bit_array_of_size(size))

  _empty_bit_array_of_size: (size) ->
    0 for index in [1..size]

  _validate_input: (value) ->
    return if value == true || value == false || value == 0 || value == 1
    throw 'Input value must be a binary value (0, 1, or a boolean)'

  _validate_length: (options) ->
    return if options.base64 || @_even_number_of_bits(options)
    throw new Error('BitArray must be initialized with an even number of bits')

  _even_number_of_bits: ({ bits: bits, size: size }) ->
    (bits?.length || size) % 2 == 0

class Base64
  constructor: (@base64) ->

  get_value: (position) ->
    @_value_at(@_base64_coordinates(position))

  set_value: ({ position: position, value: value }) ->
    @_set_value_at(coordinates: @_base64_coordinates(position), value: value)

  _set_value_at: ({ coordinates: coordinates, value: value }) ->
    @_replace_character({ index: coordinates.byte, character: @_updated_base64_byte(coordinates, value) })

  _updated_base64_byte: ({ byte: byte, bit: bit }, value) ->
    binary_byte = @_binary_byte_at(byte)
    binary_byte[bit] = value
    Base64Utilities.from_binary(binary_byte)

  _replace_character: ({ index: index, character: character }) ->
    @base64 = @base64.substring(0, index) + character + @base64.substring(index + 1)

  _value_at: ({ byte: byte, bit: bit }) ->
    @_binary_byte_at(byte)[bit]

  _binary_byte_at: (byte_index) ->
    Base64Utilities.to_binary(@base64[byte_index])

  _base64_coordinates: (position) ->
    byte: Math.floor(position/6)
    bit: position % 6

class Base64Utilities
  BASE_64_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

  @to_binary: (base64) -> new Base64Utilities().to_binary(base64)

  @from_binary: (bit_array) -> new Base64Utilities().from_binary(bit_array)

  to_binary: (base64) ->
    return unless base64
    @bit_array = []
    [base64, padding] = @_separate_padding(base64)
    @_add_bits_from_base64 character for character in base64
    @_without_padded_bits(@bit_array, padding)

  from_binary: (@bit_array) ->
    base64 = ''
    chunks = @_chunks_of_six()

    padding = @_padding_for(chunks)
    @_pad(chunks)

    for chunk in chunks
      decimal = @to_decimal(chunk)
      base64 = base64 + BASE_64_CHARACTERS[decimal]

    base64 + padding

  _padding_for: (chunks) ->
    last_chunk = chunks[chunks.length - 1]
    switch last_chunk.length
      when 6 then return ''
      when 4 then return '='
      when 2 then return '=='

  _pad: (chunks) ->
    last_chunk = chunks[chunks.length-1]
    last_chunk = (last_chunk + '0000').substring(0, 6)
    chunks[chunks.length-1] = last_chunk
    chunks

  _chunks_of_six: ->
    chunks = []
    for index in [0...@bit_array.length/6]
      chunks.push(@_chunk_number(index))
    chunks

  _chunk_number: (index) ->
    @bit_array.slice(index*6, (index+1)*6).join('')

  to_decimal: (chunk) -> parseInt(chunk, 2)

  _without_padded_bits: (bits, padding) ->
    return bits unless padding.length > 0
    bits.slice(0, -2*padding.length)

  _separate_padding: (base64) ->
    padding = base64.match('=*$')[0]
    base64 = @_without_padding(base64, padding)
    [base64, padding]

  _without_padding: (base64, padding) ->
    return base64 unless padding.length > 0
    base64.slice(0, -1*padding.length)

  _add_bits_from_base64: (character) ->
    decimal = @_decimal_from_base64(character)
    binary = @_binary_from_decimal(decimal)
    @bit_array = @bit_array.concat binary

  _binary_from_decimal: (decimal) ->
    binary_characters = @_padded_binary_string(decimal).split('')
    Number(char) for char in binary_characters

  _padded_binary_string: (decimal) ->
    ('000000' + decimal.toString(2)).slice(-6)

  _decimal_from_base64: (character) ->
    BASE_64_CHARACTERS.indexOf(character)

module.exports = BitArray
