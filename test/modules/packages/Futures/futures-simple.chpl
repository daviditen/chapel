use Futures;

config const X = 42;

const A = new Future(lambda(x: int) { return 2 * x; }, X);
const B = new Future(lambda(x: int) { return x + 7; }, A.get(),
                     ExecMode.Async);
const C = new Future(lambda(x: int) { return 3 * x; }, B.get(),
                     ExecMode.Defer);

writeln(C.get() == (3 * ((2 * X) + 7)));
