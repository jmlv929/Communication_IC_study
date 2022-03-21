01 module vjtag_if (
02  input [7:0]  ir_out,
03  input   tdo,
04  output  [7:0]  ir_in,
05  output    tck,
06  output    tdi,
07  output    virtual_state_cdr,
08  output    virtual_state_cir,
09  output    virtual_state_e1dr,
10  output    virtual_state_e2dr,
11  output    virtual_state_pdr,
12  output    virtual_state_sdr,
13  output    virtual_state_udr,
14  output    virtual_state_uir
15 );
16  wire  sub_wire0;
17  wire  sub_wire1;
18  wire [7:0] sub_wire2;
19  wire  sub_wire3;
20  wire  sub_wire4;
21  wire  sub_wire5;
22  wire  sub_wire6;
23  wire  sub_wire7;
24  wire  sub_wire8;
25  wire  sub_wire9;
26  wire  sub_wire10;
27  wire  virtual_state_cir = sub_wire0;
28  wire  virtual_state_pdr = sub_wire1;
29  wire [7:0] ir_in = sub_wire2[7:0];
30  wire  tdi = sub_wire3;
31  wire  virtual_state_udr = sub_wire4;
32  wire  tck = sub_wire5;
33  wire  virtual_state_e1dr = sub_wire6;
34  wire  virtual_state_uir = sub_wire7;
35  wire  virtual_state_cdr = sub_wire8;
36  wire  virtual_state_e2dr = sub_wire9;
37  wire  virtual_state_sdr = sub_wire10;
38
39  sld_virtual_jtag  sld_virtual_jtag_component (
40        .ir_out (ir_out),
41        .tdo (tdo),
42        .virtual_state_cir (sub_wire0),
43        .virtual_state_pdr (sub_wire1),
44        .ir_in (sub_wire2),
45        .tdi (sub_wire3),
46        .virtual_state_udr (sub_wire4),
47        .tck (sub_wire5),
48        .virtual_state_e1dr (sub_wire6),
49        .virtual_state_uir (sub_wire7),
50        .virtual_state_cdr (sub_wire8),
51        .virtual_state_e2dr (sub_wire9),
52        .virtual_state_sdr (sub_wire10)
53        // synopsys translate_off
54        ,
55        .jtag_state_cdr (),
56        .jtag_state_cir (),
57        .jtag_state_e1dr (),
58        .jtag_state_e1ir (),
59        .jtag_state_e2dr (),
60        .jtag_state_e2ir (),
61        .jtag_state_pdr (),
62        .jtag_state_pir (),
63        .jtag_state_rti (),
64        .jtag_state_sdr (),
65        .jtag_state_sdrs (),
66        .jtag_state_sir (),
67        .jtag_state_sirs (),
68        .jtag_state_tlr (),
69        .jtag_state_udr (),
70        .jtag_state_uir (),
71        .tms ()
72        // synopsys translate_on
73        );
74  defparam
75    sld_virtual_jtag_component.sld_auto_instance_index = "YES",
76    sld_virtual_jtag_component.sld_instance_index = 0,
77    sld_virtual_jtag_component.sld_ir_width = 8,
78    sld_virtual_jtag_component.sld_sim_action = "((0,1,0,8),(2,1,5,8),(3,1,6,8))",
79    sld_virtual_jtag_component.sld_sim_n_scan = 3,
80    sld_virtual_jtag_component.sld_sim_total_length = 24;
81
82 endmodule
83
84
