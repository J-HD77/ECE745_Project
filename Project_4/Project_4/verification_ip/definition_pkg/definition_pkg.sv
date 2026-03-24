package definition_pkg;

  typedef enum bit {WRITE=1'b0, READ=1'b1} i2c_op_t;
  typedef enum bit [1:0] {NONE=2'b00, START=2'b01, DATA=2'b10, STOP=2'b11} i2c_op_fsm;

  parameter int WB_ADDR_WIDTH = 2;
  parameter int WB_DATA_WIDTH = 8;
  parameter int NUM_I2C_BUSSES = 1;
  parameter int I2C_ADDR_WIDTH = 7;
  parameter int I2C_DATA_WIDTH = 8;

endpackage