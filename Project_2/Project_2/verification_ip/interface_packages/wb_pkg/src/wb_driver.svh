class wb_driver extends ncsu_component#(.T(wb_transaction));

  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
  endfunction

  virtual wb_if #(WB_ADDR_WIDTH, WB_DATA_WIDTH) bus;
  wb_configuration configuration;
  wb_transaction wb_trans;

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

// WB FLOW
  int alt_write_val = 64;

  virtual task bl_put(T trans);
    //$display("WB_DRIVER TRANS RECEIVED");
    if (trans.we) bus.master_read(trans.address, trans.data);
    else bus.master_write(trans.address, trans.data);
  endtask
endclass