#!/bin/sh

#Generator tests
make cli GEN_TEST_TYPE=rand_rd
make cli GEN_TEST_TYPE=rand_wr
make cli GEN_TEST_TYPE=alternate
#Register tests
make cli GEN_TEST_TYPE=invalid
make cli GEN_TEST_TYPE=read_only
make cli GEN_TEST_TYPE=default_register_vals
#Additional Tests
make cli GEN_TEST_TYPE=wait
make cli GEN_TEST_TYPE=reset
#Merge coverage and testplan
make merge_coverage_with_test_plan
