module ms(
    input   clk, 
    input   rst_n,
    input  logic [7 : 0] u2d_data_i,
    input  logic          u2d_valid_i,     // from upstream node
    output logic          u2d_ready_o,    // to upstream node

    output logic [7 : 0] d2u_data_o,
    output logic          d2u_valid_o,    // to downstream node
    input  logic          d2u_ready_i      // from downstream node
);

wire      up_handshake_success;
wire      down_handshake_success;
logic     reseive;
logic     transmit;

    assign up_handshake_success = u2d_ready_o & u2d_valid_i;   // handshake of upstream into this node fired, logic as a slave/receiver
    assign down_handshake_success = d2u_ready_i  & d2u_valid_o;  // handshake of this node to downstream fired, logic as a master/transmitter

//reseive
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        u2d_ready_o <= 0;
    end
    else case(u2d_valid_i)
            1'b1: begin
                   reseive <= 1;
                   d2u_valid_o <= u2d_valid_i;
                   end
            1'b0: begin
                   u2d_ready_o <= u2d_ready_o;
                   reseive <= 0;
                   end
            default: reseive <= 0;
        endcase
end

//transmit
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        d2u_valid_o <= 0;
        d2u_data_o <=0;
    end
    else case(d2u_ready_i)
            1'b1: begin
                transmit <= 1;
                u2d_ready_o <= d2u_ready_i;
                   end
            1'b0: begin
                transmit <= 0;
                d2u_valid_o <= d2u_valid_o;
                   end
            default: transmit <= 0;
        endcase
end

always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        transmit <= 0;
        reseive <=0;
    end
    else if((transmit || reseive) == 1) d2u_data_o <= u2d_data_i;


end

endmodule
