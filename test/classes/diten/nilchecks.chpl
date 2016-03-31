class C {
  var a, b: int;
  proc write() {
    writeln((a,b));
  }
}

proc foofoo() {
  var b: C;
  var c = new C();
  var s1: sync bool;
  var s2: sync bool;
  begin with (ref c) {
    s1;
    c = nil;
    s2 = true;
  }
  c.a = 1;
  c.b = 2;
  s1 = true;
  s2;
  c.write();
}

proc main {
  foofoo();
}
