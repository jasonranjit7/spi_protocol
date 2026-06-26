`include "spi_master.v"
`include "spi_slave.v"
module spi_top(input en,
               input clk,
               input rst,
               input [7:0] m_data,
               output [7:0] sl_data
              );
  
  wire mosi,miso,cs,sclk;
  
  spi_master master(.miso(miso),
             .en(en),
             .clk(clk),
             .rst(rst),
             .data(m_data),
             .mosi(mosi),
             .cs(cs),
             .sclk(sclk)
            );
  
  spi_slave slave(.sclk(sclk),
                  .rst(rst),
                  .mosi(mosi),
                  .cs(cs),
                  .miso(miso),
                  .sl_in(sl_data)
                 );
  

  
endmodule
