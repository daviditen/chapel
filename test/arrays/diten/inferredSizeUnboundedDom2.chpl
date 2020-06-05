config const n = 10;

config param bt: BoundedRangeType;

assert(bt != BoundedRangeType.boundedNone);

var r = if bt == BoundedRangeType.bounded then 10..#n else
        if bt == BoundedRangeType.boundedLow then 10.. else ..10+n-1;

proc inferredSizeArr(n: int) {
  var A: [0..#n] int;
  for i in A.domain {
    A[i] = i;
  }
  return A;
}

var A: [r] int = inferredSizeArr(n);
writeln(A);
writeln(A.domain);
