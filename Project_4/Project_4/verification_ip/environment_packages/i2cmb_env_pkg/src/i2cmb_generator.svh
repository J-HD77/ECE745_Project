class i2cmb_generator extends ncsu_component;
//`ncsu_register_object(i2cmb_generator)

  i2c_transaction i2c_trans;
  wb_transaction wb_trans;
  wb_agent wb_ag;
  i2c_agent i2c_ag;
  int alt_write_val = 64;
  int alt_write_val_cov = 128;
  string trans_name;

  wb_rand_transaction wb_rand;
  int i2c_rand;
  int success;
  bit [WB_DATA_WIDTH-1:0] original_data[4];
  bit [WB_DATA_WIDTH-1:0] post_transaction_data[4];

  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);
    // if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
    //   $display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
    //   $fatal;
    // end
    // $display("%m found +GEN_TRANS_TYPE=%s", trans_name);
  endfunction

  //Generator Tests
  task wait_test();
    wb_ag.bus.wait_for_num_clocks(150);
    wb_ag.bus.wait_for_num_clocks(250);
    $display("WAIT COMPLETE");
  endtask
  task reset_test();
    wb_ag.bus.reset_bus();
    wb_ag.bus.wait_for_reset();
    $display("RESET COMPLETE");
  endtask
  task rand_rd_test();
    fork
      begin : i2c_flow
        i2c_trans = new;
        for(int i=0; i<64; i++) begin
          i2c_rand = $urandom_range(0, 255); //random number between 0 and 255
          i2c_trans.data_queue.push_back(i2c_rand);
        end
        i2c_ag.bl_put(i2c_trans);
      end
      begin : wb_flow
        //******************************
        //example 1
        wb_trans = new;
        wb_trans.address = 0;
        wb_trans.data = 8'b11xxxxxx; 
        wb_ag.bl_put(wb_trans);

        //set I2C bus ID
        wb_trans = new;
        wb_trans.address = 1;
        wb_trans.data = 8'h05;
        wb_ag.bl_put(wb_trans);
        
        //set bus command
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx110;
        wb_ag.bl_put(wb_trans);

        //wait for interrupt
        wb_ag.bus.wait_for_interrupt();
        //$display("interrupt received");
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);

        //************************************
        //read back random data
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
        for(int i=0; i<64; i++)begin
          //command
          wb_trans = new;
          wb_trans.address = 2;
          wb_trans.data = 8'bxxxxx010;
          wb_ag.bl_put(wb_trans);
          //wait for irq
          wb_ag.bus.wait_for_interrupt();
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
      end
    join
  endtask
  task rand_wr_test();
    fork
      begin : i2c_flow
        //write 64 values to i2c slave
        i2c_trans = new;
        i2c_ag.bl_put(i2c_trans);
      end
      begin : wb_flow
        //******************************
        //example 1
        wb_trans = new;
        wb_trans.address = 0;
        wb_trans.data = 8'b11xxxxxx; 
        wb_ag.bl_put(wb_trans);

        //set I2C bus ID
        wb_trans = new;
        wb_trans.address = 1;
        wb_trans.data = 8'h05;
        wb_ag.bl_put(wb_trans);

        //set bus command
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx110;
        wb_ag.bl_put(wb_trans);
        wb_ag.bus.wait_for_interrupt();

        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);
        //********************************
        //write random value to the bus
        //start command
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx100;
        wb_ag.bl_put(wb_trans);
        wb_ag.bus.wait_for_interrupt();

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
        for(int i=0; i<64; i++) begin
          wb_rand = new; //new random wb transaction
          wb_rand.address = 1;
          //wb_rand.data = i;
          success = wb_rand.randomize();
          wb_ag.bl_put(wb_rand);

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
        //interrupt received, clear irq flag
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);
      end
    join
  endtask
  task alternate_test();
    fork
      begin : i2c_flow
        //alternating reads and writes
        for(int i=127; i>=0; i--) begin
          //write value to i2c slave
          i2c_trans = new;
          i2c_ag.bl_put(i2c_trans);
          //read value from i2c slave
          i2c_trans = new;
          i2c_trans.data_queue.push_front(i);
          i2c_ag.bl_put(i2c_trans);
        end
      end
      begin : wb_flow
        //******************************
        //example 1
        wb_trans = new;
        wb_trans.address = 0;
        wb_trans.data = 8'b11xxxxxx; 
        wb_ag.bl_put(wb_trans);

        //set I2C bus ID
        wb_trans = new;
        wb_trans.address = 1;
        wb_trans.data = 8'h05;
        wb_ag.bl_put(wb_trans);
        
        //set bus command
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.data = 8'bxxxxx110;
        wb_ag.bl_put(wb_trans);

        //wait for interrupt
        wb_ag.bus.wait_for_interrupt();
        //$display("interrupt received");
        wb_trans = new;
        wb_trans.address = 2;
        wb_trans.we = 1;
        wb_ag.bl_put(wb_trans);

        //************************************
        //alternating read 127-0, write 128-255 to the bus
        for(int i=0; i<128; i++) begin
          //write value
          //start command
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
          wb_trans.data = alt_write_val_cov;
          wb_ag.bl_put(wb_trans);
          alt_write_val_cov++;
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

  //Register Tests
  task invalid_test();
    $display("INVALID ADDRESS/ALIASING TEST BEGIN");
    //example 1
    wb_trans = new;
    wb_trans.address = 0;
    wb_trans.data = 8'b11xxxxxx;
    wb_ag.bl_put(wb_trans);

    //read original value of registers
    wb_trans = new;
    wb_trans.address = 0;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[0] = wb_trans.data;
    $display("Original Data for CSR: %b", original_data[0]);

    wb_trans = new;
    wb_trans.address = 1;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[1] = wb_trans.data;
    $display("Original Data for DPR: %b", original_data[1]);

    wb_trans = new;
    wb_trans.address = 2;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[2] = wb_trans.data;
    $display("Original Data for CMDR: %b", original_data[2]);

    wb_trans = new;
    wb_trans.address = 3;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[3] = wb_trans.data;
    $display("Original Data for FSMR: %b", original_data[3]);

    //register write
    wb_trans = new;
    wb_trans.address = 1;
    wb_trans.data = 8'h05;
    wb_ag.bl_put(wb_trans);

    //check other regs haven't been affected
    wb_trans = new;
    wb_trans.address = 0;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    post_transaction_data[0] = wb_trans.data;
    $display("Post Write Data for CSR: %b", post_transaction_data[0]);

    wb_trans = new;
    wb_trans.address = 1;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    post_transaction_data[1] = wb_trans.data;
    $display("Post Write Data for DPR: %b", post_transaction_data[1]);
    
    wb_trans = new;
    wb_trans.address = 2;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    post_transaction_data[2] = wb_trans.data;
    $display("Post Write Data for CMDR: %b", post_transaction_data[2]);

    wb_trans = new;
    wb_trans.address = 3;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    post_transaction_data[3] = wb_trans.data;
    $display("Post Write Data for FSMR: %b", post_transaction_data[3]);

    if(post_transaction_data[0] == 8'b11100000 &&
      post_transaction_data[1] == 8'b00000000 &&
      post_transaction_data[2] == 8'b10000000 &&
      post_transaction_data[3] == 8'b00000000   ) begin
      $display("RESULTS: CORRECT VALUES RECIEVED");
    end 
    else begin
      $display("RESULTS: INCORRECT VALUES RECIEVED");
    end
    $display("END TEST");
  endtask
  task read_only_test(); 
    $display("WRITE TO READ ONLY REGISTER TEST BEGIN");
    //example 1
    wb_trans = new;
    wb_trans.address = 0;
    wb_trans.data = 8'b11xxxxxx;
    wb_ag.bl_put(wb_trans);

    //read original value of registers
    wb_trans = new;
    wb_trans.address = 0;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[0] = wb_trans.data;
    //$display("Original Data in CSR: %b", original_data[0]);

    wb_trans = new;
    wb_trans.address = 1;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[1] = wb_trans.data;
    //$display("Original Data in DPR: %b", original_data[1]);
    
    wb_trans = new;
    wb_trans.address = 2;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[2] = wb_trans.data;
    //$display("Original Data in CMDR: %b", original_data[2]);

    wb_trans = new;
    wb_trans.address = 3;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[3] = wb_trans.data;
    //$display("Original Data in FSMR: %b", original_data[3]);

    //write to FSM reg
    wb_trans = new;
    wb_trans.address = 3;
    wb_trans.data = 8'b11111111;
    wb_ag.bl_put(wb_trans);

    //check to see if the write went through and make sure no aliasing
    wb_trans = new;
    wb_trans.address = 0;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    post_transaction_data[0] = wb_trans.data;
    //$display("Post Write Data for CSR: %b", post_transaction_data[0]);

    wb_trans = new;
    wb_trans.address = 1;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    post_transaction_data[1] = wb_trans.data;
    //$display("Post Write Data for DPR: %b", post_transaction_data[1]);

    wb_trans = new;
    wb_trans.address = 2;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    post_transaction_data[2] = wb_trans.data;
    //$display("Post Write Data for CMDR: %b", post_transaction_data[2]);

    wb_trans = new;
    wb_trans.address = 3;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    post_transaction_data[3] = wb_trans.data;
    //$display("Post Write Data for FSMR: %b", post_transaction_data[3]);

    if(post_transaction_data[0] == 8'b11100000 &&
      post_transaction_data[1] == 8'b00000000 &&
      post_transaction_data[2] == 8'b10000000 &&
      post_transaction_data[3] == 8'b00000000   ) begin
      $display("RESULTS: CORRECT VALUES RECIEVED");
    end
    else begin
      $display("RESULTS: INCORRECT VALUES RECIEVED");
    end
    $display("END TEST");
  endtask
  task default_register_vals();
    $display("CHECK DEFAULT VALUES OF REGISTERS TEST BEGIN");
    //collect reset values in registers
    wb_trans = new;
    wb_trans.address = 0;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[0] = wb_trans.data;
    //$display("Reset Value Collected for CSR: %b", original_data[0]);

    wb_trans = new;
    wb_trans.address = 1;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[1] = wb_trans.data;
    //$display("Reset Value Collected for DPR: %b", original_data[1]);

    wb_trans = new;
    wb_trans.address = 2;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[2] = wb_trans.data;
    //$display("Reset Value Collected for CMDR: %b", original_data[2]);

    wb_trans = new;
    wb_trans.address = 3;
    wb_trans.we = 1;
    wb_ag.bl_put(wb_trans);
    original_data[3] = wb_trans.data;
    //$display("Reset Value Collected for FSMR: %b", original_data[3]);

    //check values
    if(original_data[0] == 8'b00000000 &&
      original_data[1] == 8'b00000000 &&
      original_data[2] == 8'b10000000 &&
      original_data[3] == 8'b00000000   ) begin
      $display("RESULTS: CORRECT VALUES RECIEVED");
    end
    else begin
      $display("RESULTS: INCORRECT VALUES RECIEVED");
    end
    $display("TEST END");  
  endtask

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