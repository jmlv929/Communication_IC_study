

--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of shared_fifo_mem is

  -----------------------------------------------------------------------------
  -- Component
  -----------------------------------------------------------------------------
  -- dual port memory for XILINX FPGA target
  component xilinx_dual_port_memory_128x22_rf_wr
    port(
       -- Port A : for reading
       clka   : in  std_logic;
       sinita : in  std_logic;
       ena    : in  std_logic;
       addra  : in  std_logic_vector(6 downto 0);   
       --
       douta  : out std_logic_vector(21 downto 0);
       -- Port B : for writing
       clkb   : in  std_logic;
       sinitb : in  std_logic;
       enb    : in  std_logic;
       web    : in  std_logic;
       addrb  : in  std_logic_vector(6 downto 0);   
       dinb   : in  std_logic_vector(21 downto 0)
      );
  
  end component;

  -----------------------------------------------------------------------------
  -- Type
  -----------------------------------------------------------------------------
  type   FIFO_TYPE_T is array(0 to depth_g - 1) of 
                      std_logic_vector(datawidth_g - 1 downto 0);

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  signal fifo_array    : FIFO_TYPE_T ;
  signal d_fifo_array  : FIFO_TYPE_T ;
  signal rd_ptr1_int   : std_logic_vector(addrsize_g downto 0);
  signal rd_ptr2_int   : std_logic_vector(addrsize_g downto 0);
  signal wr_ptr_int    : std_logic_vector(addrsize_g downto 0);
  signal data2write    : std_logic_vector(datawidth_g - 1 downto 0);

  -- For xilinx
  signal write_enable  : std_logic; 
  signal enable        : std_logic;
  
begin 
  
  enable <= '1';

  --------------------------------------------
  -- Reading pointer
  --------------------------------------------
  read_pointer : process( ffe2_read_ptr_i, ffe_read_i, init_sync_read_i,
                          init_sync_read_ptr1_i)

  begin
    rd_ptr2_int <= (others => '0');
    if (init_sync_read_i = '1') then    -- time domain
      rd_ptr2_int <= init_sync_read_ptr1_i;
    elsif ffe_read_i = '1' then         -- fine frequency estim
      rd_ptr2_int <= ffe2_read_ptr_i;
    end if;
  end process read_pointer;

  rd_ptr1_int <= ffe1_read_ptr_i;

  --------------------------------------------
  -- Writing pointer
  --------------------------------------------
  write_pointer : process( ffe_wdata_i, ffe_write_i, ffe_write_ptr_i,
                           init_sync_wdata_i, init_sync_write_i,
                           init_sync_write_ptr_i)
  begin
    wr_ptr_int <= (others => '0');
    data2write <= (others => '0');
    if ( init_sync_write_i = '1' ) then     -- time domain
      wr_ptr_int <= init_sync_write_ptr_i;
      data2write <= init_sync_wdata_i;
    elsif ( ffe_write_i = '1' ) then        -- fine frequency estimation
      wr_ptr_int <= ffe_write_ptr_i;
      data2write <= ffe_wdata_i;
    end if;
  end process write_pointer;

  
  --------------------------------------------
  -- XILINX FPGA target :
  --------------------------------------------
  XILINX_g : if (TARGET_SUPPLIER_CT = XILINX) generate
   
   
    --------------------------------------------
    -- XILINX memory instanciation
    --------------------------------------------
    xilinx_dual_port_memory_128x22_rf_wr_1 : xilinx_dual_port_memory_128x22_rf_wr
      port map (
        -- Port A : for reading
        clka   => clk,
        sinita => reset_n,
        ena    => enable,
        addra  => rd_ptr1_int,
        --
        douta  => fifo_mem_data1_o,
        -- Port B : for writing
        clkb   => clk,
        sinitb => reset_n,
        enb    => enable,
        web    => write_enable,
        addrb  => wr_ptr_int,
        dinb   => data2write
      );

    --------------------------------------------
    -- XILINX memory instanciation
    --------------------------------------------
    xilinx_dual_port_memory_128x22_rf_wr_2 : xilinx_dual_port_memory_128x22_rf_wr
      port map (
        -- Port A : for reading
        clka   => clk,
        sinita => reset_n,
        ena    => enable,
        addra  => rd_ptr2_int,
        --
        douta  => fifo_mem_data2_o,
        -- Port B : for writing
        clkb   => clk,
        sinitb => reset_n,
        enb    => enable,
        web    => write_enable,
        addrb  => wr_ptr_int,
        dinb   => data2write
      );   

    -- Write enable
    write_enable <= init_sync_write_i or ffe_write_i;
      
  end generate XILINX_g;
  

  --------------------------------------------
  -- ASIC target
  --------------------------------------------
  SYNTHESIS_g : if (TARGET_SUPPLIER_CT /= XILINX) generate

    --------------------------------------------
    -- FIFO read
    --------------------------------------------
    fifo_mem_data1_o <= fifo_array(conv_integer(rd_ptr1_int));
    fifo_mem_data2_o <= fifo_array(conv_integer(rd_ptr2_int));

    --------------------------------------------
    -- Sequencial FIFO
    --------------------------------------------
    write_fifo_p: process( clk, reset_n)
      variable i : integer;
    begin
      if (reset_n = '0') then
        fifo_array <= (others => (others => '0'));
      elsif (clk'event and clk = '1') then
        if init_sync_write_i = '1' or ffe_write_i = '1' then
            fifo_array(conv_integer(wr_ptr_int)) <= data2write;
        end if;    
      end if;
    end process write_fifo_p;

  end generate SYNTHESIS_g;

end rtl;
