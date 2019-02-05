describe('BitArray', function() {

  beforeAll(function() {
    BitArray = require('views/lib/bit_array.js')
  });

  it('can initialize a BitArray of 0s', function() {
    bit_array = new BitArray({ size: 10 });
    expect(bit_array.bits()).toEqual([0,0,0,0,0,0,0,0,0,0])
  });

  it('can initialize a BitArray from an array', function() {
    bit_array = new BitArray({ bits: [0,1,0,1] })
    expect(bit_array.bits()).toEqual([0,1,0,1])
  });

  it('must be initialized with an even number of bits', function() {
    expect(function() { new BitArray({ size: 7 }) }).toThrow(new Error('BitArray must be initialized with an even number of bits'));
    expect(function() { new BitArray({ bits: [0,1,0] }) }).toThrow(new Error('BitArray must be initialized with an even number of bits'));
  });

  it('can set a bit at a position', function() {
    bit_array = new BitArray({ size: 10 });
    bit_array.value({ position: 3, value: 1 })

    expect(bit_array.value({ position: 3 })).toEqual(1)
    expect(bit_array.bits()).toEqual([0,0,0,1,0,0,0,0,0,0])

    bit_array.value({ position: 3, value: 0 })

    expect(bit_array.value({ position: 3 })).toEqual(0)
    expect(bit_array.bits()).toEqual([0,0,0,0,0,0,0,0,0,0])

    bit_array.value({ position: 9, value: true })
    expect(bit_array.value({ position: 9 })).toEqual(1)
    expect(bit_array.bits()).toEqual([0,0,0,0,0,0,0,0,0,1])

    bit_array.value({ position: 9, value: false })
    expect(bit_array.value({ position: 9 })).toEqual(0)
    expect(bit_array.bits()).toEqual([0,0,0,0,0,0,0,0,0,0])
  });

  it('requires the input value to be 0, 1, or a boolean', function() {
    bit_array = new BitArray({ size: 10 });

    expect(function() { bit_array.value({ position: 0, value: 2 }) }).toThrow('Input value must be a binary value (0, 1, or a boolean)');
    expect(function() { bit_array.value({ position: 0, value: 'hi' }) }).toThrow('Input value must be a binary value (0, 1, or a boolean)');
  });

  it('can encode itself to base64', function() {
    bit_array_1 = new BitArray({ bits: [0,1,0,1,1,0] });

    expect(bit_array_1.to_base64()).toEqual('W');

    bit_array_2 = new BitArray({ bits: [0,1,0,0,1,0,1,1,0,0,0,0] });

    expect(bit_array_2.to_base64()).toEqual('Sw');

    bit_array_3 = new BitArray({ bits: [0,1,0,0,1,0,1,1,0,0] });

    expect(bit_array_3.to_base64()).toEqual('Sw=');

    bit_array_4 = new BitArray({ bits: [0,1,0,0,1,0,1,1] });

    expect(bit_array_4.to_base64()).toEqual('Sw==');
  });

  it('can be constructed from a base64 string', function() {
    bit_array_1 = new BitArray({ base64: 'W' });

    expect(bit_array_1.bits()).toEqual([0,1,0,1,1,0]);

    expect(bit_array_1.to_base64()).toEqual('W');

    bit_array_2 = new BitArray({ base64: 'Sw=' });

    expect(bit_array_2.bits()).toEqual([0,1,0,0,1,0,1,1,0,0])

    expect(bit_array_2.to_base64()).toEqual('Sw=');

    bit_array_3 = new BitArray({ base64: 'Sw==' });

    expect(bit_array_3.bits()).toEqual([0,1,0,0,1,0,1,1])

    expect(bit_array_3.to_base64()).toEqual('Sw==');
  })
})
