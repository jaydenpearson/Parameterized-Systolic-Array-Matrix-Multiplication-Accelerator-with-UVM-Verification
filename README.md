# Parameterized-Systolic-Array-Matrix-Multiplication-Accelerator-with-UVM-Verification

To run directed testbench, run the following command:

xrun -sv -timescale 1ns/1ps -access +r \ rtl/pe.sv \ rtl/input_skew.sv \ rtl/systolic_array.sv \ rtl/controller.sv \ rtl/mm_accelerator_top.sv \ tb/directed/tb_mm_accelerator.sv

To run uvm environment, run the following command:

xrun -sv -uvm -timescale 1ns/1ps -access +r 
	-coverage all \ 
	-covscope worklib \ 
	-covoverwrite \    
	-incdir tb/uvm/top      
	-incdir tb/uvm/seq_items      
	-incdir tb/uvm/agent      
	-incdir tb/uvm/env      
	-incdir tb/uvm/sequences      
	-incdir tb/uvm/tests      
	-incdir tb/uvm/pkg      
	rtl/pe.sv      
	rtl/input_skew.sv      
	rtl/systolic_array.sv      
	rtl/controller.sv      
	rtl/mm_accelerator_top.sv      
	tb/uvm/top/tb_top.sv      
	+UVM_TESTNAME=mm_regression_test

