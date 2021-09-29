`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

class environment;
  generator               gen;            //environment中包含了generator、agent、driver等子组件,并且会对其进行调用
  agent                   agt;             
  driver                  drv;

  int                     tr_num;        //定义发包数目，发挥指挥作用
   
  mailbox       gen2agt_mbx = new();      //environment顶层会定义公共邮箱，进行邮箱连接，传递数据
  mailbox       agt2drv_mbx = new();
  mailbox       agt2scb_mbx = new();

  virtual    ahb_slv_if      slv_if;      //env顶层通过接口interface与子组件之间进行连接
  
  //new是传递更外部的slv_if，把interface传给我们的driver，后面是发包的数目
  extern function new(virtual ahb_slv_if slv_if,int tr_num);
  extern function build();
  extern task run();
  
endclass

//new和build都是起连接的作用，只不过就是new的时候跟把env上面一层的相关的接口信号连接到env内部的成员里面来；
//build阶段就是把new阶段连接的成员信息又连接到drv里面来
//slv_if和tr_num是外部的testcase给的
//注意interface要定义为virtual

//new是传递更外部的slv_if，把interface传给我们的driver，后面是发包的数目
function environment::new(virtual ahb_slv_if slv_if,int tr_num);
  this.slv_if = slv_if;            //new函数执行时，会将env顶层外部（DUT传递来的）接口信号与其子组件连接
  this.tr_num = tr_num;
endfunction


function environment::build();       //通过邮箱、接口，构建数据传输的通道
  gen = new(gen2agt_mbx, tr_num);         //env层公共邮箱的建立是为了实现数据包tr在组件之间的传递
  agt = new(gen2agt_mbx,agt2drv_mbx,agt2scb_mbx,tr_num);
  drv = new(agt2drv_mbx,slv_if,tr_num);   //slv_if负责连接DUT tr_num的具体数值有testcase层给出
endfunction

task environment::run();
  fork       //并发执行，可以直接用begin...end，否则会卡住
     gen.run();                           //产生数据，给到agent
     agt.run();                           //将接受自generator的数据通过邮箱发送至drv，scb
     drv.run();                           //将接受自generator的数据，按照AHB时序协议通过接口slv_if送至DUT
  join
endtask

`endif

