all: compile simulate dve_wave log open dve_cov

# rnd_seed相当于我们产生的随机的种子，通过时间data的变化，随机种子就在变化
rnd_seed = $(shell data+%s) # rnd意思是随机数 

tc_num = 0 # 产生tc_num 默认是testcase0，后面可以通过终端赋值改变

compile: # 我们run这个脚本是在sim下面run的，所以文件的位置就是和sim的相对关系
	vcs -full64 -l comp.log -sverilog -f rtl.f -debug_pp -timescale=1ns/1ns \ # 一定要把rtl.f文件拷贝到sim目录下面来
		-cm line+cond+fsm+tgl \ 
		../tb/ahb_slv_if.sv \ # 各个文件的编译顺序是依次进行的，写的顺序也是这样的
		../env/transaction.sv \
		../env/generator/generator.sv \
		../env/agent/agent.sv \
		../env/driver/driver.sv \
		../env/environment.sv \
		../tests/ahb_sram_test.sv \
		../tb/ahb_sramc_svtb_top.sv

simulate: # 生成一个./simv的文件之后就会simulate，然后不同的种子产生不同的log.  +plusargs_save表示上面定义的rnd_seed 和 tc_num 可以传递到后面的代码里面去
	./simv -l sim_$(tc_num).log +plusargs_save \ 
		+ntb_random_seed=$(rnd_seed) \
		+tc_num=$(tc_num)

dve_wave: # 通过dve_wave看看testcase产生的激励是不是和我们预期相吻合
	dve -vpd vcdplus.vpd&

dve_cov: # cov先不用管，这个是后面做coverage加的
	dve -full64 -covdir simv.vdb&

log:
	sed '/^[^*].*/d' sim_$(tc_num).log > rslt.log

open:
	gvim rslt.log

clean:
	dve_covrm _rf work mti_lib transcript modelsim.ini *.log *.wlf test.ucdb  

