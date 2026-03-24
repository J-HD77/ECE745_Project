class i2c_coverage extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration configuration;
  bit [I2C_ADDR_WIDTH-1:0] addr;
  i2c_op_t op;
  bit [I2C_DATA_WIDTH-1:0] data;

  covergroup i2c_transaction_cg;
  	option.per_instance = 1;
    option.name = get_full_name();
    address : coverpoint addr;
    data : coverpoint data;
    op : coverpoint op;
    address_x_data_x_op : cross address, data, op;
  endgroup

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    i2c_transaction_cg = new;
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
    //$display("i2c_coverage::nb_put() %s called",get_full_name());
    addr = trans.addr;
    data = trans.data[0];
    op = trans.op;
    i2c_transaction_cg.sample();
  endfunction

endclass
