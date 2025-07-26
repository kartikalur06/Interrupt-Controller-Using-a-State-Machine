vlib work
vlog int_cntrl_1.v
vlog tb_int_cntrl.v
vsim tb
add wave -position insertpoint sim:/tb/dut/*
run -all
