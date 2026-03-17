#!/bin/bash

# -----------------------------------------------------------------------
# run_sim.sh — compile and run directed testbench
# Usage: ./scripts/run_sim.sh
# -----------------------------------------------------------------------

xrun -sv \
     -timescale 1ns/1ps \
     -access +r \
     rtl/pe.sv \
     rtl/input_skew.sv \
     rtl/systolic_array.sv \
     rtl/controller.sv \
     rtl/mm_accelerator_top.sv \
     tb/directed/tb_mm_accelerator.sv
