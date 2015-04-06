// tan.chpl
// 
// Test the tan function.
//

var re32a: real(32) = -0.653338667:real(32);
var re32b: real(32) = -0.0:real(32);
var re32c: real(32) = 0.0:real(32);
var re32d: real(32) = 0.814420537:real(32);

var re64a: real(64) = -0.988837303;
var re64b: real(64) = -0.0;
var re64c: real(64) = 0.0;
var re64d: real(64) = 0.153876293;


writeln("re32a = ", re32a, " tan(re32a) = ", tan(re32a));
writeln("re32b = ", re32b, " tan(re32b) = ", tan(re32b));
writeln("re32c = ", re32c, " tan(re32c) = ", tan(re32c));
writeln("re32d = ", re32d, " tan(re32d) = ", tan(re32d));

writeln("re64a = ", re64a, " tan(re64a) = ", tan(re64a));
writeln("re64b = ", re64b, " tan(re64b) = ", tan(re64b));
writeln("re64c = ", re64c, " tan(re64c) = ", tan(re64c));
writeln("re64d = ", re64d, " tan(re64d) = ", tan(re64d));
