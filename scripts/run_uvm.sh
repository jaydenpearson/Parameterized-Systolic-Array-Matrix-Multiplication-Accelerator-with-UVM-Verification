#!/bin/bash

# -----------------------------------------------------------------------
# run_uvm.sh — compile and run UVM regression
# Usage:
#   ./scripts/run_uvm.sh                          (default: regression test)
#   ./scripts/run_uvm.sh mm_corner_test           (run specific test)
#   ./scripts/run_uvm.sh mm_rand_test 500         (rand test with N transactions)
# -----------------------------------------------------------------------

TEST=${1:-mm_regression_test}
NUM_TRANSACTIONS=${2:-200}

xrun -sv -uvm \
     -timescale 1ns/1ps \
     -access +r \
     -coverage all \
     -covscope worklib \
     -covoverwrite \
     -incdir tb/uvm/top \
     -incdir tb/uvm/seq_items \
     -incdir tb/uvm/agent \
     -incdir tb/uvm/env \
     -incdir tb/uvm/sequences \
     -incdir tb/uvm/tests \
     -incdir tb/uvm/pkg \
     rtl/pe.sv \
     rtl/input_skew.sv \
     rtl/input_skew.sv \
     rtl/systolic_array.sv \
     rtl/controller.sv \
     rtl/mm_accelerator_top.sv \
     tb/uvm/top/tb_top.sv \
     +UVM_TESTNAME=$TEST \
     +NUM_TRANSACTIONS=$NUM_TRANSACTIONS
