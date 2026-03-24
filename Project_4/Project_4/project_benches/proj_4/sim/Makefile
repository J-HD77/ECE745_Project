export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/definition_pkg/Makefile

GEN_TRANS_TYPE ?= wb_transaction
GEN_TEST_TYPE ?= i2cmb_test
TEST_SEED ?= 12345

clean: 
	rm -rf work *.wlf transcript qrun.out

comp_I2C_MB:
	vcom -cover f ../rtl/iicmb_int_pkg.vhd
	vcom -cover f ../rtl/iicmb_pkg.vhd
	vcom -cover f ../rtl/mbyte.vhd
	vcom -cover f ../rtl/mbit.vhd
	vcom -cover f ../rtl/bus_state.vhd
	vcom -cover f ../rtl/filter.vhd
	vcom -cover f ../rtl/conditioner.vhd
	vcom -cover f ../rtl/conditioner_mux.vhd
	vcom -cover f ../rtl/iicmb_m.vhd
	vcom -cover f ../rtl/regblock.vhd
	vcom -cover f ../rtl/wishbone.vhd
	vcom -cover f ../rtl/iicmb_m_wb.vhd

comp_bench: comp_ncsu_pkg comp_definition_pkg comp_i2c_pkg comp_wb_pkg comp_i2cmb_env_pkg
	vlog ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

simulate:
	vsim  -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) +GEN_TEST_TYPE=$(GEN_TEST_TYPE) optimized_debug_top_tb

debug_3step: clean compile simulate

debug:
	qrun -64 -gui -visualizer -onfinish stop -classdebug -uvmcontrol=all -msgmode both -permit_unmatched_virtual_intf -l run.log -f lab1_filelist.f -sv_seed 123456 -msglimit error -msglimitcount 20 -do "set IterationLimit 140000; set NoQuitOnFinish 1; coverage attribute -name TESTNAME -value $(GEN_TEST_TYPE) ; coverage save test_top.ucdb; do wave.do" -debug,livesim -qwavedb=+signal+memory=1024+report+parameter+class+assertion+uvm_schematic+msg+classmemory=1024+statictaskfunc -top top -covermultiuserenv -designfile design.bin 

run_cli:
	vsim -coverage -c -sv_seed $(TEST_SEED) -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GEN_TEST_TYPE); coverage save $(GEN_TEST_TYPE).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) +GEN_TEST_TYPE=$(GEN_TEST_TYPE) optimized_debug_top_tb

cli: clean compile run_cli

run_cov:
	vsim -i -classdebug -msgmode both -do "do load_ucdbs_and_merge_with_test_plan.do" optimized_debug_top_tb

run_debug_cov:
	qrun -64 -gui -onfinish stop -classdebug -uvmcontrol=all -msgmode both -permit_unmatched_virtual_intf -l run.log -f lab1_filelist.f -sv_seed 123456 -msglimit error -msglimitcount 20 -do "set IterationLimit 140000; set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GEN_TEST_TYPE); coverage save test_top.ucdb; do wave.do" -debug,livesim -qwavedb=+signal+memory=1024+report+parameter+class+assertion+uvm_schematic+msg+classmemory=1024+statictaskfunc -top top -covermultiuserenv -designfile design.bin 

merge_coverage_with_test_plan: clean compile run_cov

run_all_tests:
	chmod +x ./testlist.sh
	./testlist.sh

merge_all_tests:
	vcover merge -stats=none -strip 0 -totals merged_tests.ucdb ./*.ucdb

covert_testplan:
	xml2ucdb -format Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
	add testbrowser ./*.ucdb

merge_coverage:
	vcover merge -stats=none -strip 0 -totals regression.ucdb ./merged_tests.ucdb ./i2cmb_test_plan.ucdb
	coverage open ./regression.ucdb

report_coverage:
	vcover report -details -html -htmldir covhtmlreport -assert -directive -cvg -code bcefst -threshL 50 -threshH 90 ./regression.ucdb
