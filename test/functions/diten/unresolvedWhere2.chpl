proc foo(x) where isIntegral(x) && !isReal(x) { }
proc foo(x) where isReal(x) { }
foo("bar");
