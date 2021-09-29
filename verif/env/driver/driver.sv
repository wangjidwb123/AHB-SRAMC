`ifndef DRIVER_SV
`define DRIVER_SV

class driver;
  mailbox         agt2drv_mbx = new();     //创建邮箱，以采集由agent发送至driver的数据包（无时序）
  transaction     tr;   
  // 从上面获取数据，传会通过interface传，声明为virtual是语法规定，对interface的定义必须要声明成virtual
  virtual  ahb_slv_if  slv_if;             //driver会将接收到的数据按照AHB时序处理后，通过接口interface发送至DUT
  int             tr_num;                  //发包数量，在testcase中告知
  //把数据打一拍，按照规定数据比address晚一拍，晚一个时钟周期发出去，所以用它把数据寄存一下，晚一拍在发出去，为了时序的作用
  logic  [31:0]   hwdata_ld;               //做时序用途，因为数据阶段会比地址阶段晚一拍发送。1d表示的含义是：1 cycle delay

  //通过mailbox跟外面的agt的mailbox连接起来，这样才是跟agt用的同一个mailbox，取出来的数才是从agent里面来的
  extern function new(mailbox agt2drv_mbx,virtual ahb_slv_if slv_if,int tr_num);
  extern function build();                 //new函数主要将driver内部成员（从generator发送到agent，再到driver的
  extern task run();                       //tr数据包）与DUT的外部接口DUT成员连接起来，以便数据发送

endclass

//mailbox agt2drv_mbx：通过mailbox跟外面的agt的mailbox连接起来，这样才是跟agt用的同一个mailbox，取出来的数才是从agent里面来的
//virtual ahb_slv_if slv_if：这里是interface是和DUT的interface连接起来的，因为在内部只能通过内部成员进行操作，内部操作的是在class里面定义的东西。相当于邮箱中收到一个tr，给到内部的tr，然后再通过内部的tr把内部成员slave_if的接口进行一个赋值，再通过内部的slv_if跟外部的连在一起就传到dut去了
function driver::new(mailbox agt2drv_mbx,virtual ahb_slv_if slv_if,int tr_num);
  this.agt2drv_mbx = agt2drv_mbx;          //通过公共邮箱，建立agent与driver之间的连接
  this.slv_if = slv_if;                //接口的作用也是为了建立driver与DUT之间的连接，类似邮箱的作用
  this.tr_num = tr_num;
endfunction

function driver::build();
endfunction

task driver::run();                        //run将对agent发来的数据进行时序处理，再经过接口发送进入DUT
  @(posedge slv_if.hresetn);               //在run开始之前，先等待DUT的复位信号失效，由低变高
  @slv_if.drv_cb;
  @slv_if.drv_cb;                          //等待两个时钟周期
  repeat(tr_num)begin
    tr = new();                            //创建数据包对象
    agt2drv_mbx.get(tr);                   //将由agent发送来的数据从邮箱mailbox中取出，mailbox是一个FIFO行为
    // wait 是等待一个事件被触发
    wait(slv_if.hready_resp);              //master需要看到slave ready信号才会发送数据，Hready_resp是slave发过来的
    // 以下赋值，左侧是DUT的接口，右侧是tr的数据
    //把tr里面产生的数据送到到dut的slv_if里面，把这些值赋值过去wait等待slv_if和hready_resp的握手。模拟一个真实的行为，master要看到slv_ready之后才去发。
    slv_if.drv_cb.hsel   <= tr.hsel;     //driver是去模拟master的行为时序，等slave ready为高时，才将数据发出
    slv_if.drv_cb.haddr  <= tr.haddr;
    slv_if.drv_cb.htrans <= tr.htrans;
    slv_if.drv_cb.hwrite <= tr.hwrite;
    slv_if.drv_cb.hsize  <= tr.hsize;    //右侧数据为generator进过agent发送来driver的数据  
    slv_if.drv_cb.hready <= 1'b1;        //常高
    //hwdata在generator产生的时候是在同一个数据包里面产生的，但是数据是寄存在hwdata_id里面,等一拍后再把data送出去，这样看到的就是地址数据，间隔着出去的。这就是做driver的目的。就是要把整个要发送的数据按照标准的接口协议给发送出去。
    hwdata_ld            <= tr.hwdata;   //地址和控制信号相对于写数据信号寄存一拍
    @slv_if.drv_cb;                      //等待一个时钟周期，再发送写数据信号（总线协议时序要求）
    slv_if.drv_cb.hwdata <= hwdata_ld; 
  end
  
  // 包发完后等10个时间单位，为了做后续的处理，10是随便取的，必须要有，不然最后一个命令如果是读命令，那么仿真结束，就收不到了。
  repeat(10)begin
    @slv_if.drv_cb;                        //后续处理，等待几个周期，以防止尾巴上的数据丢失
  end

endtask

`endif


