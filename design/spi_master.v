module spi_master(input miso,
                  input en,
                  input clk,
                  input rst,
                  input [7:0] data,
                  output reg cs,
                  output reg mosi,
                  output reg sclk
                 );                  
  
  reg [7:0] master_out_reg,master_in_reg;
  reg [2:0] count; 
  reg [1:0] state, nxt_state;
  reg shift;
  localparam IDLE = 2'b00,
  			 SETUP = 2'b01,
  		 	 TRANSFER = 2'b10;
  
  //sclk gen
  always@(clk) begin
    if(rst)
      sclk <= 1'b0;
    else begin
      if(state == TRANSFER)
      	sclk <= clk;
      else
        sclk <= 0;
    end
  end
  
  //state register
  always@(posedge clk) begin
    if(rst)
      state <= IDLE;
    else
      state <= nxt_state;
  end
  
  //shift register
  always@(posedge clk) begin
    if(rst) begin
      master_in_reg <= 0;
      master_out_reg <= 0;
    end
    else if(state == SETUP)
      master_out_reg  = data;
    if(shift) begin
      master_out_reg <= {master_out_reg[6:0],1'b0};
      master_in_reg <= {miso, master_in_reg[7:1]};
    end
  end	
  
  //bit counter
  always@(posedge clk) begin
    if(rst)
      count <= 0;
    else if(state == TRANSFER)
      count <= count + 1'b1;
  end
  
  always@(*) begin
    nxt_state = state;
	shift = 0;
    case(state)
      IDLE: begin
        if(en) begin
          nxt_state = SETUP;
        end
        else nxt_state = IDLE;
      end
      SETUP: begin
        cs = 1'b0; //chip select pulled low
        if(data|miso)
        	nxt_state = TRANSFER;
      end
      TRANSFER: begin
        mosi = master_out_reg[7]; //MSB sent first
        $display("mosi =%b", mosi);
        if(count < 7) begin
          shift = 1; //signal shift register
          nxt_state = TRANSFER;
        end
        else begin
          nxt_state = IDLE;
          shift = 0;
        end
      end
      default: nxt_state = IDLE;
    endcase
  end
        
  
endmodule
