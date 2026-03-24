class i2cmb_generator extends ncsu_component;
//`ncsu_register_object(i2cmb_generator)

  i2c_transaction i2c_trans;
  wb_transaction wb_trans;
  wb_agent wb_ag;
  i2c_agent i2c_ag;
  int alt_write_val = 64;
  string trans_name;

  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);
    // if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
    //   $display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
    //   $fatal;
    // end
    // $display("%m found +GEN_TRANS_TYPE=%s", trans_name);
  endfunction

  virtual task run();
    fork
      // I2C responses using i2c_transactions
      begin : i2c_flow
        //write 32 values to i2c slave
        i2c_trans = new;
        i2c_ag.bl_put(i2c_trans);
        //read 32 values from i2c slave (100-131)
        for(int i=0; i<32; i++) begin
            i2c_trans.data_queue.push_back(i+100);
        end
        //$display(i2c_trans.data_queue);
        i2c_ag.bl_put(i2c_trans);

        //alternating reads and writes
        for(int i=63; i>=0; i--) begin
            //write value to i2c slave
            i2c_trans = new;
            i2c_ag.bl_put(i2c_trans);
            //read value from i2c slave
            i2c_trans = new;
            i2c_trans.data_queue.push_front(i);
            i2c_ag.bl_put(i2c_trans);
        end
      end
      // test flow using wb_transactions
      begin : wb_flow
        // 6.1 Example 1
        // Task: Enable the IICMB core after power-up.
        // Write byte “1xxxxxxx” to the CSR register. This sets bit E to '1', enabling the core.
        wb_trans = new;
        wb_trans.address = 0;
        wb_trans.data = 8'b11xxxxxx; 
        wb_ag.bl_put(wb_trans);      

        //This is the ID of desired I2C bus
        wb_trans = new;
        wb_trans.address = 1;
        wb_trans.data = 8'h05;
        wb_ag.bl_put(wb_trans);

        //This is Set Bus command
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx110;
        wb_ag.bl_put(wb_trans);

        //Wait for interrupt
        wb_ag.bus.wait_for_interrupt();

        //Write enable
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);

        //*********************************************
        //write 0-31 to the bus
        //start command
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx100;
        wb_ag.bl_put(wb_trans);
        wb_ag.bus.wait_for_interrupt();
        //clear irq flag
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);

        //write command to slave 0x22
        wb_trans = new;
        wb_trans.address = 1;
        wb_trans.data = 8'h44;
        wb_ag.bl_put(wb_trans);
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx001;
        wb_ag.bl_put(wb_trans);
        wb_ag.bus.wait_for_interrupt();
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);

        //write vals
        for(int i=0; i<32; i++) begin
            wb_trans = new;
            wb_trans.address = 1;
            wb_trans.data = i;
            wb_ag.bl_put(wb_trans);
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.data = 8'bxxxxx001;
            wb_ag.bl_put(wb_trans);
            wb_ag.bus.wait_for_interrupt();
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.we = 1;
            wb_ag.bl_put(wb_trans);
        end

        //write stop bit
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx101;
        wb_ag.bl_put(wb_trans);
        wb_ag.bus.wait_for_interrupt();
        //clear irq flag
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);
        //*********************************************

        //**********************************
        //read back 100-131
        //start command
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx100;
        wb_ag.bl_put(wb_trans);
        wb_ag.bus.wait_for_interrupt();
        //$display("interrupt received");
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);

        //read command to slave 0x22
        wb_trans = new;
        wb_trans.address = 1;
        wb_trans.data = 8'h45;
        wb_ag.bl_put(wb_trans);

        //write command
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx001;
        wb_ag.bl_put(wb_trans);
        //wait for irq, clear flag after
        wb_ag.bus.wait_for_interrupt();
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);

        //read values
        for(int i=0; i<32; i++)begin
            //command
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.data = 8'bxxxxx010;
            wb_ag.bl_put(wb_trans);
            //wait for irq
            wb_ag.bus.wait_for_interrupt();
            //$display("interrupt received");
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.we = 1;
            wb_ag.bl_put(wb_trans);
            //read operation
            wb_trans = new;
            wb_trans.address = 1;
            wb_trans.we = 1;
            wb_ag.bl_put(wb_trans);
        end
        
        //read command
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx011;
        wb_ag.bl_put(wb_trans);
        wb_ag.bus.wait_for_interrupt();
        //$display("interrupt received");
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);
        
        //write stop command
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx101;
        wb_ag.bl_put(wb_trans);
        wb_ag.bus.wait_for_interrupt();
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);

        //************************************
        //alternating read 63-0, write 64-127 to the bus
        for(int i=0; i<64; i++) begin
            //write value
            //start command
            //wb_trans = new;
            //wb_trans.address = 2;
            //wb_trans.we = 1;
            //wb_ag.bl_put(wb_trans);
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.data = 8'bxxxxx100;
            wb_ag.bl_put(wb_trans);
            wb_ag.bus.wait_for_interrupt();
            //$display("interrupt received");
            //interrupt received, clear irq flag
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.we = 1;
            wb_ag.bl_put(wb_trans);
            
            //write command to slave 0x22
            wb_trans = new;
            wb_trans.address = 1;
            wb_trans.data = 8'h44;
            wb_ag.bl_put(wb_trans);
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.data = 8'bxxxxx001;
            wb_ag.bl_put(wb_trans);
            wb_ag.bus.wait_for_interrupt();
            //interrupt received, clear irq flag
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.we = 1;
            wb_ag.bl_put(wb_trans);

            //write value
            wb_trans = new;
            wb_trans.address = 1;
            wb_trans.data = alt_write_val;
            wb_ag.bl_put(wb_trans);
            alt_write_val++;
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.data = 8'bxxxxx001;
            wb_ag.bl_put(wb_trans);
            wb_ag.bus.wait_for_interrupt();
            //interrupt received, clear irq flag
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.we = 1;
            wb_ag.bl_put(wb_trans);

            //write stop bit
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.data = 8'bxxxxx101;
            wb_ag.bl_put(wb_trans);
            wb_ag.bus.wait_for_interrupt();
            //interrupt received, clear irq flag
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.we = 1;
            wb_ag.bl_put(wb_trans);

            //*********************************
            //read value
            //start command
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.data =8'bxxxxx100;
            wb_ag.bl_put(wb_trans);
            wb_ag.bus.wait_for_interrupt();
            //interrupt received, clear irq flag
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.we = 1;
            wb_ag.bl_put(wb_trans);

            //read command to slave 0x22
            wb_trans = new;
            wb_trans.address = 1;
            wb_trans.data = 8'h45;
            wb_ag.bl_put(wb_trans);
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.data = 8'bxxxxx001;
            wb_ag.bl_put(wb_trans);
            wb_ag.bus.wait_for_interrupt();
            //interrupt received, clear irq flag
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.we = 1;
            wb_ag.bl_put(wb_trans);

            //read command
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.data = 8'bxxxxx011;
            wb_ag.bl_put(wb_trans);
            wb_ag.bus.wait_for_interrupt();
            //interrupt received, clear irq flag
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.we = 1;
            wb_ag.bl_put(wb_trans);
            //read value
            wb_trans = new;
            wb_trans.address = 1;
            wb_trans.we = 1;
            wb_ag.driver.bl_put(wb_trans);

            //write stop command
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.data = 8'bxxxxx101;
            wb_ag.bl_put(wb_trans);
            wb_ag.bus.wait_for_interrupt();
            //interrupt received, clear irq flag
            wb_trans = new;
            wb_trans.address = 2;
            wb_trans.we = 1;
            wb_ag.bl_put(wb_trans);
        end
      end
    join
  endtask

   function void set_agent(wb_agent agent1, i2c_agent agent2);
    this.wb_ag = agent1;
    this.i2c_ag = agent2;
  endfunction
endclass