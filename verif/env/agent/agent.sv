`ifndef AGENT_SV
`define AGENT_SV

//前三个是外部传递进来的公共邮箱，gen2agt是外面env这一层会定义一个公共邮箱，会把这个邮箱同时传给agt和gen，那么这两个邮箱就是一个邮箱了。gen在run的时候会put tr，而agt在run的时候就get tr
//agent也需要得到传输的包的个数，先定义一个类
class agent;
  int          tr_num;               //传输数据包的总个数，测试用例会告知每次传输多少个包
  mailbox      gen2agt_mbx=new();    //创建邮箱，邮箱深度不限
  mailbox      agt2drv_mbx=new();	 //mailbox是generator给到agent的，agent把它给取下来之后就会送到drv和scb这两个里面来，scb是scoreboard
  mailbox      agt2scb_mbx=new();
  
  transaction  tr;                    //在tr的传输过程中，数据内容都是一样的来源于transaction

  extern function new(mailbox gen2agt_mbx,agt2drv_mbx,agt2scb_mbx, int tr_num);
  extern function build();
  extern task run();
  
endclass

//new是在建立agent的对象的时候通过公共邮箱把gen连接起来，包括gen和drv的也连接起来
function agent::new(mailbox gen2agt_mbx,agt2drv_mbx,agt2scb_mbx, int tr_num);
  this.gen2agt_mbx = gen2agt_mbx;      //generator的外层（env层）会定义公共邮箱（形参），并将其
  this.agt2drv_mbx = agt2drv_mbx;      //同时传递给agent、generator，那么这两个邮箱就成了一个邮箱
  this.agt2scb_mbx = agt2scb_mbx;      //new函数的作用就是在创建agent对象时，通过公共邮箱，
  this.tr_num = tr_num;                //将generator、driver和Scoreboard的邮箱连接起来
endfunction

//这里有个印象,build阶段是做一些初始化的配置
function agent::build();
endfunction

//agt的作用就是可以往多个方向去put,就避免gen去往多个方向put，起一个代理的作用，帮助gen去发
task agent::run();
  repeat(tr_num)begin        //tr_num为发包数目
    tr = new();            //创建对象实体,不可省略，下边邮箱获取的数据包会用到句柄
    gen2agt_mbx.get(tr);     //从generator处获得（get）一个 实体数据包
    agt2drv_mbx.put(tr);     //将tr实体数据包发送（put）到driver
    agt2scb_mbx.put(tr);     //将tr实体数据包发送（put）到Scoreboard
  end    //此处的邮箱收发数据存在先后顺序，不可使用fork——join语句
endtask

`endif

