

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of master_seria is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  -- Number of cycle between 2 data (depend on the Mb/s)
  constant RD_REG_SHIFT_CT : std_logic_vector(4 downto 0) := "00100";  -- 3+1 (x2 (i/q)) 
  constant WR_REG_SHIFT_CT : std_logic_vector(4 downto 0) := "01100";  -- 11+1 (x2 (i/q)) 
  constant A_SHIFT_CT      : std_logic_vector(4 downto 0) := "01011";  -- 12-1 
  constant B1_SHIFT_CT     : std_logic_vector(4 downto 0) := "10101";  -- 22-1 
  constant B2_SHIFT_CT     : std_logic_vector(4 downto 0) := "10011";  -- 20-1
  -- Adjustment
  constant B1_ADJUST_CT    : std_logic_vector(3 downto 0) := "1001";  -- 10-1 
  constant B2_ADJUST_CT    : std_logic_vector(3 downto 0) := "0000";  -- 1-1
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Count the number of shift to perform                                                        
  -- Special Counter for 11 MHz samples (10 x count 22  - shift 2
  --                                      1 x count 20  - shift 2)
  signal shift_counter     : std_logic_vector(4 downto 0);
  signal alternate_mode    : std_logic;
  signal adjust_counter    : std_logic_vector(3 downto 0); 
  --
  -- Shift Registers (size of add + data = 11bits)
  signal seria_i_reg       : std_logic_vector(11 downto 0);
  signal seria_q_reg       : std_logic_vector(11 downto 0);
  -- Request a new data to the buffer_for_seria
  signal next_data_req_tog : std_logic;
  -- Indication to sm
  signal seria_valid       : std_logic;
  signal not_seria_valid   : std_logic;
  -- Parity bit
  signal parity_i_bit      : std_logic;
  signal parity_q_bit      : std_logic;
  -- memorize a reg access
  signal reg_access        : std_logic;

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -----------------------------------------------------------------------------
  -- Shift Register
  -----------------------------------------------------------------------------
  -- The same register is used for all the serializations (from tx_filter or
  -- from reg )
  seria_p: process (hiss_clk, reset_n)
  begin  -- process seria_p
    if reset_n = '0' then               
      seria_i_reg       <= (others => '0');
      seria_q_reg       <= (others => '0');
      next_data_req_tog <= '0';
      reg_access        <= '0';
    elsif hiss_clk'event and hiss_clk = '1' then
      -------------------------------------------------------------------------
      -- Data from 60 MHz clock Domain
      -------------------------------------------------------------------------
      -------------------------------
      -- Storing data of tx_paths
      --------------------------------
      if transmit_possible_i = '1'  and shift_counter = "00000" then
        -- Data from Tx_Filter (via buffer_for_seria) available - driver enabled
        seria_i_reg       <= bufi_i;   --  data is on LSB (MSB can possess clk skip or other info)
        seria_q_reg       <= bufq_i;
        next_data_req_tog <= not next_data_req_tog; -- ask to prepare the next data
        reg_access        <= '0';
      end if;

      -------------------------------------------------------------------------
      -- Data from 240 MHz clock Domain
      -------------------------------------------------------------------------
      -------------------------------
      -- Storing data for apb_access
      --------------------------------
      if rd_reg_pulse_i = '1' or wr_reg_pulse_i = '1' then  -- add will always have the same place
        -- Data from Registers available (LSB is sent first)
        --          _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ ____
        -- rf_txi  X_a0__X_a1__X_a2__X_d0__X_d1__X_d2__X_d3__X_d4__X_d5__X_d6__X_d7_
        --          _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ ____
        -- rf_txq  X_a3__X_a4__X_a5__X_d8__X_d9__X_d10_X_d11_X_d12_X_d13_X_d14_X_d15
        --
        seria_i_reg <= '0' & wrdata_i(7 downto 0)  & add_i(2 downto 0);
        seria_q_reg <= '0' & wrdata_i(15 downto 8) & add_i(5 downto 3);
        reg_access  <= '1'; -- memorize that it is a reg access

      elsif shift_counter /= "00000" and
        not (transmit_possible_i = '1' and tx_abmode_i = '1') then
        -------------------------------------------------------------------------
        -- Right Shifting (no right shift on b transmission) 
        -------------------------------------------------------------------------
        seria_i_reg(seria_i_reg'high-1 downto 0) <= seria_i_reg(seria_i_reg'high downto 1);
        seria_q_reg(seria_q_reg'high-1 downto 0) <= seria_q_reg(seria_q_reg'high downto 1);
      end if;
    end if;
  end process seria_p;

  -- Output Linking : LSB first - Send parity bit when register access (we are
  -- not in transmission mode).
  reg_or_i_o <= parity_i_bit when (shift_counter = "00001"  and reg_access = '1')
          else seria_i_reg(0);
  reg_or_q_o <= parity_q_bit when (shift_counter = "00001"  and reg_access = '1')
          else seria_q_reg(0);
  next_data_req_tog_o <= next_data_req_tog;

  -----------------------------------------------------------------------------
  -- Serialization Counter
  -----------------------------------------------------------------------------
  -- When a data arrives, store the nb o shift to perform 
  seria_count_p : process (hiss_clk, reset_n)
  begin  -- process seria_count_p
    if reset_n = '0' then              
      shift_counter       <= (others => '0');
    elsif hiss_clk'event and hiss_clk = '1' then  
      
      if transmit_possible_i = '1'  and shift_counter = "00000"  and trans_enable_i = '1' then
        -- Time to refill the nb of shifts
        if tx_abmode_i = '0' then
          -- 11 bits of Data A to transfer + 1 with no data
          shift_counter     <= A_SHIFT_CT;
        else
          -- 1 bits of Data B to transfer + 19 or 21 with no data  
          if alternate_mode = '0' then
            shift_counter     <= B1_SHIFT_CT;
          else
            shift_counter     <= B2_SHIFT_CT;
          end if;
        end if;
      end if;

      if wr_reg_pulse_i = '1' then
        -- 8x2 Data from Registers to transfer
        shift_counter <= WR_REG_SHIFT_CT;

      elsif rd_reg_pulse_i = '1' then
        -- 8x2 Data from Registers to transfer
        shift_counter <= RD_REG_SHIFT_CT;

      elsif shift_counter /= "00000" then
        -- decrement counter
        shift_counter <= shift_counter - '1';
      end if;
    end if;
  end process seria_count_p;

  -----------------------------------------------------------------------------
  -- Generate Parity bits
  -----------------------------------------------------------------------------
  -- For avoiding wrong info sent to the radio, a parity bit is sent after
  -- write and read access.
  --------------------------------
  -- Generate Parity bit for I
  --------------------------------            
  serial_parity_gen_1: serial_parity_gen
    generic map (
      reset_val_g => 1)
    port map (
      clk             => hiss_clk,
      reset_n         => reset_n,
      data_i          => seria_i_reg(0),
      init_i          => not_seria_valid,
      data_valid_i    => seria_valid,
      parity_bit_o    => open,
      parity_bit_ff_o => parity_i_bit);
  
  --------------------------------
  -- Generate Parity bits for Q
  --------------------------------            
  serial_parity_gen_2: serial_parity_gen
    generic map (
      reset_val_g => 1)
    port map (
      clk          => hiss_clk,
      reset_n      => reset_n,
      data_i       => seria_q_reg(0),
      init_i       => not_seria_valid,
      data_valid_i => seria_valid,
      parity_bit_o => open,
      parity_bit_ff_o => parity_q_bit);
  
  -----------------------------------------------------------------------------
  -- Seria Valid generation
  -----------------------------------------------------------------------------
  -- seria_valid is high when data are transmitted, and goes low at the end. It
  -- is used to set the rf_en of the sm.
  -- At the end of the packet, the rf_en should remains high during all the
  -- shift_counter, even if all data are transmitted.
  seria_v_p : process (hiss_clk, reset_n)
  begin  -- process seria_v_p
    if reset_n = '0' then              
      seria_valid <= '0';
    elsif hiss_clk'event and hiss_clk = '1' then  
      seria_valid <= '0';
      if trans_enable_i = '0' and shift_counter /= "00000" and reg_access = '0'
        and txv_immstop_i = '1' then
          -- txv_immstop feature: reinit parity generator when
          -- end of transmission but last sample not fully transmitted
          -- to avoid polluting parity of the next access
          seria_valid <= '0';
          
      elsif reg_access = '0' and shift_counter /= "00000" and txv_immstop_i = '0' then
        -- data (not from registers) are transmitted
          seria_valid <= '1';
        
      elsif shift_counter > "00001" or  wr_reg_pulse_i = '1' or rd_reg_pulse_i = '1' then 
        -- data from registers are transmitted
        seria_valid <= '1';
      end if;
    end if;
  end process seria_v_p;
 
  seria_valid_o   <= seria_valid;
  not_seria_valid <= not seria_valid;
    
  -----------------------------------------------------------------------------
  -- Adjust Counter
  -----------------------------------------------------------------------------
  adjust_count_p : process (hiss_clk, reset_n)
  begin  -- process adjust_count_p
    if reset_n = '0' then
      alternate_mode <= '0';
      adjust_counter <= B1_ADJUST_CT; -- start with the longest
    elsif hiss_clk'event and hiss_clk = '1' then
      if trans_enable_i = '1' then
        if tx_abmode_i = '1' then
          -- B Mode
          if shift_counter = "00001" and transmit_possible_i = '1' then
            -- there are still data to transfer
            -- watch for change in advance (cycle_counter = 1) 
            if adjust_counter = "0000" then
              alternate_mode <= not alternate_mode;
              -- Reinit Counter
              if alternate_mode = '0' then
                adjust_counter <= B2_ADJUST_CT;
              else
                adjust_counter <= B1_ADJUST_CT; 
              end if;
            else
              -- decrement counter
              adjust_counter <= adjust_counter - '1';
            end if;
          end if;
        end if;

      else
        -- reset counter for next time / start with the longest 
        adjust_counter <= B1_ADJUST_CT;
        alternate_mode <= '0';
                              
      end if;
    end if;
  end process adjust_count_p;
  
  

end RTL;
