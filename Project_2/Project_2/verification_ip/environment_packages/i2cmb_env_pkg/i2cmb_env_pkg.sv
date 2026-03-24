package i2cmb_env_pkg;
  import ncsu_pkg::*;
  `include "ncsu_macros.svh"
  import wb_pkg::*;
  import i2c_pkg::*;
  import definition_pkg::*;
	`include "src/i2cmb_env_configuration.svh"
  `include "src/i2cmb_coverage.svh"
  `include "src/i2cmb_scoreboard.svh"
  `include "src/i2cmb_predictor.svh"
  `include "src/i2cmb_environment.svh"
  `include "src/i2cmb_generator.svh"
  `include "src/i2cmb_test.svh"
endpackage