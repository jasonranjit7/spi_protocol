module tb_spi_slave();
  reg sclk,rst,mosi,cs;
  wire miso;
  wire [7:0] sl_in;
  
  spi_slave DUT(.sclk(sclk),
                .rst(rst),
                .mosi(mosi),
                .cs(cs),
                .miso(miso),
                .sl_in(sl_in)
               );
  
  initial
    forever #10 sclk = ~sclk;
  
  initial begin
    sclk = 1;
    rst = 1;
    cs = 1;
  end
  
  task run;
    input m;
    begin
      mosi = m;
      @(negedge sclk);
    end
  endtask
      
    
    
  
  initial begin
    $dumpfile("image.vcd");
    $dumpvars(0,tb_spi_slave.DUT);
    repeat(2)@(negedge sclk)
    cs = 0;
    rst = 0;
    repeat(8)
      run(1'b1);
    @(negedge sclk);
    cs = 1;
    $display("sl_in reg  %b, sl_out reg  %b", sl_in, DUT.sl_out);
    $finish();
  end
endmodule
