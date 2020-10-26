use HDF5;

record R {
  var i: int;
}

var tr = getHDF5Type(real);
var ti = getHDF5Type(int);
var tbad = getHDF5Type(R);
