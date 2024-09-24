open_project prj/prj.xpr
update_compile_order -fileset sources_1

# Synthesis
# reset_run synth_1
# launch_runs synth_1 -jobs 6
# wait_on_runs -runs synth_1

# Implementation
# reset_run impl_1
# launch_runs impl_1 -jobs 6
# wait_on_runs -runs impl_1

# Write bitstream
# reset_runs impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 6
wait_on_runs -runs impl_1

# Export hardware
write_hw_platform -fixed -include_bit -force -file /home/nice-user/code/Vivado-build-test/build/design_1_wrapper.xsa