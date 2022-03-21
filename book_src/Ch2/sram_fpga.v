 1 module ram256x8 ( //忽略部分端口列表，完整请参考电子附件
 8     input [7:0]  address;//RAM的地址
 9     input        clock;// RAM时钟，表示RAM是同步的
10     input [7:0]  data; //RAM输入数据
11     input        wren; //RAM写使能信号，高电平有效
12     output[7:0]  q;
24     altsyncram  altsyncram_component ( //例化Altera内部标准双口RAM
25                 .address_a (address),
26                 .clock0 (clock),
27                 .data_a (data),
28                 .wren_a (wren),
29                 .q_a (sub_wire0),
30                 .aclr0 (1'b0),
31                 .aclr1 (1'b0),
32                 .address_b (1'b1),
33                 .addressstall_a (1'b0),
34                 .addressstall_b (1'b0),
35                 .byteena_a (1'b1),
36                 .byteena_b (1'b1),
37                 .clock1 (1'b1),
38                 .clocken0 (1'b1),
39                 .clocken1 (1'b1),
40                 .clocken2 (1'b1),
41                 .clocken3 (1'b1),
42                 .data_b (1'b1),
43                 .eccstatus (),
44                 .q_b (),
45                 .rden_a (1'b1),
46                 .rden_b (1'b1),
47                 .wren_b (1'b0));

