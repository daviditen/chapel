//  lhs: borrowed?  rhs: borrowed?  ok

class MyClass {
  var x: int;
}

var rhs: borrowed MyClass?;

var lhs: borrowed MyClass? = rhs;


