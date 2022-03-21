506 ant_num_tmp = get(handles.popupmenu1, 'Value'); % 2 4 8  ----1 2 3
508 switch ant_num_tmp
509     case 1
510         ant_num=2;
511     case 2
512         ant_num=4;
513     case 3
514         ant_num=8;
515 end  
516 cell_num = get(handles.popupmenu4, 'Value'); % 1 2 3 4 5
517 fs_in    = str2double(get(handles.edit6,'string'));
518 fclk     = str2double(get(handles.edit13,'string'));


17 % stage_num_hb=log2(Fs_out/Fs_in);
18 %tSys=num2str(1/(Fclk*10^6));
19 tSys=1/(Fclk*10^6);
20 assignin('base','tSys',tSys);
21 data_width =16;
22 data_width_str=num2str(data_width);
23 bin_point =0;
24 bin_point_str=num2str(bin_point);
25 
26 %local param
27 chl_hb1=Fclk/Fs_in;
28 chl_hb2=chl_hb1/2;
29 %calculate number of HB 30.72to61.44
30 N1=ceil(ANT_NUM*CELL_NUM*2/chl_hb1);
31 %calculate number of HB 61.44to122.88
32 N2=ceil(ANT_NUM*CELL_NUM*2/chl_hb2);
33 %add_num
34 Add_N3 = ceil(ANT_NUM/2);

51 %% System Generator       
52  blk_sysgen_name = ' System Generator';
53  p_sysgen = strcat(mdl_name,'/',blk_sysgen_name); 
54  add_block('newlib/ System Generator',p_sysgen);
55  set_param(p_sysgen, 'Position',[650 20 650+80 20+80]);
56  set_param(p_sysgen,'simulink_period','tSys');
57 %% System Generator       
58  blk_resurce_name = 'Resource Estimator';
59  p_resurce = strcat(mdl_name,'/',blk_resurce_name); 
60  add_block('newlib/Resource Estimator',p_resurce);
61  set_param(p_resurce, 'Position',[850 20 850+80 20+80]);
62 %% hb1
63 pos1=[600 325 600+100 325+150];
64 blk_hb1_name = cell(1,N1);
65 p1 = cell(1,N1);
66 for i1=1:N1
67      blk_hb1_name{i1} = sprintf('hb23_2R_stage1_%d',i1);
68      p1{i1}=strcat(mdl_name,'/',blk_hb1_name{i1});
69      add_block('newlib/hb23_2R',p1{i1});
70      set_param(p1{i1}, 'fs', '30.72','fclk','245.76','data_width',
71                '16','Position',pos1+[0 (i1-1)*500 0 (i1-1)*500]);
72 end
73 if ANT_NUM == 2 && mod(CELL_NUM,2) == 1
74    blk_term_name = 'Terminator';
75    p_term = strcat(mdl_name,'/','Terminator');
76    add_block('newlib/Terminator',p_term);
77    set_param(p_term,'Position',pos1+[140 110+(CELL_NUM-1)/2*500 
78              65 -15+(CELL_NUM-1)/2*500]);
79    add_line(mdl_name,[blk_hb1_name{N1} '/3'], [blk_term_name '/1']
80             , 'autorouting','on')
81 end


01 syms fm_C
02 fm_C=1;
03 syms z  fm1 fm2 fm_num fm_div fm_result fm_hz
04 N=8
05 %% set symbols
06 fm1=fm_C*(z^2+1)*(z^2-1)*(z^2+sqrt(3)*z+1)
07 fm2=z^6+(1-2^(2-N))
08 %% get iir result
09 fm_num=expand(fm1)
10 fm_div=expand(fm2)
11 fm_num_fix=sym2poly(fm_num)
12 fm_div_fix=sym2poly(fm_div)
13 %% get freqency respond
14 freqz(fm_num_fix,fm_div_fix)£»figure
16 zplane(fm_num_fix,fm_div_fix)

