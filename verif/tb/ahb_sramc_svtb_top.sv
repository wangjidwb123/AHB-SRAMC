module ahb_sramc_svtb_top();
  
  bit    hclk;
  bit    sram_clk;
  bit    hresetn;    

  // 它实例化对象的名字，后面都得用这个名字，才能把test里面的interface和dut连接起来
  ahb_slv_if ahb_sramc_if(hclk);        //接口例化
 
  // test需要给它传一个interface进去，这个interface一方面连接我们的环境了，另外一方面就连接到DUT
  // 这个ahb_sram_test就是我们刚才做的testcase, sram_top是rtl。两者通过ahb_slv_if即interface连接起来。当然也会产生时钟和复位

  ahb_sram_test  test(ahb_sramc_if);       //1.通过接口例化连接测试用例testcase 这个test就是刚才做的testcase
 
  // sram_top就是我们的RTL。RTL相当于最终封了一个顶层，把sram_if和sram_core封成了一个top
  sramc_top   u_sramc_top(                 //2.通过接口例化连接DUT顶层文件；结合1、2两步骤建立DUT与TB之间的连接
              .hclk           (hclk),
              .sram_clk       (sram_clk),
              .hresetn        (ahb_sramc_if.hresetn),   	//给DUT
              .hsel           (ahb_sramc_if.hsel),			//给DUT
              .hwrite         (ahb_sramc_if.hwrite),		//给DUT
              .htrans         (ahb_sramc_if.htrans),		//给DUT
              .hsize          (ahb_sramc_if.hsize),			//给DUT
              .hready         (ahb_sramc_if.hready),		//给DUT
              .hburst         (3'b0),                   	//无用 burst没用的话就接0，在tr里面激励产生什么都关系不大了
              .haddr          (ahb_sramc_if.haddr),			//给DUT
              .hwdata         (ahb_sramc_if.hwdata),		//给DUT
              .hrdata         (ahb_sramc_if.hrdata),		//给DUT
              .dft_en         (1'b0),                   	//不测    dft不测，写成0        
              .bist_en        (1'b0),                   	//不测
              .hready_resp    (ahb_sramc_if.hready_resp),              
              .hresp          (ahb_sramc_if.hresp),
              .bist_done      ( ),                      	//不测              
              .bist_fail      ( )                       	//不测
	);

  initial begin
     forever  #10  hclk = ~ hclk;               //产生时钟信号
  end
   
  always @(*)     sram_clk = ~hclk;
   
  initial begin
     hresetn = 1;
     #1 hresetn = 0;          //复位处理
     #10 hresetn = 1;         //撤销复位 复位撤离之后才会进行数据传输
  end
  
  // 下面会把interface的reset按照外面产生的reset赋值给interface
  assign ahb_sramc_if.hresetn = hresetn;         //在开始时，先进行复位操作

endmodule


