#### control[7:0]  
control[7:5] 片选 8个设备
CPOL = control[3]
CPHA = control[4]
divide_factor = control[2:0]  

#### slave_cs 片选有效信号 低电平有效

#### clk_divide[7:0]    
negedge pro_clk
计数器 对pro_clk计数

#### spi_clk_gen  

spi时钟 与pro_clk时钟成倍数关系 通过divide_factor控制

#### sclk  
posedge spi_clk_gen
the SPI clock
周期是spi_clk_gen的两倍

#### spi_word_send   
posedge pro_clk
send a new spi word
CS & WR & addr[1] & ~addr[0]情况下 有效

#### addr[1:0]  
2'b10 向从机写
2'b00 控制有效 写入控制spi主机的control
2'b01 查看内部 status
2'b11 向从机读

#### shift_register  
移位寄存器
CPHA CPOL 00 || 11 上升沿采样
CPHA CPOL 01 || 10 下降沿采样

#### mosi   
CPHA CPOL 00 || 11 下降沿输出
CPHA CPOL 01 || 10 上升沿输出
输出移位寄存器最高位

#### slave_cs 低电平有效  
pro_clk 域下

spi_word_send 为1  slave_cs有效
count == 8计数完成 且 sclk 与 CPOL一致 slave_cs无效 

#### count  
Counting SPI word length

#### data_out[7:0]  

addr为2'b11 : if (RD) data_out <= rxdata