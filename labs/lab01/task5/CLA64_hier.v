// cla64_hier.v
// BONUS -- open-ended. No detailed scaffold is provided; this is meant to
// be a genuine design exercise. Not required for lab submission.
//
// Structure:
//   - 16 four-bit CLA blocks (cla4.v, unchanged interface)
//   - Block-level G/P computed externally from raw a/b bits (no cla4 changes needed)
//   - Second-level 16-input CLA computes each block's carry-in directly
//   - Each cla4 block then computes its 4 sum bits given the correct carry-in

module cla64_hier(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);

  // ------------------------------------------------------------------
  // Step 1: bit-level P and G for all 64 bits
  // ------------------------------------------------------------------
  wire [63:0] p_bit, g_bit;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : gen_pg_bit
      xor #(2) (p_bit[i], a[i], b[i]);
      and #(2) (g_bit[i], a[i], b[i]);
    end
  endgenerate

  // ------------------------------------------------------------------
  // Step 2: block-level G and P for each of the 16 four-bit blocks
  //   P_blk[k] = p3 & p2 & p1 & p0  (carry sails through whole block)
  //   G_blk[k] = g3 | p3.g2 | p3.p2.g1 | p3.p2.p1.g0
  //              (= block cout when cin = 0; same form as cla4's c4 without cin term)
  // ------------------------------------------------------------------
  wire [15:0] P_blk, G_blk;
  genvar k;
  generate
    for (k = 0; k < 16; k = k + 1) begin : gen_blk_pg
      // Convenience: base bit index for this block
      localparam B = 4*k;

      // P_blk[k]
      and #(2) (P_blk[k], p_bit[B+3], p_bit[B+2], p_bit[B+1], p_bit[B]);

      // G_blk[k] = g3 | p3.g2 | p3.p2.g1 | p3.p2.p1.g0
      wire t_ga, t_gb, t_gc;
      and #(2) (t_ga, p_bit[B+3], g_bit[B+2]);
      and #(2) (t_gb, p_bit[B+3], p_bit[B+2], g_bit[B+1]);
      and #(2) (t_gc, p_bit[B+3], p_bit[B+2], p_bit[B+1], g_bit[B]);
      or  #(2) (G_blk[k], g_bit[B+3], t_ga, t_gb, t_gc);
    end
  endgenerate

  // ------------------------------------------------------------------
  // Step 3: second-level CLA -- computes carry-in for each of the 16 blocks
  //   C_blk[0] = cin
  //   C_blk[k] = G_blk[k-1] | P_blk[k-1].G_blk[k-2] | ... | P_blk[k-1]..P_blk[0].cin
  // (same two-level form as cla4; just 16 "bits" instead of 4)
  // ------------------------------------------------------------------
  wire [15:0] C_blk;  // carry-in to each block; C_blk[0] = cin
  assign C_blk[0] = cin;

  // C_blk[1] = G_blk[0] | P_blk[0].cin
  wire t1_0;
  and #(2) (t1_0, P_blk[0], cin);
  or  #(2) (C_blk[1], G_blk[0], t1_0);

  // C_blk[2] = G_blk[1] | P_blk[1].G_blk[0] | P_blk[1].P_blk[0].cin
  wire t2_0, t2_1;
  and #(2) (t2_0, P_blk[1], G_blk[0]);
  and #(2) (t2_1, P_blk[1], P_blk[0], cin);
  or  #(2) (C_blk[2], G_blk[1], t2_0, t2_1);

  // C_blk[3]
  wire t3_0, t3_1, t3_2;
  and #(2) (t3_0, P_blk[2], G_blk[1]);
  and #(2) (t3_1, P_blk[2], P_blk[1], G_blk[0]);
  and #(2) (t3_2, P_blk[2], P_blk[1], P_blk[0], cin);
  or  #(2) (C_blk[3], G_blk[2], t3_0, t3_1, t3_2);

  // C_blk[4]
  wire t4_0, t4_1, t4_2, t4_3;
  and #(2) (t4_0, P_blk[3], G_blk[2]);
  and #(2) (t4_1, P_blk[3], P_blk[2], G_blk[1]);
  and #(2) (t4_2, P_blk[3], P_blk[2], P_blk[1], G_blk[0]);
  and #(2) (t4_3, P_blk[3], P_blk[2], P_blk[1], P_blk[0], cin);
  or  #(2) (C_blk[4], G_blk[3], t4_0, t4_1, t4_2, t4_3);

  // C_blk[5]
  wire t5_0, t5_1, t5_2, t5_3, t5_4;
  and #(2) (t5_0, P_blk[4], G_blk[3]);
  and #(2) (t5_1, P_blk[4], P_blk[3], G_blk[2]);
  and #(2) (t5_2, P_blk[4], P_blk[3], P_blk[2], G_blk[1]);
  and #(2) (t5_3, P_blk[4], P_blk[3], P_blk[2], P_blk[1], G_blk[0]);
  and #(2) (t5_4, P_blk[4], P_blk[3], P_blk[2], P_blk[1], P_blk[0], cin);
  or  #(2) (C_blk[5], G_blk[4], t5_0, t5_1, t5_2, t5_3, t5_4);

  // C_blk[6]
  wire t6_0, t6_1, t6_2, t6_3, t6_4, t6_5;
  and #(2) (t6_0, P_blk[5], G_blk[4]);
  and #(2) (t6_1, P_blk[5], P_blk[4], G_blk[3]);
  and #(2) (t6_2, P_blk[5], P_blk[4], P_blk[3], G_blk[2]);
  and #(2) (t6_3, P_blk[5], P_blk[4], P_blk[3], P_blk[2], G_blk[1]);
  and #(2) (t6_4, P_blk[5], P_blk[4], P_blk[3], P_blk[2], P_blk[1], G_blk[0]);
  and #(2) (t6_5, P_blk[5], P_blk[4], P_blk[3], P_blk[2], P_blk[1], P_blk[0], cin);
  or  #(2) (C_blk[6], G_blk[5], t6_0, t6_1, t6_2, t6_3, t6_4, t6_5);

  // C_blk[7]
  wire t7_0, t7_1, t7_2, t7_3, t7_4, t7_5, t7_6;
  and #(2) (t7_0, P_blk[6], G_blk[5]);
  and #(2) (t7_1, P_blk[6], P_blk[5], G_blk[4]);
  and #(2) (t7_2, P_blk[6], P_blk[5], P_blk[4], G_blk[3]);
  and #(2) (t7_3, P_blk[6], P_blk[5], P_blk[4], P_blk[3], G_blk[2]);
  and #(2) (t7_4, P_blk[6], P_blk[5], P_blk[4], P_blk[3], P_blk[2], G_blk[1]);
  and #(2) (t7_5, P_blk[6], P_blk[5], P_blk[4], P_blk[3], P_blk[2], P_blk[1], G_blk[0]);
  and #(2) (t7_6, P_blk[6], P_blk[5], P_blk[4], P_blk[3], P_blk[2], P_blk[1], P_blk[0], cin);
  or  #(2) (C_blk[7], G_blk[6], t7_0, t7_1, t7_2, t7_3, t7_4, t7_5, t7_6);

  // C_blk[8]
  wire t8_0, t8_1, t8_2, t8_3, t8_4, t8_5, t8_6, t8_7;
  and #(2) (t8_0, P_blk[7], G_blk[6]);
  and #(2) (t8_1, P_blk[7], P_blk[6], G_blk[5]);
  and #(2) (t8_2, P_blk[7], P_blk[6], P_blk[5], G_blk[4]);
  and #(2) (t8_3, P_blk[7], P_blk[6], P_blk[5], P_blk[4], G_blk[3]);
  and #(2) (t8_4, P_blk[7], P_blk[6], P_blk[5], P_blk[4], P_blk[3], G_blk[2]);
  and #(2) (t8_5, P_blk[7], P_blk[6], P_blk[5], P_blk[4], P_blk[3], P_blk[2], G_blk[1]);
  and #(2) (t8_6, P_blk[7], P_blk[6], P_blk[5], P_blk[4], P_blk[3], P_blk[2], P_blk[1], G_blk[0]);
  and #(2) (t8_7, P_blk[7], P_blk[6], P_blk[5], P_blk[4], P_blk[3], P_blk[2], P_blk[1], P_blk[0], cin);
  or  #(2) (C_blk[8], G_blk[7], t8_0, t8_1, t8_2, t8_3, t8_4, t8_5, t8_6, t8_7);

  // C_blk[9..15]: same expanding pattern; using intermediate wires per term
  // C_blk[9]
  wire t9_0,t9_1,t9_2,t9_3,t9_4,t9_5,t9_6,t9_7,t9_8;
  and #(2)(t9_0,P_blk[8],G_blk[7]);
  and #(2)(t9_1,P_blk[8],P_blk[7],G_blk[6]);
  and #(2)(t9_2,P_blk[8],P_blk[7],P_blk[6],G_blk[5]);
  and #(2)(t9_3,P_blk[8],P_blk[7],P_blk[6],P_blk[5],G_blk[4]);
  and #(2)(t9_4,P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],G_blk[3]);
  and #(2)(t9_5,P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],G_blk[2]);
  and #(2)(t9_6,P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],G_blk[1]);
  and #(2)(t9_7,P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],G_blk[0]);
  and #(2)(t9_8,P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],P_blk[0],cin);
  or  #(2)(C_blk[9],G_blk[8],t9_0,t9_1,t9_2,t9_3,t9_4,t9_5,t9_6,t9_7,t9_8);

  // C_blk[10]
  wire ta_0,ta_1,ta_2,ta_3,ta_4,ta_5,ta_6,ta_7,ta_8,ta_9;
  and #(2)(ta_0,P_blk[9],G_blk[8]);
  and #(2)(ta_1,P_blk[9],P_blk[8],G_blk[7]);
  and #(2)(ta_2,P_blk[9],P_blk[8],P_blk[7],G_blk[6]);
  and #(2)(ta_3,P_blk[9],P_blk[8],P_blk[7],P_blk[6],G_blk[5]);
  and #(2)(ta_4,P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],G_blk[4]);
  and #(2)(ta_5,P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],G_blk[3]);
  and #(2)(ta_6,P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],G_blk[2]);
  and #(2)(ta_7,P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],G_blk[1]);
  and #(2)(ta_8,P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],G_blk[0]);
  and #(2)(ta_9,P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],P_blk[0],cin);
  or  #(2)(C_blk[10],G_blk[9],ta_0,ta_1,ta_2,ta_3,ta_4,ta_5,ta_6,ta_7,ta_8,ta_9);

  // C_blk[11]
  wire tb_0,tb_1,tb_2,tb_3,tb_4,tb_5,tb_6,tb_7,tb_8,tb_9,tb_10;
  and #(2)(tb_0, P_blk[10],G_blk[9]);
  and #(2)(tb_1, P_blk[10],P_blk[9],G_blk[8]);
  and #(2)(tb_2, P_blk[10],P_blk[9],P_blk[8],G_blk[7]);
  and #(2)(tb_3, P_blk[10],P_blk[9],P_blk[8],P_blk[7],G_blk[6]);
  and #(2)(tb_4, P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],G_blk[5]);
  and #(2)(tb_5, P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],G_blk[4]);
  and #(2)(tb_6, P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],G_blk[3]);
  and #(2)(tb_7, P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],G_blk[2]);
  and #(2)(tb_8, P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],G_blk[1]);
  and #(2)(tb_9, P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],G_blk[0]);
  and #(2)(tb_10,P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],P_blk[0],cin);
  or  #(2)(C_blk[11],G_blk[10],tb_0,tb_1,tb_2,tb_3,tb_4,tb_5,tb_6,tb_7,tb_8,tb_9,tb_10);

  // C_blk[12]
  wire tc_0,tc_1,tc_2,tc_3,tc_4,tc_5,tc_6,tc_7,tc_8,tc_9,tc_10,tc_11;
  and #(2)(tc_0, P_blk[11],G_blk[10]);
  and #(2)(tc_1, P_blk[11],P_blk[10],G_blk[9]);
  and #(2)(tc_2, P_blk[11],P_blk[10],P_blk[9],G_blk[8]);
  and #(2)(tc_3, P_blk[11],P_blk[10],P_blk[9],P_blk[8],G_blk[7]);
  and #(2)(tc_4, P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],G_blk[6]);
  and #(2)(tc_5, P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],G_blk[5]);
  and #(2)(tc_6, P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],G_blk[4]);
  and #(2)(tc_7, P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],G_blk[3]);
  and #(2)(tc_8, P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],G_blk[2]);
  and #(2)(tc_9, P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],G_blk[1]);
  and #(2)(tc_10,P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],G_blk[0]);
  and #(2)(tc_11,P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],P_blk[0],cin);
  or  #(2)(C_blk[12],G_blk[11],tc_0,tc_1,tc_2,tc_3,tc_4,tc_5,tc_6,tc_7,tc_8,tc_9,tc_10,tc_11);

  // C_blk[13]
  wire td_0,td_1,td_2,td_3,td_4,td_5,td_6,td_7,td_8,td_9,td_10,td_11,td_12;
  and #(2)(td_0, P_blk[12],G_blk[11]);
  and #(2)(td_1, P_blk[12],P_blk[11],G_blk[10]);
  and #(2)(td_2, P_blk[12],P_blk[11],P_blk[10],G_blk[9]);
  and #(2)(td_3, P_blk[12],P_blk[11],P_blk[10],P_blk[9],G_blk[8]);
  and #(2)(td_4, P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],G_blk[7]);
  and #(2)(td_5, P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],G_blk[6]);
  and #(2)(td_6, P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],G_blk[5]);
  and #(2)(td_7, P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],G_blk[4]);
  and #(2)(td_8, P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],G_blk[3]);
  and #(2)(td_9, P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],G_blk[2]);
  and #(2)(td_10,P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],G_blk[1]);
  and #(2)(td_11,P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],G_blk[0]);
  and #(2)(td_12,P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],P_blk[0],cin);
  or  #(2)(C_blk[13],G_blk[12],td_0,td_1,td_2,td_3,td_4,td_5,td_6,td_7,td_8,td_9,td_10,td_11,td_12);

  // C_blk[14]
  wire te_0,te_1,te_2,te_3,te_4,te_5,te_6,te_7,te_8,te_9,te_10,te_11,te_12,te_13;
  and #(2)(te_0, P_blk[13],G_blk[12]);
  and #(2)(te_1, P_blk[13],P_blk[12],G_blk[11]);
  and #(2)(te_2, P_blk[13],P_blk[12],P_blk[11],G_blk[10]);
  and #(2)(te_3, P_blk[13],P_blk[12],P_blk[11],P_blk[10],G_blk[9]);
  and #(2)(te_4, P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],G_blk[8]);
  and #(2)(te_5, P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],G_blk[7]);
  and #(2)(te_6, P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],G_blk[6]);
  and #(2)(te_7, P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],G_blk[5]);
  and #(2)(te_8, P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],G_blk[4]);
  and #(2)(te_9, P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],G_blk[3]);
  and #(2)(te_10,P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],G_blk[2]);
  and #(2)(te_11,P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],G_blk[1]);
  and #(2)(te_12,P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],G_blk[0]);
  and #(2)(te_13,P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],P_blk[0],cin);
  or  #(2)(C_blk[14],G_blk[13],te_0,te_1,te_2,te_3,te_4,te_5,te_6,te_7,te_8,te_9,te_10,te_11,te_12,te_13);

  // C_blk[15]
  wire tf_0,tf_1,tf_2,tf_3,tf_4,tf_5,tf_6,tf_7,tf_8,tf_9,tf_10,tf_11,tf_12,tf_13,tf_14;
  and #(2)(tf_0, P_blk[14],G_blk[13]);
  and #(2)(tf_1, P_blk[14],P_blk[13],G_blk[12]);
  and #(2)(tf_2, P_blk[14],P_blk[13],P_blk[12],G_blk[11]);
  and #(2)(tf_3, P_blk[14],P_blk[13],P_blk[12],P_blk[11],G_blk[10]);
  and #(2)(tf_4, P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],G_blk[9]);
  and #(2)(tf_5, P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],G_blk[8]);
  and #(2)(tf_6, P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],G_blk[7]);
  and #(2)(tf_7, P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],G_blk[6]);
  and #(2)(tf_8, P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],G_blk[5]);
  and #(2)(tf_9, P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],G_blk[4]);
  and #(2)(tf_10,P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],G_blk[3]);
  and #(2)(tf_11,P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],G_blk[2]);
  and #(2)(tf_12,P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],G_blk[1]);
  and #(2)(tf_13,P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],G_blk[0]);
  and #(2)(tf_14,P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],P_blk[0],cin);
  or  #(2)(C_blk[15],G_blk[14],tf_0,tf_1,tf_2,tf_3,tf_4,tf_5,tf_6,tf_7,tf_8,tf_9,tf_10,tf_11,tf_12,tf_13,tf_14);

  // cout = G_blk[15] | ... (same expanding pattern)
  wire tg_0,tg_1,tg_2,tg_3,tg_4,tg_5,tg_6,tg_7,tg_8,tg_9,tg_10,tg_11,tg_12,tg_13,tg_14,tg_15;
  and #(2)(tg_0, P_blk[15],G_blk[14]);
  and #(2)(tg_1, P_blk[15],P_blk[14],G_blk[13]);
  and #(2)(tg_2, P_blk[15],P_blk[14],P_blk[13],G_blk[12]);
  and #(2)(tg_3, P_blk[15],P_blk[14],P_blk[13],P_blk[12],G_blk[11]);
  and #(2)(tg_4, P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],G_blk[10]);
  and #(2)(tg_5, P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],G_blk[9]);
  and #(2)(tg_6, P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],G_blk[8]);
  and #(2)(tg_7, P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],G_blk[7]);
  and #(2)(tg_8, P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],G_blk[6]);
  and #(2)(tg_9, P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],G_blk[5]);
  and #(2)(tg_10,P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],G_blk[4]);
  and #(2)(tg_11,P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],G_blk[3]);
  and #(2)(tg_12,P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],G_blk[2]);
  and #(2)(tg_13,P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],G_blk[1]);
  and #(2)(tg_14,P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],G_blk[0]);
  and #(2)(tg_15,P_blk[15],P_blk[14],P_blk[13],P_blk[12],P_blk[11],P_blk[10],P_blk[9],P_blk[8],P_blk[7],P_blk[6],P_blk[5],P_blk[4],P_blk[3],P_blk[2],P_blk[1],P_blk[0],cin);
  or  #(2)(cout,G_blk[15],tg_0,tg_1,tg_2,tg_3,tg_4,tg_5,tg_6,tg_7,tg_8,tg_9,tg_10,tg_11,tg_12,tg_13,tg_14,tg_15);

  // ------------------------------------------------------------------
  // Step 4: instantiate 16 cla4 blocks, feeding each its precomputed carry-in
  // ------------------------------------------------------------------
  wire [15:0] dummy_cout;   // block carry-outs not needed (precomputed above)

  cla4 block0  (.a(a[3:0]),   .b(b[3:0]),   .cin(C_blk[0]),  .sum(sum[3:0]),   .cout(dummy_cout[0]));
  cla4 block1  (.a(a[7:4]),   .b(b[7:4]),   .cin(C_blk[1]),  .sum(sum[7:4]),   .cout(dummy_cout[1]));
  cla4 block2  (.a(a[11:8]),  .b(b[11:8]),  .cin(C_blk[2]),  .sum(sum[11:8]),  .cout(dummy_cout[2]));
  cla4 block3  (.a(a[15:12]), .b(b[15:12]), .cin(C_blk[3]),  .sum(sum[15:12]), .cout(dummy_cout[3]));
  cla4 block4  (.a(a[19:16]), .b(b[19:16]), .cin(C_blk[4]),  .sum(sum[19:16]), .cout(dummy_cout[4]));
  cla4 block5  (.a(a[23:20]), .b(b[23:20]), .cin(C_blk[5]),  .sum(sum[23:20]), .cout(dummy_cout[5]));
  cla4 block6  (.a(a[27:24]), .b(b[27:24]), .cin(C_blk[6]),  .sum(sum[27:24]), .cout(dummy_cout[6]));
  cla4 block7  (.a(a[31:28]), .b(b[31:28]), .cin(C_blk[7]),  .sum(sum[31:28]), .cout(dummy_cout[7]));
  cla4 block8  (.a(a[35:32]), .b(b[35:32]), .cin(C_blk[8]),  .sum(sum[35:32]), .cout(dummy_cout[8]));
  cla4 block9  (.a(a[39:36]), .b(b[39:36]), .cin(C_blk[9]),  .sum(sum[39:36]), .cout(dummy_cout[9]));
  cla4 block10 (.a(a[43:40]), .b(b[43:40]), .cin(C_blk[10]), .sum(sum[43:40]), .cout(dummy_cout[10]));
  cla4 block11 (.a(a[47:44]), .b(b[47:44]), .cin(C_blk[11]), .sum(sum[47:44]), .cout(dummy_cout[11]));
  cla4 block12 (.a(a[51:48]), .b(b[51:48]), .cin(C_blk[12]), .sum(sum[51:48]), .cout(dummy_cout[12]));
  cla4 block13 (.a(a[55:52]), .b(b[55:52]), .cin(C_blk[13]), .sum(sum[55:52]), .cout(dummy_cout[13]));
  cla4 block14 (.a(a[59:56]), .b(b[59:56]), .cin(C_blk[14]), .sum(sum[59:56]), .cout(dummy_cout[14]));
  cla4 block15 (.a(a[63:60]), .b(b[63:60]), .cin(C_blk[15]), .sum(sum[63:60]), .cout(dummy_cout[15]));

endmodule