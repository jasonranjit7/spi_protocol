module spi_master(input miso,
                  input en,
                  input clk,
                  input rst,
                  input [7:0] data,
                  output reg cs,
                  output reg mosi,
                  output sclk
                 );                  
  
  reg [7:0] master_out_reg,master_in_reg;
  reg [3:0] count; 
  reg [1:0] state, nxt_state;
  reg shift, c_rst;
  localparam IDLE = 2'b00,
  			 SETUP = 2'b01,
  		 	 TRANSFER = 2'b10;
  
  
  //sclk gen
  assign sclk = (state == TRANSFER) ? clk : 0;
  
  //state register
  always@(posedge clk) begin
    if(rst)
      state <= IDLE;
    else
      state <= nxt_state;
  end
  
  //master drives mosi at posedge
  always @(posedge clk) begin
      if (rst)
          master_out_reg <= 8'b0;
      else if (state == SETUP)
          master_out_reg <= data;
      else if (shift)
          master_out_reg <= {master_out_reg[6:0], 1'b0};
  end

  //master samples miso at negedge
  always @(negedge clk) begin
      if (rst)
          master_in_reg <= 8'b0;
      else if (shift)
          master_in_reg <= {master_in_reg[6:0], miso};
  end
  
  //bit counter
  always@(posedge clk) begin
    if(rst | c_rst)
      count <= 0;
    else if(state == TRANSFER)
      count <= count + 1'b1;
  end
  
  always@(*) begin
    nxt_state = state;
	shift = 0;
    mosi = 0;
    cs = 1;
    c_rst = 0;
    case(state)
      IDLE: begin
        if(en) begin
          nxt_state = SETUP;
        end
        else nxt_state = IDLE;
      end
      SETUP: begin
        cs = 1'b0; //chip select pulled low
        nxt_state = TRANSFER;
      end
      TRANSFER: begin
        mosi = master_out_reg[7]; //MSB sent first
        //$display("mosi =%b", mosi);
        if(count <4'd8 ) begin
          shift = (count > 4'd0) ? 1'b1 : 1'b0; //signal shift register
          nxt_state = TRANSFER;
        end
        else begin
          nxt_state = IDLE;
          shift = 0;
          c_rst = 1;
        end
      end
      default: nxt_state = IDLE;
    endcase
  end
        
  
endmodule
