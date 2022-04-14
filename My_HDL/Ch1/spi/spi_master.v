module spi_master(
    pro_clk,
    sclk,
    miso,
    mosi,
    ss,
    data_bus,
    WR,
    RD,
    addr,
    CS
);
// port
input pro_clk;
inout[7:0] data_bus;
output reg sclk;
output reg mosi;
input miso;
output[7:0] ss;  //8个从设备
input WR;
input RD;
input[1:0] addr;
input CS;

//reg

reg[7:0] clk_divide;
reg[7:0] control;   // [2:0] control the factor
wire[2:0] factor;

reg[7:0] data_in;
reg[7:0] data_out;  //the tri state port

reg[7:0] status;

reg[7:0] shift_reg; 

reg[7:0] tx_data;
reg[7:0] rx_data;  //发送与接收buffer

reg spi_send_data_flag;  //关键信号1 检测控制状态
wire CPOL;
wire CPHA;

reg slave_cs;         //关键信号2 spi起始与结束传输信号
reg[3:0] count; //接收到的数据数量
//logic

          // 三态门
assign data_bus = RD ? data_out : 8'bz; 

always@(*) begin
    data_in = data_bus;
end

assign ss[0] = ~(!control[7] & !control[6] & !control[5] & (~slave_cs));
assign ss[1] = ~(!control[7] & !control[6] & control[5] & (~slave_cs));
assign ss[2] = ~(!control[7] & control[6] & !control[5] & (~slave_cs));
assign ss[3] = ~(!control[7] & control[6] & control[5] & (~slave_cs));
assign ss[4] = ~(control[7] & !control[6] & !control[5] & (~slave_cs));
assign ss[5] = ~(control[7] & !control[6] & control[5] & (~slave_cs));
assign ss[6] = ~(control[7] & control[6] & !control[5] & (~slave_cs));
assign ss[7] = ~(control[7] & control[6] & control[5] & (~slave_cs));

//mode设置
assign CPOL = control[3];
assign CPHA = control[4];

assign spi_clk_gen = clk_divide[factor];  // 计数器 对pro_clk进行分频 最大计数256
assign factor = control[2:0];

always@(negedge pro_clk) begin
    clk_divide <= clk_divide + 1'b1;     //没有赋初始值 clk_divide为 x 之后也一直为x 
end

always@(posedge pro_clk) begin  //发送信号 同步于pro_clk时钟  一个pro_clk周期 
    if(WR && CS && addr == 2'b10) begin   //片选信号  向从机写
        spi_send_data_flag <= 1'b1;
    end
    else begin
        spi_send_data_flag <= 1'b0;
    end
end


always@(posedge pro_clk) begin
    if(spi_send_data_flag)   //slave_cs相对于spi_send_data_flag延迟一个时钟
        slave_cs <= 1'b0;  // 为了使mosi足够时间输出移位寄存器的最高位
    else if(count == 8 && ~(sclk ^ CPOL) )   //只有count为8 这个条件 不靠谱 因为count是循环的 所以还有其他条件
        slave_cs <= 1'b1;    //还必须 时钟处于空闲状态
end

always@(posedge pro_clk) begin  //配置control寄存器
    if(CS) begin
        case(addr)
            2'b00: 
            if(WR)
                control <= data_in;  //写入控制器
            2'b01: 
            if(RD)
                data_out <= status;   //读取status寄存器
            2'b10: 
            if(WR)
                tx_data <= data_in; // 将data_bus上的信号采样进入发送buffer
            2'b11:
            if(RD) 
                data_out <= rx_data;  //接收buffer中的数据传给data_bus
        endcase
    end
end

always@(posedge spi_clk_gen) begin      //spi 时钟输出
    if(!slave_cs)                     //片选有效才有 spi时钟输出
        sclk <= ~sclk;
    else if(CPOL)
        sclk <= 1'b1;
    else
        sclk <= 1'b0;
end


//data 采样  片选有效直接装载移位寄存器
always@(posedge(sclk^(CPOL^CPHA)) or posedge spi_send_data_flag) begin  //(sclk^(CPOL^CPHA))太巧妙了
    if(spi_send_data_flag)
        shift_reg <= tx_data;
    else begin
        shift_reg = shift_reg << 1;    //在一个begin end里面同时赋值 允许 下面的是对上面的修改
        shift_reg[0] <= miso;
    end
end

//data 输出

always@(negedge(sclk^(CPOL^CPHA)) or posedge spi_send_data_flag) begin
    if(spi_send_data_flag)
        mosi <= tx_data[7];  // 片选有效直接输出tx_data的值
    else 
        mosi <= shift_reg[7];
end

//对整个spi传输数据进行计数
always@(negedge(sclk^(CPOL^CPHA)) or posedge slave_cs) begin  //数据输出完成 计数完成
    if(slave_cs)   //初始状况下 slave_cs 为 x造成未知
        count <= 0;
    else
        count <= count + 1'b1;
end

//状态寄存器

always@(posedge spi_send_data_flag or posedge slave_cs) begin
    if(spi_send_data_flag)
        status[0] <= 0;
    else begin
        status <= 8'h01;
        rx_data <= shift_reg;
    end
end


initial begin     //赋值 否则可能会对一些状态造成影响
    clk_divide = 0;
    count = 0;
    slave_cs = 1;
    data_out = 0;
    rx_data = 0;
    shift_reg = 0;
    tx_data = 0;
end

endmodule