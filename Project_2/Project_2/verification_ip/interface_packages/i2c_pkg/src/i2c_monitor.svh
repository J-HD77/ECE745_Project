class i2c_monitor extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration configuration;
  virtual i2c_if #(NUM_I2C_BUSSES, I2C_ADDR_WIDTH, I2C_DATA_WIDTH) bus;

  T monitored_trans;
  ncsu_component #(T) agent;

  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  function void set_agent(ncsu_component #(T) agent);
    this.agent = agent;
  endfunction

  //I2C MONITOR FLOW
  bit [I2C_ADDR_WIDTH-1:0] i2c_addr;
  i2c_op_t operation;
  bit [I2C_DATA_WIDTH-1:0] i2c_data[];

  virtual task run ();
      forever begin
        //$display("i2c monitor running");
        monitored_trans = new;
        if(enable_transaction_viewing) begin
          //$display("i2c monitor start");
          monitored_trans.start_time = $time;
        end
        bus.monitor(i2c_addr, operation, i2c_data);
        monitored_trans.addr = i2c_addr;
        monitored_trans.op = operation;
        monitored_trans.data = i2c_data;
        // if(operation == 1'b0) begin
        //   $display("I2C_BUS WRITE Transfer: addr - %x, data - %d", i2c_addr, i2c_data);
        // end         
        // else begin
        //   $display("I2C_BUS READ  Transfer: addr - %x, data - %d", i2c_addr, i2c_data);
        // end
        agent.nb_put(monitored_trans);
        if(enable_transaction_viewing) begin
          monitored_trans.end_time = $time;
          monitored_trans.add_to_wave(transaction_viewing_stream);
        end
    end
  endtask

endclass
