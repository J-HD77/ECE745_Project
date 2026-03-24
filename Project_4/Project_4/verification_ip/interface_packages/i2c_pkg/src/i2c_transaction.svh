class i2c_transaction extends ncsu_transaction;
  `ncsu_register_object(i2c_transaction)

  // rand bit [5:0]  delay;
  bit [I2C_ADDR_WIDTH-1:0] addr;
  i2c_op_t op;
  bit [I2C_DATA_WIDTH-1:0] data[];
  int int_data[];
  bit [I2C_DATA_WIDTH-1:0] data_queue[$];
  
  function new(string name=""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
      //$display(int_data);
      return {super.convert2string(), $sformatf("addr:0x%x op:0x%x data:%p",
	       addr, op, int_data)};
  endfunction

  function bit compare(i2c_transaction rhs);
    return ((this.addr  == rhs.addr ) && 
            (this.op == rhs.op) &&
            (this.data == rhs.data));
  endfunction

  virtual function void add_to_wave(int transaction_viewing_stream_h);
    super.add_to_wave(transaction_viewing_stream_h);
    $add_attribute(transaction_view_h, addr, "addr");
    $add_attribute(transaction_view_h, op, "op");
    $add_attribute(transaction_view_h, data[data.size()-1], "data");
    //$add_attribute(transaction_view_h, delay, "delay");
    $end_transaction(transaction_view_h, end_time);
    $free_transaction(transaction_view_h);
  endfunction
endclass