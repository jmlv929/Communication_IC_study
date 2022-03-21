

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of channel_decoder_control is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type CONTROL_STATE_T is (IDLE,
                           SIGNAL_START,
                           SIGNAL_DECODE,
                           DATA_START,
                           DATA_DECODE);

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  -- length limit enhance disable
  constant MIN_LENGTH_DECODE_CT     : std_logic_vector(11 downto 0) := "000000000001";
  constant MAX_LENGTH_DECODE_CT     : std_logic_vector(11 downto 0) := "111111111111";
  -- length limit enhance enable
  constant MIN_LENGTH_DECODE_CHK_CT : std_logic_vector(11 downto 0) := "000000001110";

  constant QAM_MODE_SIGNAL_CT      : std_logic_vector(1 downto 0) := "11";
  constant PUN_MODE_SIGNAL_CT      : std_logic_vector(1 downto 0) := "00";
  constant SMU_PARTITION_SIGNAL_CT : std_logic_vector(1 downto 0) := "00";
  constant FIELD_LENGTH_SIGNAL_CT  : FIELD_LENGTH_T := SIGNAL_FIELD_LENGTH_CT +
                                                    TAIL_BITS_CT;

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal control_curr_state : CONTROL_STATE_T;
  signal control_next_state : CONTROL_STATE_T;
  
  signal qam_mode_data      : std_logic_vector(1 downto 0);
  signal pun_mode_data      : std_logic_vector(1 downto 0);
  signal smu_partition_data : std_logic_vector(1 downto 0);
  signal field_length_data  : FIELD_LENGTH_T;

  signal parity             : std_logic;
  signal parity_error       : std_logic;
  signal unsupported_rate   : std_logic;
  signal unsupported_length : std_logic;
  signal min_length_decode  : std_logic_vector(11 downto 0);
  signal max_length_decode  : std_logic_vector(11 downto 0);

  ------------------------------------------------------------------------------
  -- Functions
  ------------------------------------------------------------------------------
  function even_parity (arg: std_logic_vector) return std_logic is
    variable r : std_logic;
  begin
    r := '0';
    for i in arg'range loop
      r := r xor arg(i);
    end loop;
    return r;
  end even_parity;
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin


  --------------------------------------
  -- Field sequential process
  --------------------------------------
  field_sequential_p : process (clk, reset_n)
  begin
    if reset_n = '0' then              -- asynchronous reset (active low)
      control_curr_state <= IDLE;
    elsif clk = '1' and clk'event then -- rising clock edge
      if sync_reset_n = '0' then       --  synchronous reset (active low)
        control_curr_state <= IDLE;
      elsif enable_i = '1' then        --  enable condition (active high)
        control_curr_state <= control_next_state;
      end if;
    end if;
  end process field_sequential_p;


  --------------------------------------
  -- Field combinational process
  --------------------------------------
  field_combinational_p : process(control_curr_state, enable_i,
                                  start_of_burst_i, signal_field_valid_i,
                                  end_of_data_i, parity_error,
                                  unsupported_rate, data_ready_deintpun_i,
                                  unsupported_length)
  begin
    enable_deintpun_o    <= '0';
    enable_viterbi_o     <= '0';
    enable_signal_o      <= '0';
    enable_data_o        <= '0';

    start_of_field_o     <= '0';
    signal_field_valid_o <= '0';
    data_ready_o         <= '1';
    
    control_next_state <= control_curr_state;

    case control_curr_state is
       
      when SIGNAL_START =>
        start_of_field_o    <= '1';            
        enable_deintpun_o   <= enable_i;
        enable_viterbi_o    <= enable_i;
        enable_signal_o     <= enable_i;
        data_ready_o        <= '0';
        if start_of_burst_i = '1' then
          control_next_state <= SIGNAL_START;
        else
          control_next_state <= SIGNAL_DECODE;
        end if;

      when SIGNAL_DECODE =>
        enable_deintpun_o <=  enable_i;
        enable_viterbi_o  <=  enable_i;
        enable_signal_o   <=  enable_i;
        data_ready_o      <= data_ready_deintpun_i;
        if start_of_burst_i = '1' then
          control_next_state <= SIGNAL_START;
        elsif signal_field_valid_i = '1' then
          control_next_state <= DATA_START;
        end if;

      when DATA_START =>
        signal_field_valid_o <= '1';
        start_of_field_o     <= '1';            
        enable_deintpun_o    <= enable_i;
        enable_viterbi_o     <= enable_i;
        enable_data_o        <= enable_i;
        data_ready_o         <= '0';
        if start_of_burst_i = '1' then
          control_next_state <= SIGNAL_START;
        elsif parity_error = '1' or 
              unsupported_rate = '1' or
              unsupported_length = '1' then
          control_next_state <= IDLE;
        else
          control_next_state <= DATA_DECODE;
        end if;

      when DATA_DECODE  =>
        enable_deintpun_o <= enable_i;
        enable_viterbi_o  <= enable_i;
        enable_data_o     <= enable_i;
        data_ready_o      <= data_ready_deintpun_i;
        if start_of_burst_i = '1' then
          control_next_state <= SIGNAL_START;
        elsif end_of_data_i = '1' then
          control_next_state <= IDLE;
        end if;

      when others => 
        if start_of_burst_i = '1' then
          control_next_state <= SIGNAL_START;
        else
          control_next_state <= IDLE;
        end if;
        
    end case;

  end process field_combinational_p;


  --------------------------------------
  -- Set datafield parameter process
  --------------------------------------
  set_datafield_parameter_p : process (signal_field_i, smu_table_i)
  begin
    unsupported_rate <= '0';
    
    case signal_field_i(3 downto 0) is
    
      when "1011" =>                   --  6Mbit/s BPSK 1/2
        qam_mode_data      <= "11";
        pun_mode_data      <= "00";
        smu_partition_data <= smu_table_i( 1 downto 0);
     
      when "1111" =>                   --  9Mbit/s BPSK 3/4
        qam_mode_data      <= "11";
        pun_mode_data      <= "11";
        smu_partition_data <= smu_table_i( 3 downto 2);
     
      when "1010" =>                   -- 12Mbit/s QPSK 1/2
        qam_mode_data      <= "10";
        pun_mode_data      <= "00";
        smu_partition_data <= smu_table_i( 5 downto 4);
     
      when "1110" =>                   -- 18Mbit/s QPSK 3/4
        qam_mode_data      <= "10";
        pun_mode_data      <= "11";
        smu_partition_data <= smu_table_i( 7 downto 6);
     
      when "1001" =>                   -- 24Mbit/s 16QAM 1/2
        qam_mode_data      <= "01";
        pun_mode_data      <= "00";
        smu_partition_data <= smu_table_i( 9 downto 8);
     
      when "1101" =>                   -- 36Mbit/s 16QAM 3/4
        qam_mode_data      <= "01";
        pun_mode_data      <= "11";
        smu_partition_data <= smu_table_i(11 downto 10);
     
      when "1000" =>                   -- 48Mbit/s 64QAM 2/3
        qam_mode_data      <= "00";
        pun_mode_data      <= "10";
        smu_partition_data <= smu_table_i(13 downto 12);
     
      when "1100" =>                   -- 54Mbit/s 64QAM 3/4
        qam_mode_data      <= "00";
        pun_mode_data      <= "11";
        smu_partition_data <= smu_table_i(15 downto 14);
     
      when others =>              -- data rate not supported
        qam_mode_data      <= "11";
        pun_mode_data      <= "00";
        smu_partition_data <= smu_table_i( 1 downto 0);
        unsupported_rate   <= '1';
        
    end case;
    
  end process set_datafield_parameter_p;

  ---------------------------------------
  -- Check length field parameter process
  ---------------------------------------
  check_lengthfield_parameter_p : process (signal_field_i, min_length_decode,
                                           max_length_decode)
  begin
    unsupported_length <= '0';
    if (signal_field_i(16 downto 5) < min_length_decode or
        signal_field_i(16 downto 5) > max_length_decode) then
      unsupported_length <= '1';
    end if;
  end process check_lengthfield_parameter_p;

  -- Min & max limit for length decoding
  min_length_decode <= MIN_LENGTH_DECODE_CHK_CT when rx_length_chk_en_i = '1'
                  else MIN_LENGTH_DECODE_CT;
  max_length_decode <= length_limit_i when rx_length_chk_en_i = '1'
                  else MAX_LENGTH_DECODE_CT;

  -- Parity check
  parity       <= even_parity(signal_field_i(SIGNAL_FIELD_LENGTH_CT-2 downto 0));
  parity_error <= parity xor signal_field_i(SIGNAL_FIELD_LENGTH_CT-1); 

  -- length of data burst in bits including service_field and tail_bits
  field_length_data <= conv_integer(signal_field_i(16 downto 5)&"000")
                       + SERVICE_FIELD_LENGTH_CT
                       + TAIL_BITS_CT;

  --------------------------------------
  -- Write burst parameter process
  --------------------------------------
  write_burst_parameter_p : process (clk, reset_n)
  begin
    if reset_n = '0' then                 -- asynchronous reset (active low)
      qam_mode_o           <= QAM_MODE_SIGNAL_CT;
      pun_mode_o           <= PUN_MODE_SIGNAL_CT;
      smu_partition_o      <= SMU_PARTITION_SIGNAL_CT;
      field_length_o       <= conv_std_logic_vector(FIELD_LENGTH_SIGNAL_CT,16);
      parity_error_o       <= '0';
      unsupported_rate_o   <= '0';
      unsupported_length_o <= '0';
    elsif clk'event and clk = '1' then    -- rising clock edge
      if sync_reset_n = '0' or (enable_i = '1' and start_of_burst_i = '1') then
        qam_mode_o           <= QAM_MODE_SIGNAL_CT;
        pun_mode_o           <= PUN_MODE_SIGNAL_CT;
        smu_partition_o      <= SMU_PARTITION_SIGNAL_CT;
        field_length_o       <= conv_std_logic_vector(FIELD_LENGTH_SIGNAL_CT,16);
        parity_error_o       <= '0';
        unsupported_rate_o   <= '0';
        unsupported_length_o <= '0';
      elsif enable_i = '1' and signal_field_valid_i = '1' then
        qam_mode_o           <= qam_mode_data;
        pun_mode_o           <= pun_mode_data;
        smu_partition_o      <= smu_partition_data;
        field_length_o       <= conv_std_logic_vector(field_length_data,16);
        parity_error_o       <= parity_error;
        unsupported_rate_o   <= unsupported_rate;
        unsupported_length_o <= unsupported_length;
      end if;
    end if;
  end process write_burst_parameter_p;

end RTL;
