/*
 * This test shows off some of Chapel's initial support for sparse
 * domains and arrays.  These features are still under development,
 * so your feedback on them is particularly valuable.
 */


config var n = 9;                       // Problem size;


const dnsDom = [1..n, 1..n];            // Dense bounding domain

var spsDom: sparse subdomain(dnsDom);   // 2D sparse subdomain of D
var spsArr: [spsDom] real;              // 2D sparse array


//
// I/O on sparse domains and arrays only prints out "non-zeroe" values;
// initially there are none, so these will both print in a degenerate manner
//
writeln("Initially, spsDom is: ", spsDom);
writeln("Initially, spsArr is: ", spsArr);
writeln();


//
// we can also do I/O more explicitly by iterating over the dense
// domain and indexing into the sparse array.  Note that it's legal to
// index into a sparse array in either its "zero" or "nonzero"
// positions; however it's only legal to assign to "nonzero"
// positions, since those are the only ones that are explicitly
// stored.
//
def writeSpsArr() {
  for (i,j) in dnsDom {
    write(spsArr(i,j), " ");
    if (j == n) then writeln();
  }
  writeln();
}


//
// Let's try that function we just wrote:
//
writeln("Printing spsArr with a dense representation:");
writeSpsArr();


//
// Chapel's sparse arrays store the element type's default value for
// their "zero" value by default -- so zeroes for numerical types,
// empty strings for strings, nil references for classes, etc.
// However, a different value can be stored at "zero" positions
// instead which is why we don't refer to it as the "zero" value and
// rather as the IRV or "Implicitly Replicated Value".  This value can
// be changed for a given array by assigning to that array's IRV
// field, allowing a more interesting value/string/class instance to
// be stored at all the "nonzero" values.
//
spsArr.IRV = 7.7;
writeln("Printing spsArr after changing its IRV:");
writeSpsArr();


//
// OK, now let's actually add some sparse indices to the DaSps domain
// and see what happens:
//
spsDom += (1,n);
spsDom += (n,n);
spsDom += (1,1);
spsDom += (n,1);

writeln("Printing spsArr after adding the corner indices:");
writeSpsArr();


//
// It appears as though nothing happened, but in fact it did.  The
// sparse domain spsDom was reallocated to store the four new (corner)
// indices; the sparse array was reallocated to allocate storage for
// the four new elements corresponding to those indices; and those
// elements were initialized to store the IRV, since that's the
// logical value that they were representing before the new sparse
// indices "filled in".  We can see this difference by going back to
// the default sparse I/O:
//
writeln("After adding corners, spsDom is:\n", spsDom);
writeln("After adding corners, spsArr is:\n", spsArr);
writeln();


//
// Or by assigning the array elements corresponding to the corners
// and using our dense printing function:
//
def computeVal(row, col) return row + col/10.0;

spsArr(1,1) = computeVal(1,1);
spsArr(1,n) = computeVal(1,n);
spsArr(n,1) = computeVal(n,1);
spsArr(n,n) = computeVal(n,n);

writeln("Printing spsArr after assigning the corner elements:");
writeSpsArr();


//
// Like other domains and arrays, sparse Chapel domains and arrays can
// be iterated over...
//

writeln("Iterating over spsDom and indexing into spsArr:");
for ij in spsDom do
  writeln("spsArr(", ij, ") = ", spsArr(ij));
writeln();

writeln("Iterating over spsArr:");
for a in spsArr do
  writeln(a, " ");
writeln();


//
// ...reductions can be taken...
//
var sparseSum = + reduce spsArr;
var denseSum = + reduce [ij in dnsDom] spsArr(ij);

writeln("the sum of the sparse elements is: ", sparseSum);
writeln("the sum of the dense elements is: ", denseSum);
writeln();

//
// ...and slices will be allowed to be taken (sparse slices of dense
// arrays, dense slices of sparse arrays, sparse slices of sparse
// arrays, etc.), but those aren't implemented yet... :(
//


//
// OK, let's clear things out and start again, this time defining a
// sparse domain whose diagonal elements are represented.
//
spsDom.clear();     // empty the sparse index set
spsArr.IRV = 0.0;   // reset the IRV

for i in 1..n do
  spsDom += (i,i);

[(i,j) in spsDom] spsArr(i,j) = computeVal(i,j);

writeln("Printing spsArr after resetting and adding the diagonal:");
writeSpsArr();


//
// Here are some other ways to enumerate sparse indices.  You can
// assign a sparse domain a tuple of indices:
//

spsDom.clear();
spsDom = ((1,1), (n/2, n/2), (n,n));

[(i,j) in spsDom] spsArr(i,j) = computeVal(i,j);

writeln("Printing spsArr after resetting and assigning a tuple of indices:");
writeSpsArr();


//
// You can also define an iterator and have it generate the sparse
// indices:
//

iterator antiDiag(n) {
  for i in 1..n do
    yield (i, n-i+1);
}

spsDom = antiDiag(n);

[(i,j) in spsDom] spsArr(i,j) = computeVal(i,j);

writeln("Printing spsArr after resetting and assigning the antiDiag iterator:");
writeSpsArr();


//
// We'll close with a brief note on performance: Chapel's default
// single-locale sparse format represents the domain using a dense
// sorted vector of explicitly represented indices and the array using
// a dense vector of elements.  This format is general, meaning that
// we can support 1D, 2D, 3D, ..., nD sparse domains and arrays in
// addition to the 2D case shown here.  However, it is also very
// general which is why we use it.  As Chapel continues to develop, it
// will support additional sparse formats that make various tradeoffs
// in efficiency and representation as part of its standard
// distribution library.  In addition, advanced users will be able to
// define their own sparse domain/array representations using the
// user-defined distribution capability.
//
// Regardless of the sparse format used, operations over a sparse
// domain's indices or sparse array's elements should typically be
// proportional to the number of nonzeroes (nnz) rather than the size
// of the dense bounding box.  Operations like inserting new indices
// or testing for membership will tend to vary depending on the
// representation.  
//
// For example, in the default representation, adding indices in
// reverse sorted order will require O(nnz**2) time due to all of the
// insertions required.  For this reason, users are encouraged to add
// indices in sorted order when performance matters.  
//
// Other general rules of thumb when working with sparse domains and
// arrays is to make the domains constant (const) whenever possible,
// setting their index set in their initializer using a forall
// expression or iterator invocation; and to assign sparse domain
// indices before declaring arrays over those sparse domains when
// possible (to avoid reallocating the arrays more than is necessary.
// While the choice of a sparse representations may make the impact of
// these decisions more or less crucial, they are good general rules
// of thumb.
//
// As a final performance-related note, there are several important
// compiler optimizations that remain unimplemented for sparse domains
// and arrays.  Today's implementation is meant to expose users to
// Chapel's sparse concepts, but additional performance will be added
// over time.
//
// Anyone reading this far who is interested in exploring more with
// sparse domains and arrays in Chapel is encouraged to contact us at
// chapel_info@cray.com.  We currently have a Compressed Sparse Row
// (CSR) sparse domain/array implementation in the works and a
// virtually complete implementation of the NAS CG benchmark that
// makes use of it, and would be happy to share those examples with
// users of the release.
