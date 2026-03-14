# Parameterized-Systolic-Array-Matrix-Multiplication-Accelerator-with-UVM-Verification

To run directed testbench, run the following command:

xrun -sv -timescale 1ns/1ps -access +r \ rtl/pe.sv \ rtl/input_skew.sv \ rtl/systolic_array.sv \ rtl/controller.sv \ rtl/mm_accelerator_top.sv \ tb/directed/tb_mm_accelerator.sv

