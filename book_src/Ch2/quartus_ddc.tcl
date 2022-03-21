## ddc quartus file
## Author : Li qinghua
## Date : 2005/2/21
## run with " source e:/project/ddc_int/bin/quartus_ddc.tcl "
package require ::quartus::flow
set work_root e:/project/ddc_int
set top_module ddc
set project_name ddc

set filelist "./tb/_fpga/${project_name}/fpgalist.f_${project_name}"
set synplify_blackbox_filelist "./tb/_fpga/${project_name}/dut_blackbox.f"
set quartus_blackbox_filelist  "./tb/_asic/${project_name}/dut_blackbox.f"

set quartus_stp_file stp1.stp
set work_dir  ${work_root}
global top_module,project_name,filelist,work_root,action,work_dir

proc create_project { } { 
    global project_name
    global work_root
    cd ${work_root}
		if [project_exists $project_name] {
		  project_open $project_name
		} else {
		  project_new $project_name
		}
}

proc add_file { } {
	global work_root
	global filelist
	global quartus_blackbox_filelist
	global synplify_blackbox_filelist
	global action
	
	set action "set_global_assignment -name VERILOG_FILE "
	source ${work_root}/bin/get_filelist.tcl
	setup_filelist ${work_root}/${filelist}
}


proc get_fmax_from_report {} {
  global project_name
  load_report $project_name
  set fmax_panel_name "Timing Analyzer Summary"
  foreach panel_name [get_report_panel_names] {
    if { [string match "*$fmax_panel_name*" "$panel_name"] } {
      set fmax_row [get_report_panel_row "$panel_name" -row 1]
    }
  }
  set actual_fmax [lindex $fmax_row 3]
  unload_report $project_name
  return $actual_fmax
}

proc add_quartus_debug_info { } {
	global quartus_stp_file

   if { [file exists "${quartus_stp_file}" ]} {
			set_global_assignment -name ENABLE_SIGNALTAP ON
			set_global_assignment -name USE_SIGNALTAP_FILE ${quartus_stp_file}
   } else {	 
   		puts stdout "SignalTap file missing "
	}
}

create_project
add_quartus_debug_info

add_file
source ${work_root}/bin/${project_name}_assignment_defaults.qdf

execute_flow -compile

get_fmax_from_report

## ::quartus::timing 时序验证
## #估算仿真并且报告时序验证，只能在quartus_tan中执行
##   create_timing_netlist
##   report_timing
##   delete_timing_netlist
