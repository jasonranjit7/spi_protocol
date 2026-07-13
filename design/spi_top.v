`include "spi_master.v"
`include "spi_slave.v"
module spi_top(input ready,
               input clk,
               input rst,
               input [7:0] m_data,
               output [7:0] s_data,
               output slave_done
              );
  
  wire mosi,miso,cs,sclk,m_done;
  
  spi_master master(.clk(clk),
                    .data(m_data),
                    .rst(rst),
                    .ready(ready),
                    .miso(miso),
                    .sclk(sclk),
                    .cs(cs),
                    .done(m_done)
            );
  
    spi_slave slave(.cs(cs),
                    .clk(clk),
                    .rst(rst),
                    .sclk(sclk),
                    .mosi(mosi),
                    .miso(miso),
                    .done(slave_done),
                    .s_reg(s_data)
                 );
  

  
endmodule
