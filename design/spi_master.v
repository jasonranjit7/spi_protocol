`include "tick_divider.v"
module spi_master(input clk,
                  input [7:0] data,
                  input rst,
                  input ready,
                  input miso,
                  output mosi,
                  output sclk,
                  output cs,
                  output done);
  
  reg [7:0] m_reg;
  reg tick_en;
  wire en = state==TRANSFER;
  
  
  tick_divider td(clk,rst,en,sclk);
  
  reg sclk_delay;
  
  //edge detector
  always@(posedge clk) begin
    if(rst)
      sclk_delay<=0;
    else
      sclk_delay<=sclk;
  end
  
  wire sclk_rising = sclk & ~sclk_delay;
  wire sclk_falling = ~sclk & sclk_delay;
  
  
  reg[1:0] state,nxt_state;
  localparam IDLE=0,SETUP=1,TRANSFER=2,DONE=3;
  
  reg [3:0] bit_cnt;
  //bit counter
  always@(posedge clk) begin
    if(rst)
      bit_cnt<=0;
    else if(state == TRANSFER) begin
      if(sclk_falling)
      	bit_cnt<=bit_cnt+1'b1;
    end
    else
      bit_cnt<=0;
  end
  
  reg miso_r;
  //miso capture
  always@(posedge clk) begin
    if(rst)
      miso_r<=0;
    else if(sclk_rising)
      miso_r<=miso;
  end
  
  //shift register
  always@(posedge clk) begin
    if(rst) begin
      m_reg<=0;
    end
    else begin
      if(state == SETUP)
        m_reg<=data;
      if(state == TRANSFER && sclk_falling)
        m_reg<={m_reg[6:0],miso_r};
    end
  end        
  
  //state register
  always@(posedge clk) begin
    if(rst)
      state<=IDLE;
    else
      state<=nxt_state;
  end
  
  //transition logic
  always@(*) begin
    nxt_state = state;
    case(state)
      IDLE: begin
        if(ready)
          nxt_state = SETUP;
        else
          nxt_state = IDLE;
      end
      SETUP: begin
        nxt_state = TRANSFER;
      end
      TRANSFER: begin
        if(bit_cnt<8)
          nxt_state = TRANSFER;
        else
          nxt_state = DONE;
      end
      DONE: nxt_state = IDLE;
      default: nxt_state = IDLE;
    endcase
  end
  
  assign done = state==DONE;
  assign cs = (state==SETUP||state==TRANSFER)?1'b0:1'b1;
  assign mosi = m_reg[7];
  
endmodule
        
    
      
        
  
  
