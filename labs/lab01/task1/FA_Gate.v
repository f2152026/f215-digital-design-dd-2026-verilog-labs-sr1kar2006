// FA_Gate.v
// Gate-level model of a 1-bit full adder. No delays yet -- that starts in
// Task 2. This task is purely about gate ordering.
//
// Part (a): leave this file exactly as it is, compile, and simulate.
// Part (b): AFTER completing part (a), come back and reorder the five gate
//           instantiations below into any different sequence, then
//           re-simulate with the same tb.v and compare.

module FA_Gate(
  input  a,
  input  b,
  input  cin,
  output sum,
  output cout
);
  wire ps, pc1, pc2;

  // Part (b): gates reordered (or -> top, xors swapped) -- same results prove
  //           that Verilog gate statements are concurrent, not sequential.
  // Part (c): #(2) delay added to every gate.
  or  #(2) (cout, pc1, pc2);
  and #(2) (pc2, cin, ps);
  xor #(2) (sum, cin, ps);
  and #(2) (pc1, a,   b);
  xor #(2) (ps,  a,   b);

endmodule
