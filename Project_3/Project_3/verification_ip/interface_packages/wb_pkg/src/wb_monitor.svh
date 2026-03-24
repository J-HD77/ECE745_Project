class wb_monitor extends ncsu_component#(.T(wb_transaction));

  wb_configuration configuration;
  virtual wb_if #(WB_ADDR_WIDTH, WB_DATA_WIDTH) bus;

  T monitored_trans;
  ncsu_component #(T) agent;

   function new(string name = "", ncsu_component_base parent = null);
      super.new(name, parent);
   endfunction

   function void set_configuration(wb_configuration cfg);
      configuration = cfg;
   endfunction

   function void set_agent(ncsu_component#(T) agent);
      this.agent = agent;
   endfunction

  //WB MONITOR FLOW
  bit [WB_ADDR_WIDTH-1:0] addr_val;
  bit [WB_DATA_WIDTH-1:0] data_val;
  bit                     we_val;

  virtual task run();
    bus.wait_for_reset();
    forever begin
        //$display("wb monitor running");
        monitored_trans = new("monitored_trans");
        if(enable_transaction_viewing) begin
          monitored_trans.start_time = $time;
        end
        bus.master_monitor(addr_val, data_val, we_val);
        monitored_trans.address = addr_val;
        monitored_trans.we = we_val;
        monitored_trans.data = data_val;
        //$display("wb monitored_trans data: %d", data_val);
        //$display("transferred: addr - %x. data - %d, we - %x", addr_val, data_val, we_val);
        agent.nb_put(monitored_trans);
        if(enable_transaction_viewing) begin
          monitored_trans.end_time = $time;
          monitored_trans.add_to_wave(transaction_viewing_stream);
        end
    end
  endtask

endclass
