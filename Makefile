
.PHONY: sim uvm corner rand stress regression clean

# directed testbench
sim:
	./scripts/run_sim.sh

# UVM tests
corner:
	./scripts/run_uvm.sh mm_corner_test

rand:
	./scripts/run_uvm.sh mm_rand_test

stress:
	./scripts/run_uvm.sh mm_stress_test

regression:
	./scripts/run_uvm.sh mm_regression_test

# clean build artifacts
clean:
	rm -rf xcelium.d/ xrun.log waves.shm uvm_waves.shm cov_work/ *.shm *.log
