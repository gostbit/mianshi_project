module testbench;
    logic clk, rst_n;
    // tb - master wire
    logic [7 : 0]       tb_master_data;
    logic                tb_master_valid;
    logic                master_tb_ready;
    // master - slave logic
    logic [7 : 0]       master_slave_data;
    logic                master_slave_valid;
    logic                slave_master_ready;
    // slave - tb logic
    logic [7 : 0]       slave_tb_data;
    logic                slave_tb_valid;
    logic                tb_slave_ready;
    //other
    wire transmit_handshake_success = tb_master_valid & master_tb_ready;
    wire reseive_handshake_success = slave_tb_valid  & tb_slave_ready;

    //tb to master
    ms master(
      //from upstream node 
      .clk(clk), 
      .rst_n(rst_n),
      .u2d_data_i(tb_master_data),
      .u2d_valid_i(tb_master_valid), 
      .u2d_ready_o(master_tb_ready),
      //from downstream node
      .d2u_data_o(master_slave_data),
      .d2u_valid_o(master_slave_valid),
      .d2u_ready_i(slave_master_ready)
      );

    //slave to tb
    ms slave(
      //from upstream node
      .clk(clk), 
      .rst_n(rst_n),
      .u2d_data_i(master_slave_data),
      .u2d_valid_i(master_slave_valid), 
      .u2d_ready_o(slave_master_ready),
      //from downstream node
      .d2u_data_o(slave_tb_data),
      .d2u_valid_o(slave_tb_valid),
      .d2u_ready_i(tb_slave_ready)
      );

     initial begin 
        clk <= 0;
        forever begin
          #5ns clk <= !clk;
        end
      end

    integer i,j;

    task send_value;
        input [31: 0] value_in;
        begin
            @(negedge clk);
            tb_master_valid = 1'b1;
            tb_master_data  = value_in;
            #1ns
            while (!transmit_handshake_success) begin
                $display("waiting for send %d", tb_master_data);
                @(negedge clk);
            end
        end
    endtask

    initial begin
        #1ns
        clk             = 1'b1;
        rst_n           = 1'b0;
        tb_slave_ready  = 1'b0;
        tb_master_valid = 1'b0;
        $display("Simulation Start");

        repeat (10) @(negedge clk);
        rst_n           = 1'b1;
        tb_slave_ready  = 1'b1;
        tb_master_valid = 1'b1;
        tb_master_data  = 0;

        for (i=0; i<16; i=i+1) begin
            send_value(i);
        end

        @(negedge clk);
        tb_master_valid = 1'b0;
        @(posedge clk);
        tb_slave_ready  = 1'b0;

        @(negedge clk);
        tb_master_valid = 1'b1;
        tb_master_data  = 16;
        repeat (3) @(negedge clk);
        @(posedge clk);
        tb_slave_ready  = 1'b1;

        for (i=0; i<16; i=i+1) begin
            @(negedge clk);
            tb_master_valid = 1'b0;
            send_value(i + 17);
        end

        @(negedge clk);
        tb_master_valid = 1'b0;

        repeat (10) @(negedge clk);
        $display("Simulation Finish");
        $finish();
    end
    
endmodule
