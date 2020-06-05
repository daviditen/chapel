config const n = 10;

config param bt: BoundedRangeType;

var r = if bt == BoundedRangeType.bounded then 0..#n else
        if bt == BoundedRangeType.boundedLow then 0.. else
        if bt == BoundedRangeType.boundedHigh then ..n-1 else .. ;

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
