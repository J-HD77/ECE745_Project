class wb_transaction extends ncsu_transaction;
  `ncsu_register_object(wb_transaction)

  bit [WB_ADDR_WIDTH-1:0] address; //register address
  bit we = 0; //operation
  bit [WB_DATA_WIDTH-1:0] data; //data
  //rand bit [5:0] delay;

  function new(string name =""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
    return {super.convert2string(), $sformatf("address:0x%x write enable:0x%x data:0x%x",
            address, we, data)};
  endfunction

  function bit compare(wb_transaction rhs);
      return ((this.address == rhs.address) && 
              (this.we == rhs.we) && 
              (this.data == rhs.data));
  endfunction

  virtual function void add_to_wave(int transaction_viewing_stream_h);
    super.add_to_wave(transaction_viewing_stream_h);
    $add_attribute(transaction_view_h, address, "address");
    $add_attribute(transaction_view_h, we, "write_enable");
    $add_attribute(transaction_view_h, data, "data");
    //$add_attribute(transaction_view_h, delay, "delay");
    $end_transaction(transaction_view_h, end_time);
    $free_transaction(transaction_view_h);
  endfunction
endclass