var D: domain(string);
var A: [D] int;

proc addPair(ref D, A, key, val) {
  D += key;
  A[key] = val;
}

addPair(D, A, "one", 1);
addPair(D, A, "two", 2);
addPair(D, A, "three", 3);
addPair(D, A, "zero", 0);
addPair(D, A, "four", 4);

var f = open("testfile.txt", iomode.cw);
var c = f.writer();

c.formatter = new owned JSONFormatter();
c.write(A);
writeln(c.formatter);
