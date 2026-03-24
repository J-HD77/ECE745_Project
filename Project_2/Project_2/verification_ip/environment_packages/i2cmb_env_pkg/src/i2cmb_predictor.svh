class i2cmb_predictor extends ncsu_component #(.T(wb_transaction));

  ncsu_component#(.T(i2c_transaction))  scoreboard;
  i2c_transaction                       transport_trans;
  i2cmb_env_configuration               configuration;

  bit          [I2C_ADDR_WIDTH-1:0]     addr;
  bit          [I2C_DATA_WIDTH-1:0]     write_data[];
  bit          [I2C_DATA_WIDTH-1:0]     read_data[];
  i2c_op_t                              op;
  bit          [1:0]                    state;
  parameter    [1:0]                    wait_for_start      = 0,
                                        wait_for_addr       = 1,
                                        wait_for_write_data = 2,
                                        wait_for_read_data  = 3;

  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void set_scoreboard(ncsu_component#(.T(i2c_transaction)) scoreboard);
      this.scoreboard = scoreboard;
  endfunction

  virtual function void nb_put(wb_transaction trans);
    case (state)
      wait_for_start        : begin
        if (trans.address == 2 &&
            trans.we == 1 &&
            trans.data[2:0] == 3'b100 ) begin // This is Start command
          state = wait_for_addr;
        end
      end
      wait_for_addr         : begin
        if(trans.address == 1 && trans.we == 1) begin
          addr = trans.data >> 1;

          if(trans.data[0]) op = READ;
          else op = WRITE; 

          if(trans.data[0]) state = wait_for_read_data; 
          else state = wait_for_write_data;
        end
      end
      wait_for_write_data   : begin
        //get write data, loop until stop bit
        if(trans.address == 1 && trans.we == 1) begin
          write_data = new[write_data.size()+1](write_data);
          write_data[write_data.size()-1] = trans.data;
          state = wait_for_write_data;
        end
        //stop bit
        else if(trans.address == 2 && trans.we == 1 && trans.data[2:0] == 3'b101) begin
          transport_trans = new;
          transport_trans.addr = addr;
          transport_trans.op = op;
          transport_trans.data = write_data;
          scoreboard.nb_transport(transport_trans, null);
          write_data.delete();
          state = wait_for_start;
        end
      end
      wait_for_read_data    : begin
        //get read data, loop until stop bit
        if(trans.address == 1 && trans.we == 0) begin 
          read_data = new[read_data.size()+1](read_data);
          read_data[read_data.size()-1] = trans.data;
          state = wait_for_read_data;
        end
        else if(trans.address == 2 && trans.we == 1 && trans.data[2:0] == 3'b101) begin
          transport_trans = new;
          transport_trans.addr = addr;
          transport_trans.op = op;
          transport_trans.data = read_data;
          scoreboard.nb_transport(transport_trans, null);
          read_data.delete();
          state = wait_for_start;
        end
      end
      default: state = wait_for_start;
    endcase
  endfunction
endclass