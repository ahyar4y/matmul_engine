# Set reference directory to script location
set origin_dir [file dirname [info script]]

if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

set _xil_proj_name_ "MatMul_Engine"

if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

# Create project
create_project ${_xil_proj_name_} $origin_dir/${_xil_proj_name_} -part xc7z020clg484-1 -force

# Project properties
set obj [current_project]
set_property -name "board_part" -value "xilinx.com:zc702:part0:1.4" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj

# 1. Add HDL Source Files
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

set hdl_files [list \
  [file normalize "${origin_dir}/src/hdl/mat_mul.v"] \
]
add_files -norecurse -fileset [get_filesets sources_1] $hdl_files

# 2. Re-create Block Design and Wrapper
# source $origin_dir/src/bd/design_1.tcl
# set bd_file [get_files *.bd]
# make_wrapper -files $bd_file -top -import

# 3. Add Simulation Sources
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

set sim_files [list \
  [file normalize "${origin_dir}/src/tb/mat_mul_tb.v"] \
]
add_files -norecurse -fileset [get_filesets sim_1] $sim_files

set_property -name "top" -value "testbench" -objects [get_filesets sim_1]

# 4. Set Runs
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part xc7z020clg484-1 -flow {Vivado Synthesis 2025}
}
current_run -synthesis [get_runs synth_1]

if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -part xc7z020clg484-1 -flow {Vivado Implementation 2025} -parent_run synth_1
}
current_run -implementation [get_runs impl_1]

puts "INFO: Project '${_xil_proj_name_}' and Block Design successfully reconstructed!"