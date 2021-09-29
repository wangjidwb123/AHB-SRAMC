`ifndef TRANSACTION_SV
`define TRANSACTION_SV

class transaction;                  //对数据激励进行建模，以便产生随机化数据包
	rand bit  [31:0]  haddr;
	rand bit          hsel;           //需要注意，并不是将所有接口interface中的信号都放在数据包transaction中发出，
	rand bit  [1:0]   htrans;         //因为有些信号是固定接死的（如hready_resp=1‘b1，常高接死），并没有必要去采集，看他们的覆盖率，
	rand bit  [1:0]   hsize;          //或者发送出去做一些随机化处理。
	rand bit          hwrite;
	rand bit  [2:0]   hburst;         //常用于随机化的数据：地址信号、控制信号、读写数据信号、hsel选择信号等。
	rand bit  [31:0]  hwdata;         //一般在发送非定向用例时，便会随机化这些信号。
	rand bit  [31:0]  hrdata;	      //hrdata通常我们从SRAM（DUT）读出来，而不是随机产生，我们定义了rand并不说一定是随机的，仍然可以定义为确定的值

	constraint c1{
				   haddr inside {[32'h0:32'h0000_FFFF]};//系统内存：64KByte；sram内存：16K*32bit，二者内存大小一样，但编址方式不同
	}      												//这里的地址是系统地址64K=2^16, 地址深度：2^16,地址位宽16（15~0），最大二进制写法表示如下，再变化为十六进制写法
													    //32'b0:32'b0000_0000_0000_0000_1111_1111_1111_1111 = 32'h0:32'h0000_FFFF
endclass

`endif

