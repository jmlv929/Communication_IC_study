#--------- create library and mapping ------------#
01 # usage: vlib <library_name>
02 #          vmap <logical_name> <directory_path>
03 vlib work
04 
05 set path [pwd]
06 set proj_dir [file dirname $path]
07 
08 set sim [file mkdir [file join $proj_dir "sim"]]
09 set debussy [file mkdir [file join $proj_dir "debussy"]]
10 
11 # get vlog files
12 set tbfiles  [glob -nocomplain [file join [file join $proj_dir "tb"]  "*.v"]]
13 set rtlfiles [glob -nocomplain [file join [file join $proj_dir "rtl"] "*.v"]]
14 set tbfile   [glob -nocomplain [file join [file join $proj_dir "tb"]  "*_tb.v"]]
15 
16 # novas_vlog file
17 regsub {(.*)/vlog/.*} $proj_dir {\1/lib/novas_vlog.v} novas_vlog
18 
19 # verilog file list
20 set vfile_list [concat $novas_vlog $tbfiles $rtlfiles]
21 
22 # generate modules.f file
23 set filelist [open [file join $sim "modules.f"] w]
24 puts $filelist "//vlog source files"
25 foreach vfile $vfile_list {
26     puts $filelist $vfile
27 }
28 close $filelist
29 
30 #-------------------- compile --------------------#
31 # usage: vlog -work <library_name> <-incr> <file1>.v <file2>.v
32 vlog -f modules.f -incr
33 
34 #-------------------- simulate -------------------#
35 # usage: vsim -lib <library_name> <top_level_design>
36 regsub {.*/(\w+)\.v} $tbfile {\1} tb_module
37 vsim -novopt $tb_module
38 
39 #------------------ add wave -------------------#
40 # enable following two lines if you check wave file in modelsim
41 #regsub {work\.((.*)_tb)$} $tb_module {sim:/\1/\2/*} top_signals
42 #add wave -radix hexadecimal $top_signals
43 
44 #-------------------- run ------------------#
45 # usage: run <time_step> <time_units>
46 run -all
47 quit
48 