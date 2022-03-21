
--------------------------------------------
-- Architecture
--------------------------------------------
architecture rtl of rx_mac_if is

  -- bit counter
  signal counter        : std_logic_vector(2 downto 0);
  signal d_counter      : std_logic_vector(2 downto 0);

  -- shift register
  signal shift_data     : std_logic_vector(7 downto 0);

  -- data availability indication
  signal rx_data_ind      : std_logic;
  signal rx_data_ind_s_o  : std_logic;
  signal d_rx_data_ind    : std_logic;

begin

  -- register that stores the value of the output "byte-ready" (control path)
  -- reset_n resets asynchronously the register.
  -- packet_end_i resets synchronously the register after rx_start_end_ind low,
  -- to avoid data to be taken into account two times by the bup.
  byte_ctrl_reg_p: process (clk, reset_n)
  begin 
    if reset_n = '0' then
      rx_data_ind     <= '0';
      rx_data_ind_s_o <= '0';
    elsif clk'event and clk = '1' then
      if packet_end_i = '1' then
        rx_data_ind     <= '0';
        rx_data_ind_s_o <= '0';
      else
        rx_data_ind     <= d_rx_data_ind;
        rx_data_ind_s_o <= rx_data_ind;
      end if;
    end if;
  end process byte_ctrl_reg_p;

  -- "byte-ready" combinational logic
  -- if the data-in is valid and counter reachs 000, 
  -- the indicator for "byte-ready" is set.
  -- Thus, a new byte is ready when 8 valid bits have been received.
  byte_ctrl_comb: process (counter, data_valid_i, rx_data_ind)
  begin
    -- default values
    d_rx_data_ind <= rx_data_ind;
    if counter = "000" and data_valid_i = '1' then
      d_rx_data_ind <= not(rx_data_ind);
    end if;
  end process byte_ctrl_comb;
 

  -- Shift-register (data path) : we shift-in the data-in 
  -- if this data-in is valid.
  -- reset_n resets asynchronously the register.
  shift_reg_p: process (clk, reset_n)
  begin 
    if reset_n = '0' then
      shift_data <= (others => '0');
    elsif clk'event and clk = '1' then
      if data_valid_i = '1' then
        shift_data(6 downto 0) <= shift_data(7 downto 1); 
        shift_data(7)          <= data_i;
      end if;
    end if;
  end process shift_reg_p;
  
  
  -- Decounter combinational logic
  -- if the data-in is valid, the counter is decremented
  counter_ctrl_p: process (counter, data_valid_i)
  begin
    -- default values
    d_counter <= counter;
    if data_valid_i = '1' then
      d_counter <= counter - '1';
    end if;
  end process counter_ctrl_p;

  -- register that stores the value of the counter (control path)
  -- reset_n resets asynchronously the register.
  -- sync_reset_n resets asynchronously the register.
  counter_reg_p: process (clk, reset_n)
  begin  
    if reset_n = '0' then
      counter <= (others => '1');
    elsif clk'event and clk = '1' then
      if sync_reset_n = '0' or start_of_burst_i = '1' then
        counter <= (others => '1');
      else
        counter <= d_counter;
      end if;
    end if;
  end process counter_reg_p;


  data_ready_o  <= '1';
  rx_data_ind_o <= rx_data_ind_s_o;
  
  data_resync_p: process (clk, reset_n)
  begin 
    if reset_n = '0' then
      rx_data_o       <= (others => '0');
    elsif clk'event and clk = '1' then
      if rx_data_ind_s_o /= rx_data_ind then
        rx_data_o     <= shift_data;
      end if;
    end if;
  end process data_resync_p;

end rtl;
