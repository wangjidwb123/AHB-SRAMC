`ifndef AHB_SRAM_TEST_SV
`define AHB_SRAM_TEST_SV

//只有在program里面才会去仿真，通过再上一层top把interface传进来
program ahb_sram_test(ahb_slv_if slv_if);        //创建接口对象
  int    tr_num=20;         //创建数据包变量，默认值为20
  int    rnd_seed;          //该随机种子变量在此作用不大，可以省略
  // tc_num代表用的测试用例的哪一个,我们会对测试用例进行一个编号，从而决定用哪一个
  int    tc_num;          //定义测试用例号，运行测试用例时对用例进行指定
  
  //Testcase里面调用environment，因此testcase是在environment的更上一层。
  class tc_base;              //定义基础测试用例testcase，其他用例可在此基础上进行扩展
      int           tr_num;   //设置发包数量
      environment   ahb_env;  //声明环境句柄
      virtual  ahb_slv_if  slv_if;  //例化接口 Interface，更上一层传过来的
       
      extern function new(virtual ahb_slv_if slv_if, int tr_num);
      extern function build();
      extern virtual task run();    //声明virtual run（），是为了实现多态
  endclass
   
  function tc_base::new(virtual ahb_slv_if slv_if, int tr_num);
	//这个new是把顶层给过来的slv_if传到本地的slv_if,后面再给到environment来
    this.slv_if = slv_if;      //通过接口实现testcase与environment之间的连接
    this.tr_num = tr_num;
  endfunction

  //build阶段对env进行实例化，把tr_num传给它，同时调用env的build
  function tc_base::build();
    ahb_env = new(this.slv_if,tr_num);      //将本地slv_if传递给environment，建立连接
    ahb_env.build();                      //通过邮箱和接口，将env中的各个子组件连接，打通数据通道。
  endfunction
   
  task tc_base::run(); //把env的run 运行起来
    ahb_env.run;      
  endtask

  // 第0个testcase，它是从tc_base继承过来的，因此tc_base定义的成员就不用再重复定义了
  // 这也是继承的优势，直接定义它的new函数和run,当他run起来的时候就可以产生一些自己的行为，注意没有build函数
  // tc000因为是继承的，所以 ahb_env.gen.write_data32 才可以直接调用
  class tc000 extends tc_base;        //继承基类测试用例——用例1
      extern function new(virtual ahb_slv_if slv_if, int tr_num);
      extern task run();    
  endclass    
   
  function tc000::new(virtual ahb_slv_if slv_if, int tr_num);
    super.new(slv_if,tr_num);       //通过super关键字，引用基类中的new函数，建立组件之间的连接
  endfunction
   
  task tc000::run();
    fork
	  //env run起来的同时，调用gen的各种场景，产生不同的数据，这是根据自己的规划来做
      ahb_env.run;     
      begin   //在run的同时（并发），调用generator的各种场景，产生不同的数据，形成不同的用例
		//总共发的包有tr_num个，然后一半以32的数据类型写，写的地址是048c ，i*4是地址，i是data
        for(int i=0;i<(tr_num/2);i++)begin
          #1;                         //时间间隔的设置是为了避免event事件触发不会与@等待相冲突
		  // 参数是地址和数据 
          ahb_env.gen.write_data32(i*4,i);  
        end
        for(int i=0;i<(tr_num/2);i++)begin        
          #1; 
          ahb_env.gen.read_data32(i*4);    
        end
      end
    join
  endtask  

  //用一套验证环境，跑不同的用例，就产生不同的激励了，形成不同的testcase
  class tc001 extends tc_base;        //继承基类测试用例——用例2
      extern function new(virtual ahb_slv_if slv_if, int tr_num);
      extern task run();    
  endclass    
   
  function tc001::new(virtual ahb_slv_if slv_if, int tr_num);
    super.new(slv_if,tr_num);       //通过super关键字，引用基类中的new函数，建立组件之间的连接
  endfunction
   
  task tc001::run();
    fork
      ahb_env.run;
      begin   //在run的同时（并发），调用generator的各种场景，产生不同的数据，形成不同的用例
        for(int i=0;i<(tr_num/2);i++)begin
          #1;                         //时间间隔的设置是为了避免event事件触发不会与@等待相冲突
          ahb_env.gen.write_data32(i*4, 32'h5A5A_5A5A);    //发的数据是5A5A_5A5A
        end
        for(int i=0;i<(tr_num/2);i++)begin        
          #1;  //过了一个时钟周期后再发送这个数据 
          ahb_env.gen.read_data32(i*4);    
        end
      end
    join
  endtask  

  class tc002 extends tc_base;        //继承基类测试用例——用例3
      extern function new(virtual ahb_slv_if slv_if, int tr_num);
      extern task run();    
  endclass    
   
  function tc002::new(virtual ahb_slv_if slv_if, int tr_num);
    super.new(slv_if,tr_num);       
  endfunction
   
  task tc002::run();
    fork
      ahb_env.run; 
      begin   //在run的同时（并发），调用generator的各种场景，产生不同的数据，形成不同的用例
        for(int i=0;i<(tr_num/2);i++)begin
          #1;                         
          ahb_env.gen.read_write_random();    //产生随机的激励
        end
        for(int i=0;i<(tr_num/2);i++)begin        
          #1;  
          ahb_env.gen.read_data32(i*4); // 读出来
        end
      end
    join
  endtask  

//下面对三个测试用例进行实例化，虽然一次只能跑一个，但是都实例化在这里，下面再做选择，声明tc的句柄
tc000     tc0;       //声明测试用例类句柄
tc001     tc1;
tc002     tc2;

// Get arguments from external scripts
initial begin
  //DP波形，调试的时候还是需要看波形，看看发的激励和想要发的是不是一致
  // VCD(Value Change Dump)文件Synopsys公司 VCS DVE支持的波形文件，可以用$vcdpluson产生。
  $vcdpluson();      //生成波形文件
  // 这个是从makefile脚本里面获取 tc_num 参数，以前做vtb到时候讲过
  // tc_num，我们可以通过外面的脚本来决定这次run脚本的时候是跑tc0呢，还是tc1，tc2。如果脚本不给的或者获取失败我们就取0
  if(!$value$plusargs("tc_num=%d",tc_num))begin
    tc_num = 0;
  end
  else begin
    $display("***@%0t::tc_num is : %0d",$time,tc_num); // 获取成功我们会把tc_num打印一下，就可以在屏幕上看到跑的是哪一个num
  end
  
  // 这三行是把所有的测试用例进行初始化，相当于实例化，把slv_if给到它，后面的12，200，100就是产生的tr_num，new函数在上面的话实际上有两个参数slv_if和tr_num

  tc0 = new(slv_if,12);     //传递接口和发包数量
  tc1 = new(slv_if,200);    
  tc2 = new(slv_if,100);

  // 根据给到的tc_num每次只会run一个，如果等于0就run0，等于1就run1 
  // new的话已经执行了，每一个tc的class里面只有三个method，new,build,run，后面两个在这里执行起来，串行的关系
  if(tc_num == 0)begin
    tc0.build();
    tc0.run();
  end
  else if(tc_num == 1)begin
    tc1.build();
    tc1.run();
  end
  else if(tc_num == 2)begin
    tc2.build();
    tc2.run();
  end
  else begin
    $display("@%0t : ERROR tc_num(%0d) does not exist",$time,tc_num);
  end
end

endprogram

`endif

