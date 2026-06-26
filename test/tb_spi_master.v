module tb_spi_master();
  reg miso,clk,rst,en;
  reg [7:0] data;
  wire cs, mosi, sclk;
  
  //DUT instantiation
  spi_master DUT(.miso(miso),
                 .en(en),
                 .clk(clk),
                 .rst(rst),
                 .data(data),
                 .cs(cs),
                 .mosi(mosi),
                 .sclk(sclk)
                );
  
  initial
    forever #10 clk = ~clk;
  
  task transmit;
    input [7:0] d_in;
    begin
      data = d_in;
      en = 1;
      wait(DUT.state == 2'b01);
        en = 0;
    end
  endtask
  
  task receive;
    input d;
    begin
      @(negedge clk)
      miso = d;
      repeat(3)@(posedge clk);
      #1
      miso = 0;
    end
  endtask
      
  
  
  initial begin
    clk = 0;
    rst = 1;
    $dumpfile("image.vcd");
    $dumpvars(0,tb_spi_master.DUT);
    repeat(3)@(posedge clk);
    rst = 0;
    repeat(2)@(posedge clk);
    //receive(1'b1);
    repeat(2)@(posedge clk);
    //$monitor("in reg = %b",DUT.master_in_reg);
    //$monitor("out reg = %b",DUT.master_out_reg);
    transmit(8'b11001100);
    //$monitor("count = %d, state = %d, en = %b", DUT.count, DUT.state, en);
    //$monitor("count = %b, mosi = %b", DUT.count,mosi);
    repeat(20)@(posedge clk);
    $finish();
  end
endmodule
    
    
    
    
