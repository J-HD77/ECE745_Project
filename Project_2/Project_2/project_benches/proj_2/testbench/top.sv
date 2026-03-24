`timescale 1ns / 10ps

module top();

  import definition_pkg::*;
  import ncsu_pkg::*;
  import wb_pkg::*;
  import i2c_pkg::*;
  import i2cmb_env_pkg::*;

  parameter int WB_ADDR_WIDTH = 2;
  parameter int WB_DATA_WIDTH = 8;
  parameter int NUM_I2C_BUSSES = 1;
  parameter int I2C_ADDR_WIDTH = 7;
  parameter int I2C_DATA_WIDTH = 8;

  bit  clk;
  bit  rst = 1'b1;
  wire cyc;
  wire stb;
  wire we;
  tri1 ack;
  wire [WB_ADDR_WIDTH-1:0] adr;
  wire [WB_DATA_WIDTH-1:0] dat_wr_o;
  wire [WB_DATA_WIDTH-1:0] dat_rd_i;
  wire irq;
  tri  [NUM_I2C_BUSSES-1:0] scl;
  tri  [NUM_I2C_BUSSES-1:0] sda;

  // ****************************************************************************
  // Clock generator (generates a 10ns clock, 5ns high and low)
  initial begin : clk_gen
    forever #5ns clk <= ~clk;
  end

  // ****************************************************************************
  // Reset generator (active high)
  initial begin : rst_gen
    #113ns rst = 1'b0;
  end

/* FOR PROJECT 1
  // ****************************************************************************
  // Monitor Wishbone bus and display transfers in the transcript
  initial begin : wb_monitoring
    bit [WB_ADDR_WIDTH-1:0] wb_address;
    bit [WB_DATA_WIDTH-1:0] wb_data;
    bit write_enable;

    @(clk);
    forever begin
      wb_bus.master_monitor(wb_address, wb_data, write_enable);
      if (write_enable) 
        $display("WB_BUS Monitor WRITE- Address: 0x%h | Data: 0x%h", wb_address, wb_data);
      else 
        $display("WB_BUS Monitor READ- Address: 0x%h | Data: 0x%h", wb_address, wb_data);
    end
  end

  // ****************************************************************************
  // Monitor I2C bus and display transfers in the transcript
  initial begin: monitor_i2c_bus
    bit [I2C_ADDR_WIDTH-1:0] i2c_addr;
    bit [I2C_DATA_WIDTH-1:0] i2c_data[];
    bit operation;

    forever begin
        i2c_bus.monitor(i2c_addr, operation, i2c_data);
        for(int i = 0; i < i2c_data.size()-1; i++) begin
          if(operation == 1'b0) begin
            $display("I2C_BUS WRITE Transfer: addr - %x, data - %d", i2c_addr, i2c_data[i]);
          end
          else begin
            $display("I2C_BUS READ Transfer: addr - %x, data - %d", i2c_addr, i2c_data[i]);
          end
        end
    end
  end

  // ****************************************************************************
  // Define the flow of the simulation
  // Loads a queue with values 100 to 131
  bit [I2C_DATA_WIDTH-1:0] read_data_queue [$];
  initial begin : load_data_queue
    for(int i=100; i<132; i++) begin
      read_data_queue.push_back(i);
    end
    for(int i=63; i>=0; i--) begin
      read_data_queue.push_back(i);
    end
  end

  // I2C
  bit [I2C_DATA_WIDTH-1:0] i2c_write_data[];
  bit [I2C_DATA_WIDTH-1:0] i2c_read_data[];
  bit i2c_op;
  bit transfer_complete;
  initial begin : i2c_flow
    i2c_read_data = new[1];

    forever begin
      transfer_complete = 1'b0;
      // capture start of transfer
      i2c_bus.wait_for_i2c_transfer(i2c_op, i2c_write_data);
      // if a read command
      if(i2c_op) begin
         while(!transfer_complete) begin
            i2c_read_data[0] = read_data_queue.pop_front();
            i2c_bus.provide_read_data(i2c_read_data, transfer_complete);
         end
      end
    end
  end

  // ****************************************************************************
  // WB Flow
  initial begin : wb_flow
    logic [WB_DATA_WIDTH-1:0] read_data_wb = 0;

    // 6.1 Example 1
    // Task: Enable the IICMB core after power-up.
    // Write byte “1xxxxxxx” to the CSR register. This sets bit E to '1', enabling the core.
    #1000 wb_bus.master_write(0, 8'b11xxxxxx);

    // 6.3 Example 3
    // System bus actions:
    // This is the ID of desired I2C bus.
    wb_bus.master_write(1, 8'h05);
    // This is Set Bus command.
    wb_bus.master_write(2, 8'bxxxxx110);
    // Wait for interrupt or until DON bit of CMDR reads '1'.
    wait(irq) wb_bus.master_read(2, read_data_wb);

    //*********************************************
    // write 0-31 to the bus
    // Start command.
    wb_bus.master_write(2, 8'bxxxxx100);
    wait(irq) wb_bus.master_read(2, read_data_wb);

    // This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '0', which means writing.
    wb_bus.master_write(1, 8'h44);
    // This is Write command.
    wb_bus.master_write(2, 8'bxxxxx001);
    wait(irq) wb_bus.master_read(2, read_data_wb);

    // Write vals
    for(int i=0; i<32; i++) begin
      wb_bus.master_write(1, i); // data
      wb_bus.master_write(2, 8'bxxxxx001); // write
      wait(irq) wb_bus.master_read(2, read_data_wb);
    end

    // This is Stop command.
    wb_bus.master_write(2, 8'bxxxxx101);
    wait(irq) wb_bus.master_read(2, read_data_wb);

    //*********************************************
    // Read back 100-131

    // start command
    wb_bus.master_write(2, 8'bxxxxx100);
    wait(irirqq) wb_bus.master_read(2, read_data_wb);
    
    // read command to slave 0x22
    wb_bus.master_write(1, 8'h45);
    
    // write command
    wb_bus.master_write(2, 8'bxxxxx001);
    wait(irq) wb_bus.master_read(2, read_data_wb);
    
    //read values
    for(int i=0; i<31; i++) begin
      // read command
      wb_bus.master_write(2, 8'bxxxxx010);
      wait(irq) wb_bus.master_read(2, read_data_wb);
      wb_bus.master_read(1, read_data_wb);
    end

    // read command (nack)
    wb_bus.master_write(2, 8'bxxxxx011);
    wait(irq) wb_bus.master_read(2, read_data_wb);
    wb_bus.master_read(1, read_data_wb);
    
    // write stop command
    wb_bus.master_write(2, 8'bxxxxx101);
    wait(irq) wb_bus.master_read(2, read_data_wb);

    //*********************************************
    // alternating read 63-0/write 64-127 to the bus
    for(int i = 64; i < 128; i++) begin
      //start command
      wb_bus.master_write(2, 8'bxxxxx100);
      wait(irq) wb_bus.master_read(2, read_data_wb);

      // write command to slave 0x22
      wb_bus.master_write(1, 8'h44);
      wb_bus.master_write(2, 8'bxxxxx001);
      wait(irq) wb_bus.master_read(2, read_data_wb);
      
      //write val
      wb_bus.master_write(1, i); // data
      wb_bus.master_write(2, 8'bxxxxx001); // write
      wait(irq) wb_bus.master_read(2, read_data_wb);
      
      // write stop bit
      wb_bus.master_write(2,8'bxxxxx101);
      wait(irq) wb_bus.master_read(2, read_data_wb);

      // *********************************************
      // read val
      // start command
      wb_bus.master_write(2, 8'bxxxxx100);
      wait(irq) wb_bus.master_read(2, read_data_wb);
      
      // read command to slave 0x22
      wb_bus.master_write(1,8'h45);
      
      // write command
      wb_bus.master_write(2, 8'bxxxxx001);
      wait(irq) wb_bus.master_read(2, read_data_wb);
      
      // read command
      wb_bus.master_write(2, 8'bxxxxx011);
      wait(irq) wb_bus.master_read(2, read_data_wb);
      wb_bus.master_read(1, read_data_wb);
      
      // write stop command
      wb_bus.master_write(2,8'bxxxxx101);
      wait(irq) wb_bus.master_read(2, read_data_wb);
    end
  end
*/
  // ****************************************************************************
  // Instantiate the I2C Slave Bus Functional Model
  i2c_if #(
        .NUM_I2C_BUSSES(NUM_I2C_BUSSES),
        .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
        .I2C_DATA_WIDTH(I2C_DATA_WIDTH)
        )
  i2c_bus (
    .clock(clk),
    .scl_i(scl),
    .sda_i(sda),
    .sda_o(sda)
    );
    
  // ****************************************************************************
  // Instantiate the Wishbone master Bus Functional Model
  wb_if #(
        .ADDR_WIDTH(WB_ADDR_WIDTH),
        .DATA_WIDTH(WB_DATA_WIDTH)
        )
  wb_bus (
    // System sigals
    .clk_i(clk),
    .rst_i(rst),
    // Master signals
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .adr_o(adr),
    .we_o(we),
    // Slave signals
    .cyc_i(),
    .stb_i(),
    .ack_o(),
    .adr_i(),
    .we_i(),
    // Shred signals
    .dat_o(dat_wr_o),
    .dat_i(dat_rd_i),
    .irq_i(irq)
    );

  // ****************************************************************************
  // PROJECT 2
  // Place an instance of i2cmb_test within top.sv
  i2cmb_test tst;

  // Modified test_flow
  initial begin : test_flow
    ncsu_config_db#(virtual i2c_if #(.NUM_I2C_BUSSES(NUM_I2C_BUSSES),
                                      .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
                                      .I2C_DATA_WIDTH(I2C_DATA_WIDTH)))
                                      ::set("tst.env.i2c_ag", i2c_bus);
    
    ncsu_config_db#(virtual wb_if #(.ADDR_WIDTH(WB_ADDR_WIDTH),
                                    .DATA_WIDTH(WB_DATA_WIDTH)))
                                    ::set("tst.env.wb_ag", wb_bus);

    tst = new("tst", null);
    wait (rst == 0); // active low
    tst.run();
    #20000ns $finish();                   
  end
  // ****************************************************************************
  // Instantiate the DUT - I2C Multi-Bus Controller
  \work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
    (
      // ------------------------------------
      // -- Wishbone signals:
      .clk_i(clk),         // in    std_logic;                            -- Clock
      .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
      // -------------
      .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
      .stb_i(stb),         // in    std_logic;                            -- Slave selection
      .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
      .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
      .we_i(we),           // in    std_logic;                            -- Write enable
      .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
      .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
      // ------------------------------------
      // ------------------------------------
      // -- Interrupt request:
      .irq(irq),           //   out std_logic;                            -- Interrupt request
      // ------------------------------------
      // ------------------------------------
      // -- I2C interfaces:
      .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
      .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
      .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
      .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
      // ------------------------------------
    );
endmodule