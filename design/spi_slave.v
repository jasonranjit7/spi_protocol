module spi_slave(input cs,
                 input clk,
                 input rst,
                 input sclk,
                 input mosi,
                 output miso,
                 output reg done,
                 output reg [7:0] s_reg
                );
  
  reg sclk_delay;
  reg cs1,cs2,sclk1,sclk2,mosi1,mosi2;
  //double flop synchroniser
  always@(posedge clk) begin
    if(rst) begin
      cs1 <=1'b1;
      sclk1<=0;
      mosi1<=0;
    end
    else begin
      cs1<=cs;
      sclk1 <=sclk;
      mosi1<=mosi;
    end
  end
  
  always@(posedge clk) begin
    if(rst) begin
      cs2 <=1'b1;
      sclk2<=0;
      mosi2<=0;
    end
    else begin
      cs2<=cs1;
      sclk2 <=sclk1;
      mosi2<=mosi1;
    end
  end
  
  wire sclk_rising = sclk1 & ~sclk2;
  wire sclk_falling = ~sclk1& sclk2;
  
  reg [3:0] bit_cnt;
  //bit counter
  always@(posedge clk) begin
    if(rst||cs2)
      bit_cnt<=0;
    else if(sclk_rising)
      bit_cnt<=bit_cnt+1'b1;
  end
  
  //sample mosi at rising edge
  reg mosi_d;
  always@(posedge clk) begin
    if(rst)
      mosi_d<=0;
    else if(sclk_rising)
      mosi_d<=mosi2;
  end
      
  
  //slave memory, shift out at falling edge
  always@(posedge clk) begin
    if(rst)
      s_reg<=8'd0;
    else if(cs2)
      s_reg<=8'h42;
    else if(!cs2 && sclk_falling)
      s_reg<={s_reg[6:0],mosi_d};
  end
  
  //output logic
  always@(posedge clk) begin
    if(rst)
      done<=0;
    else begin
      if(!cs2 && sclk_falling && bit_cnt==8)
        done<=1'b1;
      else
        done<=0;
    end
  end
  
  
  
  assign miso = (!cs2)?s_reg[7]:1'bz;
  
  
endmodule
  
  
  
  
      
  
