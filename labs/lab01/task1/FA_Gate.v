// FA_Gate.v  --  1-bit full adder, gate-level (no delays)
module FA_Gate(
  input  a,
  input  b,
  input  cin,
  output sum,
  output cout
);
  wire ps, pc1, pc2;

  xor (ps,   a,   b);
  and (pc1,  a,   b);
  xor (sum,  cin, ps);
  and (pc2,  cin, ps);
  or  (cout, pc1, pc2);
endmodule