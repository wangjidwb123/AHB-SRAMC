`ifndef GENERATOR_SV
`define GENERATOR_SV

class generator;
  int            tr_num;            //定义了要发送的激励的数量（不同的testcase发送的激励命令数量不一样）
  transaction    tr;                //产生对象tr（tr的产生由顶层testcase告知）
  mailbox        mbx=new();         //将tr对象放入邮箱mbx中，负责数据的传递
  // event gen_data是用于内部通讯。根据不同的场景来的,每个场景产生完了就会通知另外一个线程，让它把产生完的数据放到mailbox里面。产生一个数据之后就会产生一个event，放到mailbox里面
  event          gen_data;          //定义时间，以便于内部通信
  
  // 在类中extern函数，在类外实现，这种方式工程上的用的非常多
  extern function new(mailbox mbx,int tr_num); // new的时候会把外部传来的mailbox给连接起来，generator放的mailbox就会放到这个公共的邮箱中，然后下一级的组件就从里面取; tr_num 每个testcase的tr_num不一样，在上一级generator实例化自己的时候就会把这一次testcase的tr_num传进来
  extern function build(); // 跑之前的准备工作（建立的准备工作）
  extern task write_data32(logic [31:0] addr, logic [31:0] wdata);     //只写32/16/8位数据，
  extern task write_data16(logic [31:0] addr, logic [31:0] wdata);     //testcase告诉地址addr和数据wdata，
  extern task write_data8(logic [31:0] addr, logic [31:0] wdata);      //就会产生tr对象。
  extern task write_data_random(logic [31:0] addr);           //写随机数据，随机产生tr。
  extern task write_addr_random(logic [31:0] wdata);		  //写地址随机
  extern task read_data32(logic [31:0] addr);					//读32/16/8位数据,testcase告知addr
  extern task read_data16(logic [31:0] addr);
  extern task read_data8(logic [31:0] addr);
  extern task read_addr_random();          //读地址随机
  extern task read_write_random();         //读/写都随机，即地址、数据和类型hwrite都随机
  extern task all_random();          //所有的tr数据都随机，包括hsel、hwrite等信号
  extern task no_op();            //无操作，空命令
  extern task run();			  //产生数据之后放到mailbox中去

endclass

//new方法的作用就是会把公共的外部给到的邮箱给到自己的邮箱里面，就是做一个赋值。tr_num就是传输的数目，就相当于我在初始化的时候把它赋值给自己内部的tr_num.这也是做整个仿真控制用的，发完了就结束了
//因为是在外部定义的，那么你定义的function属于哪一个类呢，就需要把类名写在前面，然后加上两个冒号 :: 在加上function本身的名字，传递的参数还是要写上
function generator::new(mailbox mbx,int tr_num);
  this.mbx = mbx;       //将外部邮箱赋给内部邮箱，使两者相连接，generator的mbx会放在公共邮箱里，等待下一级组件去取
  this.tr_num = tr_num; //不同testcase发送的tr_num激励数量不一样
endfunction

//build的作用是先产生一些随机的数，产生一些随机的transaction。testcase相当于指挥家
function generator::build();         //在运行testcase之前的准备工作
  //tr就是前面声明的transaction，把对象new一下，产生随机数,相当于实例化
  tr = new;                          //对象tr实例化，分配空间
  if(!tr.randomize())begin           //随机化transaction中的数据
    $display("@%0t ERROR::generator::build randomize failed",$time);
  end
endfunction

//发送的地址和数据是task告诉我的，相当于是指定的，而不是随机的
//写数据 tr.hrdata 没有管
task generator::write_data32(logic [31:0] addr, logic [31:0] wdata); 
  tr = new;                 //对象tr实例化分配空间
  tr.haddr  = addr;         //testcase传入地址，对数据进行地址分配地址
  tr.hsel   = 1'b1;         //选中该slave
  tr.hwrite = 1'b1;         //1'b1：表示写数据传输模式
  tr.htrans = 2'b10;        //2'b10：表示指示写传输命令有效：NONSEQ； 非burst传输类型一般只有NONSEQ有效状态，SEQ状态一般不出现
  tr.hsize  = 2'b10;        //2'b10：表示有效数据传输位为32bit
  tr.hburst = 2'b00;        //single操作，非连续传输（可省略），burst传输第一个传输类型为NONSEQ，其后为SEQ
  tr.hwdata = wdata;        //写入数据
  -> gen_data;     //触发事件，在后边run（）;的时刻，等待事件在收到触发时，就会把tr放入邮箱
endtask

//这一块讲的是我们只负责写16个数据，我怎么给你产生出数据模型里面具体的数来。我们设计这个场景的含义是什么要理解
//写数据 tr.hrdata 没有管
task generator::write_data16(logic [31:0] addr, logic [31:0] wdata);
  tr = new;                 //对象tr实例化，分配空间
  tr.haddr  = addr;         //testcase传入地址，对写数据进行地址分配地址
  tr.hsel   = 1'b1;         //选中该slave
  tr.hwrite = 1'b1;         //1'b1：表示写数据传输模式
  tr.htrans = 2'b10;        //2'b10：表示指示写传输命令有效：NONSEQ
  tr.hsize  = 2'b01;        //2'b01：表示有效数据传输位为16bit //01代表16位有效，至于是高16位有效还是低16位有效，就取决于地址
  tr.hburst = 2'b00;        //（可省略）
  tr.hwdata = wdata;        //写数据
  -> gen_data;      //触发事件，在后边run（）;的时刻，等待事件在收到触发时，就会把tr放入邮箱
endtask

//写数据 tr.hrdata 没有管
task generator::write_data8(logic [31:0] addr, logic [31:0] wdata);
  tr = new;
  tr.haddr  = addr;         //testcase传入地址，对写数据进行地址分配地址
  tr.hsel   = 1'b1;         //选中该slave
  tr.hwrite = 1'b1;         //1'b1：表示写数据传输模式
  tr.htrans = 2'b10;        //2'b10：表示指示写传输命令有效：NONSEQ
  tr.hsize  = 2'b00;        //2'b00：表示有效数据传输位为8bit
  tr.hburst = 2'b00;        
  tr.hwdata = wdata;        
  -> gen_data;
endtask

//主要是data_random,参数只输入的地址，不会输入数据，因为数据是随机的，地址可以由testcase来安排，给到的
//对tr.hwdata、tr.hburst、tr.hrdata进行了随机
task generator::write_data_random(logic [31:0] addr);
  tr = new;
  // 先对数据随机化，写的数据是32位的
  if(!tr.randomize())begin  //随机化transaction包中的数据
    $display("@%0t ERROR::generator::write_data_random randomize failed",$time);//如果随机失败就会返回这么一句话
  end
  tr.haddr  = addr;         //testcase传入地址，对随机化数据进行地址分配
  tr.hsel   = 1'b1;         //选中该slave
  tr.hwrite = 1'b1;         //1'b1：表示写数据传输模式
  tr.htrans = 2'b10;        //2'b10：表示指示写传输命令有效：NONSEQ
  tr.hsize  = 2'b10;        //2'b10：表示有效数据传输位为32bit
  -> gen_data;
endtask

//对tr.haddr、tr.hburst、tr.hrdata进行了随机
task generator::write_addr_random(logic [31:0] wdata);//写地址的随机
  tr = new;
  // 地址通过tr.randomiz产生之后不再对它重新赋值，那么它就是一个随机数了
  if(!tr.randomize())begin  //随机化transaction包中的数据
    $display("@%0t ERROR::generator::write_addr_random randomize failed",$time);
  end
  tr.hsel   = 1'b1;         //选中该slave
  tr.hwrite = 1'b1;         //1'b1：表示写数据传输模式
  tr.htrans = 2'b10;        //2'b10：表示指示写传输命令有效：NONSEQ
  tr.hsize  = 2'b10;        //2'b10：表示有效数据传输位为32bit（支持写8/16/32bit）
  tr.hwdata = wdata;        //随机写入数据
  -> gen_data;
endtask

// 读跟写比起来的话就相当于我们产生数据的时候不需要产生读数据，读数据是slave返回的(通过信号线hrdata)，我们只需要产生地址。hwdata写0也行，不写也行，所以这里就没写
// 读数据 tr.hwdata 没有管
task generator::read_data32(logic [31:0] addr);
  tr = new;
  tr.haddr  = addr;       
  tr.hsel   = 1'b1;         //选中该slave
  tr.hwrite = 1'b0;         //1'b0：表示读数据传输模式
  tr.htrans = 2'b10;        //2'b10：表示指示传输命令有效：NONSEQ
  tr.hsize  = 2'b10;        //2'b10：表示有效数据传输位为32bit
  -> gen_data;
endtask

// 读数据 tr.hwdata 没有管
task generator::read_data16(logic [31:0] addr);
  tr = new;
  tr.haddr  = addr;       
  tr.hsel   = 1'b1;         //选中该slave
  tr.hwrite = 1'b0;         //1'b0：表示读数据传输模式
  tr.htrans = 2'b10;        //2'b10：表示指示传输命令有效：NONSEQ
  tr.hsize  = 2'b01;        //2'b10：表示有效数据传输位为16bit
  -> gen_data;
endtask

// 读数据 tr.hwdata 没有管
task generator::read_data8(logic [31:0] addr);
  tr = new;
  tr.haddr  = addr;       
  tr.hsel   = 1'b1;         //选中该slave
  tr.hwrite = 1'b0;         //1'b0：表示读数据传输模式
  tr.htrans = 2'b10;        //2'b10：表示指示传输命令有效：NONSEQ
  tr.hsize  = 2'b00;        //2'b00：表示有效数据传输位为8bit
  -> gen_data;
endtask

//读地址随机，因为读不存在数据就没有参数这里的读还是按照32位去读的，hsize并没有去随机
//对tr.addr、tr.hburst、tr.hrdata、tr.hwdata进行了随机
task generator::read_addr_random();   //读数据只需要地址即可，地址随机化，故不再需要参数
  tr = new;
  if(!tr.randomize())begin  //随机化transaction包中的数据
    $display("@%0t ERROR::generator::read_addr_random randomize failed",$time);
  end
  tr.hsel   = 1'b1;         //选中该slave
  tr.hwrite = 1'b0;         //1'b0：表示读数据传输命令模式
  tr.htrans = 2'b10;        //2'b10：表示指示传输命令有效：NONSEQ
  tr.hsize  = 2'b10;        //2'b10：表示有效数据传输位为32bit（支持读8/16/32bit）
  -> gen_data;
endtask

//对tr.addr、tr.hwrite、tr.hburst、tr.hrdata、tr.hwdata进行了随机
task generator::read_write_random();  //读/写都随机，即hwrite随机；同时地址也进行了随机
  tr = new;
  if(!tr.randomize())begin  //随机化transaction包中的数据
    $display("@%0t ERROR::generator::read_write_random randomize failed",$time);
  end
  tr.hsel   = 1'b1;         //选中该slave
  tr.htrans = 2'b10;        //2'b10：表示指示传输命令有效：NONSEQ
  tr.hsize  = 2'b10;        //2'b10：表示有效数据传输位为32bit
  -> gen_data;
endtask

task generator::all_random();       //所有都随机，不再对各个信号再进行赋值
  tr = new;
  if(!tr.randomize())begin  //随机化transaction包中的数据
    $display("@%0t ERROR::generator::all_random randomize failed",$time);
  end
  -> gen_data;
endtask

task generator::no_op();            //无操作命令
  tr = new;
  if(!tr.randomize())begin  //随机化transaction包中的数据
    $display("@%0t ERROR::generator::no_op randomize failed",$time);
  end
  tr.hsel   = 'h0;         //未选中slave
  tr.htrans = 'h0;        //无效命令指示，  无效操作
  -> gen_data;
endtask

//前面产生激励的task，如果产生数据的话就会产生一个gen.data 的一个event去告诉run我已经产生data了，run就会等待，等待的次数为你发的命令的个数那么多次，每次发一个就会等待一下，如果等待你发一个包过来那么就把他放到邮箱里面去。
//就是根据给到的发包的个数循环那么多次，然后在上面的这些线程产生完一次数据之后就会把数据放到我的邮箱里面，等待我的另外一个组件去取。这个邮箱就是FIFO
task generator::run();        //前面产生激励的task，如果产生数据的话，便会同时触发事件gen_data，告诉run（）；
  repeat(tr_num)begin         //tr数据包已产生了数据，然后run会把数据包放入邮箱mbx，等待下一个组件去取。
     //等待gen_data,它是靠前面的gen_data来驱动的，前面不调用的话是不起作用的
     @(gen_data);             //testcase每发一个包命令，run（）就等待tr产生数据，然后放入邮箱
     mbx.put(tr);             //这里的邮箱就相当于一个FIFO
  end
endtask

`endif

