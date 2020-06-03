use Random;

config const verbose = false;

var seed = 42;

// These are generated by the C version with seed 42 an seq 1
// generated with pcg-c-basic 0.9.

// and bound 2147483649 = 2**31 + 1
var expect32_1_2_31_1 = [ 0x65838751, 0x73e37b50, 0x67664373,
                          0x712391d, 0x3edce9a3, 0x3f09fa4f ];

// and bound 3221225473 = 2**31 + 2**30 + 1
var expect32_1_2_31_30_1 = [ 0x4df1ccf9, 0x25838751, 0x58ed9e10,
                             0x33e37b50, 0x27664373, 0x6afde4a8 ];

{
  if verbose then
    writeln("Checking 32-bit RNG seq 1 bound 2**31+1");

  var bound:uint(32) = 2147483649;
  var tmprng:pcg_setseq_64_xsh_rr_32_rng;
  var tmpinc = pcg_getvalid_inc(1);

  tmprng.srandom(seed:uint, tmpinc);

  for e32 in expect32_1_2_31_1 {
    var got = tmprng.bounded_random(tmpinc, bound);

    if verbose then writef("%xu\n", got);
    assert( got == e32 );
  }
}


{
  if verbose then
    writeln("Checking 32-bit RNG seq 1 bound 2**31+2**30+1");

  var bound:uint(32) = 3221225473;
  var tmprng:pcg_setseq_64_xsh_rr_32_rng;
  var tmpinc = pcg_getvalid_inc(1);

  tmprng.srandom(seed:uint, tmpinc);

  for e32 in expect32_1_2_31_30_1 {
    var got = tmprng.bounded_random(tmpinc, bound);

    if verbose then writef("%xu\n", got);
    assert( got == e32 );
  }
}


var histo:[0..255] int;

// Check we produce every random byte
{
  var rs = createRandomStream(seed = seed, parSafe=false,
                            eltType = uint(8), algorithm=RNG.PCG);

  for i in 1..1000000 {
    var got = rs.getNext();

    histo[got] += 1;
  }

  for (h,i) in zip(histo,0..) {
    assert(h > 0);

    if verbose then writef("% 3i: %i\n", i, h);
  }
}


histo = 0;

// Check we produce every random byte with sub-range
{
  var rs = createRandomStream(seed = seed, parSafe=false,
                            eltType = uint(8), algorithm=RNG.PCG);

  for i in 1..1000000 {
    var got = rs.getNext(5, 20);
    histo[got] += 1;
  }

  for (h,i) in zip(histo,0..) {
    if 5 <= i && i <= 20 then assert(h > 0);
    else assert(h == 0);

    if verbose then writef("% 3i: %i\n", i, h);
  }
}

histo = 0;

// Check we produce every random byte with sub-range
{
  var rs = createRandomStream(seed = seed, parSafe=false,
                            eltType = uint(64), algorithm=RNG.PCG);

  for i in 1..1000000 {
    var got = rs.getNext(5, 20):int;

    histo[got] += 1;
  }

  for (h,i) in zip(histo,0..) {
    if 5 <= i && i <= 20 then assert(h > 0);
    else assert(h == 0);

    if verbose then writef("% 3i: %i\n", i, h);
  }
}


