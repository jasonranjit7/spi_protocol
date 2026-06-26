module spi_slave(input sclk,
                 input rst,
                 input mosi,
                 input cs,
                 output reg miso,
                 output reg [7:0] sl_in
                );
  
  reg [7:0] sl_out;
  reg state, nxt_state;
  reg [2:0] count;
  
  localparam IDLE = 1'b0,
  			 TRANSFER = 1'b1;
  
  //bit counter
  always@(negedge sclk) begin
    if(rst)
      count <= 0;
    else
      count <= count + 1;
  end
  
  //state register
  always@(negedge sclk) begin
    if(rst)
      state <= IDLE;
    else 
      state <= nxt_state;
  end
  
  //shift reg
  always@(negedge sclk) begin
    if(rst) begin
      sl_out <= 8'b11111111;
      sl_in <= 8'd0;
    end
    else if(state == TRANSFER) begin
      sl_out <= {sl_out[6:0],1'b0}; //MSB shifted out
      sl_in <= {mosi, sl_in[7:1]}; //MOSI shifted into MSB
    end
  end

  always@(*) begin
    nxt_state = state;
    case(state)
      IDLE: begin
        if(!cs) //slave turns on at cs low
          nxt_state = TRANSFER;
        else
          nxt_state = IDLE;
      end
      TRANSFER: begin
        miso = sl_out[7]; //MSB sent out
        if(!cs && count<8)
          nxt_state = TRANSFER;
        else begin
          nxt_state = IDLE;
        end
      end
      default: nxt_state = IDLE;
    endcase
  end
endmodule
