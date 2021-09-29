`ifndef AHB_SLV_IF_SV
`define AHB_SLV_IF_SV

interface ahb_slv_if(input hclk);        //时钟信号一般声明在接口名后
  logic           hresetn;               //低电平有效复位信号
  logic           hsel;                  //slave选择信号
  logic           hwrite;                //读/写命令(控制信号)
  logic           hready;                //由mater发给slave(状态信号)，高：有效；低，无效
  logic  [1:0]    htrans;                //指示命令是否有效(控制信号)
  logic  [2:0]    hsize;                 //传输总线的有效数据位(控制信号)
  logic  [2:0]    hburst;                //是否连续传输(控制信号)
  logic  [31:0]   haddr;                 //32位系统总线地址信号
  logic  [31:0]   hwdata;                //写数据总线信号
  logic           hready_resp;           //hready_out(状态信号)，slave输出给master，表明slave是否OK
  logic  [1:0]    hresp;                 //hrdata信号(状态信号)，表明传输是否OK，00：OKAY，01：ERROR
  logic  [31:0]   hrdata;                //读数据总线信号

  clocking  drv_cb@(posedge hclk);       //主要用于显式同步时钟域
    output      hsel;           
    output      hready;        
    output      haddr;       //对于driver而言，它自身是一个master，通过接口interface按照AHB协议与DUT相连，  
    output      htrans;      //所以，其信号的输入输出应以DUT为依据；
    output      hsize;       //因此，driver输出信号除了常规AHB的地址信号、读/写数据信号，控制信号，
    output      hwrite;      //还有hsel选择信号，和hready(master输出)状态信号
    output      hwdata;
    input       hrdata;      //输入—读数据总线信号
  endclocking

  //monitor是采集所有接口上的东西，所以都是input，送到scoreboard去
  clocking  mon_cb@(posedge hclk);        //主要用于显式同步时钟域
    input      hsel;
    input      hready;
    input      haddr;         //对于monitor而言，它通过DUT、接口和driver相连接，他会采集所有接口上的信息，
    input      htrans;        //然后通过邮箱mailbox将数据送到Scoreboard进行比对，由于数据传输不是burst传输，
    input      hsize;         //所以，控制信号不需要定义burst信号，
    input      hwrite;        //此外monitor和driver中的hrdata信号都为input类型，它们都是由DUT输入。
    input      hwdata;
    input      hrdata;                   //输入—读数据总线信号
  endclocking

  modport driver(clocking drv_cb);       //modport是module port模块端口的简写，它为接口内部提供不同的视图，
  modport monitor(clocking mon_cb);      //这里的modport基于clocking的方式驱动信号，clocking中只需声明方向。

endinterface

`endif

