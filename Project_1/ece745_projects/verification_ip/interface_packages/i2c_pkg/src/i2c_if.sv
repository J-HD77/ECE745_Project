interface i2c_if #(      
      int NUM_I2C_BUSSES = 1,
      int I2C_ADDR_WIDTH = 7,
      int I2C_DATA_WIDTH = 8  
  )
  (
    input triand [NUM_I2C_BUSSES-1:0] scl_i, // I2C Clock inputs
    input triand [NUM_I2C_BUSSES-1:0] sda_i, // I2C Data inputs 
    //output triand [NUM_I2C_BUSSES-1:0] sci_o; // I2C Clock outputs [not used for proj 1]
    output bit [NUM_I2C_BUSSES-1:0] sda_o // I2C Data outputs
  );

  // Project 1 Enum 
  // I2C Operations (Write & Read)
  typedef enum bit {WRITE=1'b0, READ=1'b1} i2c_op_t;
  typedef enum bit [1:0] {NONE=2'b00, START=2'b01, DATA=2'b10, STOP=2'b11} i2c_op_fsm;

  bit [I2C_ADDR_WIDTH:0] SLAVE_1_ADDR; 
  assign SLAVE_1_ADDR = 7'b0100010; // slave 1 address

  // Waits for and captures transfer start
  task wait_for_i2c_transfer ( output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
    bit data_bit;
    i2c_op_fsm operation;
    bit read_stop;
    bit [I2C_ADDR_WIDTH - 1:0] SLAVE_ADDR;

    op = WRITE;
    operation = NONE;
    sda_o = 1'b1;
    read_stop = 1'b0;
    
    // wait for start bit
    while(operation != START) begin
      read(operation, data_bit);
    end

    //read in address
    for(int i = I2C_ADDR_WIDTH-1; i >= 0; i--) begin
      read(operation, data_bit);
      SLAVE_ADDR[i] = data_bit;
    end

    // read in r/w from sda
    read(operation, data_bit);

    // if address received is the slave address (ack) then if a write op read in write data, else return 
    if(SLAVE_ADDR == SLAVE_1_ADDR) begin

      // send ACK
      write_bit(0); 
      // assign operation
      op = data_bit ? READ : WRITE;

      // check operation for next
      if(op == WRITE) begin
          // read data
          while(!read_stop) begin
            // get all data bits
            write_data = new[write_data.size()+1](write_data);
            for(int i = I2C_DATA_WIDTH-1; i >= 0; i--) begin
                read(operation, data_bit);
                if(operation != DATA) begin
                  write_data = new[write_data.size()-1](write_data);
                  read_stop = 1'b1;
                  break;
                end
                if (!read_stop) write_data[write_data.size()-1][i] = data_bit;
            end
            //acknowledge if not stop condition
            if(!read_stop) begin
              write_bit(0);
            end
          end
      end
    end
  endtask

  // Provides data for read operation
  task provide_read_data ( input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);
    i2c_op_fsm operation;
    bit data_bit;

    // read data bit
    transfer_complete = 0;
    for(int i = I2C_DATA_WIDTH-1; i >= 0; i--) begin
      write_bit(read_data[0][i]);
    end

    // read ACK/NACK
    read(operation, data_bit);

    if(data_bit) begin
      read(operation, data_bit);
      if(operation == STOP) transfer_complete = 1;
    end
  endtask

  // Returns data observed
  task monitor ( output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);
    bit data_bit;
    i2c_op_fsm operation;
    bit stop_reading;

    operation = NONE;
    stop_reading = 0;

    // WAIT
    while(operation != START) begin
      read(operation, data_bit);       
    end

    // GET ADDRESS
    for(int i = I2C_ADDR_WIDTH-1; i >= 0; i--) begin
      read(operation, data_bit);
      addr[i] = data_bit;
    end
    
    read(operation, data_bit);
    op = data_bit ? READ : WRITE;
    data = new[1];

    while(!stop_reading) begin
      read(operation, data_bit);
      for(int i = I2C_DATA_WIDTH-1; i >= 0; i--) begin
          // read data
          read(operation, data_bit);
          // exits if stopped
          if(operation == STOP) begin 
            stop_reading = 1;
            break;
          end
          // stores data
          data[data.size()-1][i] = data_bit; 
      end
      if(!stop_reading) begin
          data = new[data.size()+1] (data);
      end
    end   
  endtask

  // Read Operation FSM (https://www.analog.com/en/resources/technical-articles/i2c-timing-definition-and-specification-guide-part-2.html)
  task read(output i2c_op_fsm read_operation, output bit data);
    fork
      begin // START
        wait(scl_i); 
        @(negedge sda_i);
        read_operation = START;
      end

      begin // DATA
        @(posedge scl_i); 
        data = sda_i;
        @(negedge scl_i);
        read_operation = DATA;
      end
      
      begin // STOP
        @(posedge scl_i);
        @(posedge sda_i);
        read_operation = STOP;
      end
    join_any
  endtask

  task write_bit(input bit write_bit);
    sda_o = write_bit;
    @(posedge scl_i);
    @(negedge scl_i);
    sda_o = 1;
  endtask
endinterface