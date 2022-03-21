
--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of agc_cca_hissbb is

  --=----------------------------------------------------------------------------
  -- CONSTANTS
  --=----------------------------------------------------------------------------
  constant DEL_1_US_CT : STD_LOGIC_VECTOR (14 downto 0)
                                        := CONV_STD_LOGIC_VECTOR (80, 15);
  constant DEL_4_US_CT : STD_LOGIC_VECTOR (14 downto 0)
                                        := CONV_STD_LOGIC_VECTOR (320, 15);
  constant DEL_16_US_CT : STD_LOGIC_VECTOR (14 downto 0)
                                         := CONV_STD_LOGIC_VECTOR (1280, 15);
  constant DEL_144_US_CT : STD_LOGIC_VECTOR (14 downto 0)
                                         := CONV_STD_LOGIC_VECTOR (11520, 15);
  constant DEL_3_65_MS_CT : STD_LOGIC_VECTOR (21 downto 0)
                                         := CONV_STD_LOGIC_VECTOR (292000, 22);
  constant US_to_80_MHZ_CT : STD_LOGIC_VECTOR(6 downto 0) := "1010000";
                                        -- to convert us to 80 MHZ ticks

  constant DEL_16_US_44MHZ_CT : STD_LOGIC_VECTOR (14 downto 0)
                                        := CONV_STD_LOGIC_VECTOR (704, 15);
  constant DEL_144_US_44MHZ_CT : STD_LOGIC_VECTOR (14 downto 0)
                                        := CONV_STD_LOGIC_VECTOR (6336, 15);
  constant DEL_3_65_MS_44MHZ_CT : STD_LOGIC_VECTOR (21 downto 0)
                                        := CONV_STD_LOGIC_VECTOR (160600, 22);
  constant US_to_44_MHZ_CT : STD_LOGIC_VECTOR(6 downto 0) := "0101100";


  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal agc_bb_state : AGC_BB_STATE_TYPE;  -- fsm's state

  signal delay_over  : STD_LOGIC;       -- the main delay event (longest delay)
  signal delay_over2 : STD_LOGIC;       -- the main delay event (longest delay)
  signal delay_over3 : STD_LOGIC;       -- the main delay event (longest delay)

  signal big_delay_over : STD_LOGIC;    -- secondary delay event shorter
                                        --     than delay_over

  signal packet_length_ff1 : STD_LOGIC_VECTOR (15 downto 0);
                                                   -- delay in 80 MHZ ticks
  signal prev_agc_bb_state   : AGC_BB_STATE_TYPE;  -- Previous state

  signal rx_11a_enable_internal : STD_LOGIC;
  signal rx_11b_enable_internal : STD_LOGIC;
  signal rxonoff_req_internal   : STD_LOGIC;
  signal init_rx_internal       : STD_LOGIC;
  signal cca_busy_internal      : STD_LOGIC;
  signal phy_txstartend_req_del : STD_LOGIC;
  signal phy_rxstartend_ind_ff1 : STD_LOGIC;

  -- Resynchronized signals from Modem B clock domain.
  signal sfd_found_ff1_resync      : STD_LOGIC;
  signal sfd_found_ff2_resync      : STD_LOGIC;
  
  -- Resynchronized signals from Modem A clock domain.
  signal cp2_detected_ff1_resync     : STD_LOGIC;
  signal cp2_detected_ff2_resync     : STD_LOGIC;
  
  signal rxv_macaddr_match_ff1  :  STD_LOGIC;                 
  signal rxv_macaddr_match_ff2  :  STD_LOGIC;                 
  signal rxv_macaddr_match_ff3  :  STD_LOGIC;                 
  signal rxv_macaddr_match_ff4  :  STD_LOGIC;                 
  signal rxv_macaddr_match_ff5  :  STD_LOGIC;                 
  signal rxv_macaddr_match_ff6  :  STD_LOGIC;                 
  signal rxv_macaddr_match_ff7  :  STD_LOGIC;                 
  signal rxv_macaddr_match_ff8  :  STD_LOGIC;                 
  signal rxv_macaddr_match_ff9  :  STD_LOGIC;                 
  signal rxv_macaddr_match_ff10 :  STD_LOGIC;                 
                                                             


  signal packet_duration_length : STD_LOGIC_VECTOR (15 downto 0);
                                                   -- delay in 80 MHZ ticks

  signal rxv_datarate_ff1   : STD_LOGIC_VECTOR( 3 downto 0); -- PSDU rec. rate


  signal nb_bit_rest       : STD_LOGIC_VECTOR(15 downto 0); -- PSDU rec. length
  signal reload_count      : STD_LOGIC;
  signal cnt_mod4          : STD_LOGIC_VECTOR(2 downto 0);
  signal cnt_mod4_end      : STD_LOGIC_VECTOR(2 downto 0);

  signal rx_imm_stop       : STD_LOGIC;

  signal rampdown_rest     : STD_LOGIC_VECTOR(2 downto 0);

  signal wait_cp2          : STD_LOGIC;
  signal agc_rfint_int     : STD_LOGIC;

  --------------------------------------------
  -- Function to convert the state to a std_logic_vector
  --------------------------------------------
   function conv_state_to_slv (state : AGC_BB_STATE_TYPE)
    return STD_LOGIC_VECTOR is

  begin

    case state is
      when idle                   => return "0001";
      when wait_deldc             => return "0010";
      when wait1_signal_valid     => return "0011";
      when wait_cs                => return "0100";
      when return_to_idle         => return "0101";
      when wait2_signal_valid     => return "0110";
      when wait_16us              => return "0111";
      when continue_reception_11a => return "1000";
      when continue_reception_11b => return "1001";
      when delay_init_rx          => return "1010";
      when search_sfd             => return "1011";
      when rxend_delay            => return "1100";
      when others                 => return "1111";
    end case;
  end;  -- FUNCTION conv_state_to_slv;



  --------------------------------------------
  -- Function to calculate the number of bits per symbol for each RATE
  --------------------------------------------
  function def_nb_bit_p_symb (
    signal   rate : std_logic_vector(3 downto 0))
    return std_logic_vector is
    variable res  : std_logic_vector(7 downto 0);
  begin
    res     := (others => '0');
    case rate is
      when "1011" =>      -- 6 Mbits/s
        res := conv_std_logic_vector(24, 8);
      when "1111" =>      -- 9 Mbits/s
        res := conv_std_logic_vector(36, 8);
      when "1010" =>      -- 12 Mbits/s
        res := conv_std_logic_vector(48, 8);
      when "1110" =>      -- 18 Mbits/s
        res := conv_std_logic_vector(72, 8);
      when "1001" =>      -- 24 Mbits/s
        res := conv_std_logic_vector(96, 8);
      when "1101" =>      -- 36 Mbits/s
        res := conv_std_logic_vector(144, 8);
      when "1000" =>      -- 48 Mbits/s
        res := conv_std_logic_vector(192, 8);
      when "1100" =>      -- 54 Mbits/s
        res := conv_std_logic_vector(216, 8);
      when others => null;
    end case;
    return res;
  end def_nb_bit_p_symb;

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------

begin

  -- to enable reading of outp ports assigned to diagnostic port
  rx_11a_enable    <= rx_11a_enable_internal;
  rx_11b_enable    <= rx_11b_enable_internal;
  agc_rxonoff_req  <= rxonoff_req_internal;
  init_rx       <= init_rx_internal;
  cca_busy      <= cca_busy_internal;

  agc_rfint  <= agc_rfint_int;

  --=---------------------------------------------------------------------------
  --= AGC state machine:
  --= Compute the next state and the associated control signals
  --=---------------------------------------------------------------------------
  agc_fsm_hiss_bb_comb_p : process (clk, reset_n)
    variable sig_valid_on_v : STD_LOGIC;  -- RF has sent a signal valid on 
    variable corr_11a_90_v  : BOOLEAN;
    variable corr_11a_99_v  : BOOLEAN;

    variable rx_enable_v    : STD_LOGIC;  -- diagnostic signal. OR of
                                          -- rx_11a_enable, rx_11b_enable
    variable disable_cond_v : STD_LOGIC;  -- diagnostic signal OR of 
                                          -- agc_disb, phy_ccarst_req, plcp_error
    variable delay_offset_v : STD_LOGIC_VECTOR(15 downto 0); -- PSDU rec. length

  begin  -- process agc_fsm_hiss_bb_comb_p
    
    if reset_n = '0' then               -- asynchronous reset (active low)

      agc_bb_state             <= idle;
      hiss_stream_enable       <= '0';
      rx_11a_enable_internal   <= '0';
      rx_11b_enable_internal   <= '0';
      a_b_mode                 <= '0';
      rxonoff_req_internal     <= '0';
      energy_detect            <= '0';
      cca_busy_internal        <= '0';
      agc_busy                 <= '0';
      phy_cca_ind              <= '0';
      init_rx_internal         <= '0';
      phy_ccarst_conf          <= '0';
      sig_valid_on_v           := '0';
      corr_11a_99_v            := false;
      corr_11a_90_v            := false;
      agc_cca_hissbb_diag_port <= (others => '0');
      rx_enable_v              := '0';
      disable_cond_v           := '0';
      modem_a_fsm_rst_n        <= '1';
      phy_txstartend_req_del   <= '0';
      phy_rxstartend_ind_ff1   <= '0';

      sfd_found_ff1_resync      <= '0';
      sfd_found_ff2_resync      <= '0';
--       plcp_error_ff1_resync     <= '0';
--       plcp_error_ff2_resync     <= '0';
      
      
      cp2_detected_ff1_resync  <= '0'; 
      cp2_detected_ff2_resync  <= '0'; 
      
      agc_rfint_int          <= '0';
 
      rxv_rssi       <= (others => '0');
      rxv_rxant      <= '0';
      rxv_ccaaddinfo <= (others => '0');
      
      rxv_datarate_ff1 <= (others => '0'); 
 
 
      nb_bit_rest      <= (others => '0'); 
      reload_count     <= '0';
      
      select_rx_ab     <= '0';
      
      cnt_mod4          <= "000";
      cnt_mod4_end      <= "000";
      delay_offset_v    := (others => '0');

      agc_rfoff              <= '0';


      rxv_macaddr_match_ff1  <= '0';
      rxv_macaddr_match_ff2  <= '0';
      rxv_macaddr_match_ff3  <= '0';
      rxv_macaddr_match_ff4  <= '0';
      rxv_macaddr_match_ff5  <= '0';
      rxv_macaddr_match_ff6  <= '0';
      rxv_macaddr_match_ff7  <= '0';
      rxv_macaddr_match_ff8  <= '0';
      rxv_macaddr_match_ff9  <= '0';
      rxv_macaddr_match_ff10 <= '0';



      rx_imm_stop                <= '0';
      rampdown_rest <= "000";
      
      wlanrxind <= '0';
      wait_cp2  <= '0';
      
      edtransmode_reset <= '0'; 

    elsif clk'event and clk = '1' then  -- rising clock edge

      phy_txstartend_req_del <= phy_txstartend_req;
      phy_rxstartend_ind_ff1 <= phy_rxstartend_ind; 
      -- Resynchronize signals coming from modem b clock domain.
      sfd_found_ff1_resync      <= sfd_found;
      sfd_found_ff2_resync      <= sfd_found_ff1_resync;

      -- Resynchronize signals coming from modem a clock domain.
      cp2_detected_ff1_resync      <= cp2_detected;
      cp2_detected_ff2_resync      <= cp2_detected_ff1_resync;



      rxv_macaddr_match_ff1 <=  rxv_macaddr_match;
      rxv_macaddr_match_ff2 <=  rxv_macaddr_match_ff1;
      rxv_macaddr_match_ff3 <=  rxv_macaddr_match_ff2;
      rxv_macaddr_match_ff4 <=  rxv_macaddr_match_ff3;
      rxv_macaddr_match_ff5 <=  rxv_macaddr_match_ff4;
      rxv_macaddr_match_ff6 <=  rxv_macaddr_match_ff5;
      rxv_macaddr_match_ff7 <=  rxv_macaddr_match_ff6;
      rxv_macaddr_match_ff8 <=  rxv_macaddr_match_ff7;
      rxv_macaddr_match_ff9 <=  rxv_macaddr_match_ff8;
      rxv_macaddr_match_ff10 <=  rxv_macaddr_match_ff9;



      edtransmode_reset <= '0';

      if rx_11a_enable_internal = '1' or rx_11b_enable_internal = '1' then
        rx_enable_v := '1';
      else
        rx_enable_v := '0';
      end if;

--      if agc_disb = '1' or phy_ccarst_req = '1' or plcp_error_ff2_resync = '1' then
      if agc_disb = '1' or phy_ccarst_req = '1' then
        disable_cond_v := '1';
      else
        disable_cond_v := '0';
      end if;
      
      -- Back to idle state if the modem is transmitting
      if phy_txstartend_req_del = '1' then
        if agc_bb_state <= idle then
          rx_11a_enable_internal <= '0';
        end if;
        agc_bb_state           <= idle;  -- t r a n s i t i o n
        rxonoff_req_internal   <= '0';
        a_b_mode               <= '0';
        hiss_stream_enable     <= '0';
        cca_busy_internal      <= '0';
        agc_busy               <= '0';
        phy_cca_ind            <= '0';
        rx_11b_enable_internal <= '0';
        energy_detect          <= '0';
        sig_valid_on_v         := '0';
        corr_11a_99_v          := false;
        corr_11a_90_v          := false;
        modem_a_fsm_rst_n      <= '1';
        nb_bit_rest            <= (others => '0'); 
        reload_count           <= '0';
        cnt_mod4               <= "000";
        cnt_mod4_end           <= "000";
        delay_offset_v         := (others => '0');
        agc_rfoff              <= '0';
        agc_rfint_int              <= '0';
        rx_imm_stop            <= '0';
        wlanrxind              <= '0';
        wait_cp2               <= '0';
        edtransmode_reset      <= '1';

     end if;
      

      agc_cca_hissbb_diag_port <= conv_state_to_slv (agc_bb_state) &
                                  delay_over &
                                  big_delay_over &
                                  cca_flags(5) &
                                  cca_flags (0) &
                                  rx_enable_v &
                                  cca_busy_internal &
                                  disable_cond_v &
                                  phy_rxstartend_ind &
                                  agc_rfint_int &
                                  sfd_found_ff2_resync &
                                  rxonoff_req_internal &
                                  init_rx_internal;
      
      init_rx_internal <= '0';
      sig_valid_on_v   := '0';
      corr_11a_90_v    := false;
      corr_11a_99_v    := false;

      agc_rfint_int        <= '0';
      agc_rfoff        <= '0';

      -- Acknowled reset request
      if phy_ccarst_req = '1' then
        phy_ccarst_conf <= '1';
      else
        phy_ccarst_conf <= '0';
      end if;

      -- Back to idle state if block is disabled or reset or an error occured
      if disable_cond_v = '1' then
        agc_bb_state           <= idle;  -- t r a n s i t i o n
        rxonoff_req_internal   <= '0';
        a_b_mode               <= '0';
        rx_11a_enable_internal <= '0';
        rx_11b_enable_internal <= '0';
        hiss_stream_enable     <= '0';
        energy_detect          <= '0';
        cca_busy_internal      <= '0';
        agc_busy               <= '0';
        phy_cca_ind            <= '0';
        sig_valid_on_v         := '0';
        corr_11a_99_v          := false;
        corr_11a_90_v          := false;
        modem_a_fsm_rst_n      <= '1';
        nb_bit_rest            <= (others => '0'); 
        reload_count           <= '0';
        cnt_mod4               <= "000";
        cnt_mod4_end           <= "000";
        delay_offset_v         := (others => '0');
        rx_imm_stop                     <= '0';
        wlanrxind              <= '0';
        wait_cp2               <= '0';
--         if plcp_error_ff2_resync = '1' then
--           edtransmode_reset      <= '1';
--         end if;  

      
      else
        
        case agc_bb_state is

          --------------------------------
          --  i d l e
          --------------------------------
          when idle =>

            wlanrxind             <= '0';
            
            if phy_txstartend_req = '0' and agc_rxonoff_conf = '0' then  -- end of packet
              
              agc_bb_state         <= wait1_signal_valid;  --  t r a n s i t i o n

              rxonoff_req_internal <= '1';
              agc_busy             <= '0';
              rx_imm_stop          <= '0';
              modem_a_fsm_rst_n    <= '1';

            end if;

            --=--------------------------------------
            --   w a i t 1 _ s i g n a l _ v a l i d
            --=--------------------------------------
          when wait1_signal_valid =>

            agc_rfoff <= '0'; 

            if cca_flags_marker = '1' then
              -- CCA FLAG Ramp down detection
              if cca_flags (0) = '1' and cca_flags (1) = '1' and cca_flags (2) = '0' then

                energy_detect     <= '0';

                if modeabg = "01" or reg_edmode = '1' or reg_edtransmode = '1'  then
                  cca_busy_internal <= '0';
                  agc_busy          <= '0';     
                  phy_cca_ind       <= '0';
                  rxonoff_req_internal <= '0';
                  agc_bb_state         <= idle;
                  edtransmode_reset      <= '1';
                end if;
              end if;  
            end if;  
            
            
            if sw_rfoff_req = '0' then
            
              if cca_flags_marker = '1' then
            
               -- additionnal information from the WiLDRF
               rxv_rssi       <= cca_add_flags(6 downto 0);
               rxv_rxant      <= cca_add_flags(7);
               rxv_ccaaddinfo <= cca_add_flags(15 downto 8);
               -- Check if an interrupt from the WiLDRF is contained in the cca_flag
                if cca_flags = "000001" then
                  agc_rfint_int <= '1';
                else  
                  if cca_flags (0) = '1' and cca_flags (1) = '1' and
                                             cca_flags (2) = '1' then
                    -- Ramp detected and signal above -62 dBm
                    energy_detect <= '1';
                    
                    if modeabg = "01" or reg_edmode = '1' or reg_edtransmode = '1' then
                      -- 11a only mode, cca is busy when IL > -62 dBm
                      cca_busy_internal <= '1';
                      phy_cca_ind       <= '1';
                      agc_busy          <= '1';
                    end if;
                    
                  else
                    energy_detect     <= '0';

                    if modeabg = "01" or reg_edmode = '1' or reg_edtransmode = '1'  then
                      cca_busy_internal    <= '0';
                      agc_busy             <= '0';     
                      phy_cca_ind          <= '0';
                    end if;
                  end if;
                end if;
                
              end if;  

              if cca_flags_marker = '1' and
                cca_flags (0) = '0' and cca_flags (5) = '0' then
                -- Initial detection at 4 us and enrgy above threshold
                sig_valid_on_v := '1';

                corr_11a_90_v := cca_flags (1) = '1';
                corr_11a_99_v := cca_flags (2) = '1';

              end if;  -- IF  cca_flags_marker = '1' THEN

              if sig_valid_on_v = '1' then
                
                if modeabg = "01" then    -- 11a only
                  
                  if corr_11a_90_v or cca_flags(4) = '1' then
                    -- CCA is set to busy if .11a only mode
                    agc_busy          <= '1';
                    phy_cca_ind       <= '1';
                  end if;
                  
                  if (corr_11a_99_v or corr_11a_90_v) then  -- 11a CS +ve
                    agc_bb_state <= wait_deldc;    --  t r a n s i t i o n
                  else
                    agc_bb_state         <= idle;  --  t r a n s i t i o n
                    edtransmode_reset    <= '1';

                    rxonoff_req_internal <= '0';
                    energy_detect        <= '0';
                    cca_busy_internal    <= '0';
                    phy_cca_ind          <= '0';
                  end if;
                  
                else                      -- not 11a only
                  agc_bb_state  <= wait_deldc;     --  t r a n s i t i o n
                  energy_detect <= '1';
                  
                  if (cca_mode = 1 and (modeabg = "00" or modeabg = "10")) or
                    (longslot = '0' and modeabg = "00")  then
                    -- Energy above threshold or short slot mode in .11g
--                     cca_busy_internal <= '1';
                    agc_busy          <= '1';
                    phy_cca_ind       <= '1';
                  end if;
                  
                end if;  -- if modeabg = "01"            
              end if;  -- if gt_62_dbm
            end if;
            
            --=-------------------------
            --  w a i t _ d e l d c
            --=-------------------------
          when wait_deldc =>
            agc_busy          <= '1';
            if delay_over = '1' then
              
              agc_bb_state <= wait_cs;  --  t r a n s i t i o n

              hiss_stream_enable     <= '1';  
              if modeabg /= "10" then           -- NOT 11b only mode
                cca_busy_internal      <= '1';
                rx_11a_enable_internal <= '1';  -- Start 11a modem
              end if;  -- if modeabg /= "10"
              
            end if;  -- if delay_over

            --=------------------
            --   w a i t _ c s
            --=------------------
          when wait_cs =>

            if cca_cs_valid = '1' then  -- received some infor from RF
              wait_cp2 <= '0';
              if cca_cs = "11" then  -- 11b
                
                agc_bb_state      <= wait2_signal_valid;  --  t r a n s i t i o n
                -- reset the modem a. Diable it three ticks later
                modem_a_fsm_rst_n <= '0';
                a_b_mode          <= '1';                 -- b mode
                select_rx_ab      <= '1';                 -- b mode
                cca_busy_internal <= '0';
                agc_busy          <= '1';
                phy_cca_ind       <= '1';
                wlanrxind         <= '1';
              elsif cca_cs = "01" then
                wait_cp2 <= '1';
              else  -- Noise detected: quit and return to idle
                agc_bb_state <= return_to_idle;   --  t r a n s i t i o n

                rxonoff_req_internal   <= '0';
                a_b_mode               <= '0';
                energy_detect          <= '0';
                cca_busy_internal      <= '0';
                phy_cca_ind            <= '0';
                modem_a_fsm_rst_n      <= '0';
                hiss_stream_enable     <= '0';                
              end if;  -- if cca_cs =             
--               -- additionnal information from the WiLDRF
--               rxv_rssi       <= cca_add_flags(6 downto 0);
--               rxv_rxant      <= cca_add_flags(7);
--               rxv_ccaaddinfo <= cca_add_flags(15 downto 8);
            end if;  -- if cca_cs_valid

            if wait_cp2 = '1' and cp2_detected_ff2_resync = '1' then  -- continue 11a
              reload_count      <= '0';
              agc_bb_state      <= wait_16us;  --  t r a n s i t i o n
              cca_busy_internal <= '1';
              wlanrxind         <= '1';
              agc_busy          <= '1';
              phy_cca_ind       <= '1';
              wait_cp2          <= '0';
              select_rx_ab      <= '0';                  -- a mode
            end if;

            if delay_over = '1' then    -- time out wait_cs_max us
              agc_bb_state <= return_to_idle;     --  t r a n s i t i o n
              rxonoff_req_internal   <= '0';
              a_b_mode               <= '0';
              modem_a_fsm_rst_n      <= '0';
              hiss_stream_enable     <= '0';
              energy_detect          <= '0';
              cca_busy_internal      <= '0';
              phy_cca_ind            <= '0';
              wait_cp2               <= '0';
           end if;  -- if delay_over = '1' THEN


            --=------------------------------
            --   r e t u r n _ t o _ i d l e
            --=------------------------------
          when return_to_idle =>

            agc_bb_state <= idle;   --  t r a n s i t i o n
            rx_11a_enable_internal <= '0';              
            modem_a_fsm_rst_n  <= '1';   -- remove the reset
            edtransmode_reset      <= '1';


            --=------------------------
            --   w a i t _ 1 6 _ u s
            --=------------------------
          when wait_16us =>
--            nb_bit_p_symb    <= def_nb_bit_p_symb(rxv_datarate_ff1);

            cnt_mod4      <= "100";
              
            if phy_rxstartend_ind = '1' then
              rxv_datarate_ff1 <= rxv_datarate;
              agc_bb_state <= continue_reception_11a;  --  t r a n s i t i o n
              reload_count <= '1';


              ----------------------------------------------------------------
              -- Selection of the delay according to the ADDESTIMDURA register
              ----------------------------------------------------------------
              case reg_addestimdura is
                when "1111" =>   -- -1 us
                  cnt_mod4_end <= "001";
                  delay_offset_v := (others => '0');
            
                when "1110" =>   -- -2 us
                  cnt_mod4_end <= "010";
                  delay_offset_v := (others => '0');

                when "1101" =>   -- -3 us
                  cnt_mod4_end <= "011";
                  delay_offset_v := (others => '0');

                when "1100" =>   -- -4 us
                  cnt_mod4_end <= "000";
                  delay_offset_v := sxt(0 - ('0' & def_nb_bit_p_symb(rxv_datarate)),delay_offset_v'length);

                when "1011" =>   -- -5 us
                  cnt_mod4_end <= "001";
                  delay_offset_v := sxt(0 - ('0' & def_nb_bit_p_symb(rxv_datarate)),delay_offset_v'length);

                when "1010" =>   -- -6 us
                  cnt_mod4_end <= "010";
                  delay_offset_v := sxt(0 - ('0' & def_nb_bit_p_symb(rxv_datarate)),delay_offset_v'length);

                when "1001" =>   -- -7 us
                  cnt_mod4_end <= "011";
                  delay_offset_v := sxt(0 - ('0' & def_nb_bit_p_symb(rxv_datarate)),delay_offset_v'length);

                when "1000" =>   -- -8 us
                  cnt_mod4_end <= "000";
                  delay_offset_v := sxt(0 - ('0' & def_nb_bit_p_symb(rxv_datarate) & '0'),delay_offset_v'length);

                when "0000" =>   -- 0 us
                  cnt_mod4_end <= "000";
                  delay_offset_v := (others => '0');
                  
                when "0001" =>   -- +1 us
                  cnt_mod4_end <= "011";
                  delay_offset_v := ext(def_nb_bit_p_symb(rxv_datarate),delay_offset_v'length);

                when "0010" =>   -- +2 us
                  cnt_mod4_end <= "010";
                  delay_offset_v := ext(def_nb_bit_p_symb(rxv_datarate),delay_offset_v'length);

                when "0011" =>   -- +3 us
                  cnt_mod4_end <= "001";
                  delay_offset_v := ext(def_nb_bit_p_symb(rxv_datarate),delay_offset_v'length);

                when "0100" =>   -- +4 us
                  cnt_mod4_end <= "000";
                  delay_offset_v := ext(def_nb_bit_p_symb(rxv_datarate),delay_offset_v'length);

                when "0101" =>   -- +5 us
                  cnt_mod4_end <= "011";
                  delay_offset_v := ext(def_nb_bit_p_symb(rxv_datarate) & '0',delay_offset_v'length);

                when "0110" =>   -- +6 us
                  cnt_mod4_end <= "010";
                  delay_offset_v := ext(def_nb_bit_p_symb(rxv_datarate) & '0',delay_offset_v'length);
            
                when "0111" =>   -- +7 us
                  cnt_mod4_end <= "001";
                  delay_offset_v := ext(def_nb_bit_p_symb(rxv_datarate) & '0',delay_offset_v'length);

                when others =>
                  null;
              end case;

              -- nb_bit_rest = service + length * 8 + tail bits + delay_offset
              -- Number of bit in the burst, including D0
             
              nb_bit_rest      <= ext(unsigned(rxv_length & "000") + unsigned(conv_std_logic_vector(22, 6)) 
                                  + signed(delay_offset_v),nb_bit_rest'length);
 
            end if;

            --=------------------------------------------------
            --  c o n t i n u e  _ r e c e p t i o n _ 1 1 a
            --=------------------------------------------------
          when continue_reception_11a =>
            -- Packet end occurs
            reload_count <= '0';
            
            -- Stop the reception because the mac address does not match
            if rxv_macaddr_match_ff2 = '1' and rxv_macaddr_match_ff1 = '0' then
              hiss_stream_enable     <= '0';
              rx_11b_enable_internal <= '0';
              cca_busy_internal      <= '0';
--              energy_detect          <= '0';
              modem_a_fsm_rst_n      <= '0';
              rx_11a_enable_internal <= '0';
              agc_rfoff              <= '1';
              rx_imm_stop            <= '1';
            end if;  

            -- when a error accurs during the reception, abort the reception end go to rxend_delay
            if phy_rxstartend_ind = '0' and phy_rxstartend_ind_ff1 = '1' and rxe_errorstat /= "00" then
              agc_bb_state           <= idle;     --  t r a n s i t i o n
              phy_cca_ind            <= '0';
              rx_11b_enable_internal <= '0';
              cca_busy_internal      <= '0';
              rxonoff_req_internal   <= '0';
              a_b_mode               <= '0';
              hiss_stream_enable     <= '0';
              modem_a_fsm_rst_n      <= '0';
              energy_detect          <= '0';
              rx_11a_enable_internal <= '0';
              edtransmode_reset      <= '1';

            end if;  
            
            -- Count the number of received symboles
            if nb_bit_rest(nb_bit_rest'length - 1) = '1' then
              phy_cca_ind  <= '0';
              if rx_imm_stop = '0' then
                agc_bb_state <= rxend_delay;  --  t r a n s i t i o n              
              else 
                agc_bb_state <= rampdown_delay;  --  t r a n s i t i o n              
                rampdown_rest <= reg_rampdown;
              end if;
            else  
              if delay_over  = '1' then
                cnt_mod4  <= cnt_mod4  - '1';
                if cnt_mod4 = "000" then
                  cnt_mod4 <= "011";
                  nb_bit_rest <= ext(nb_bit_rest, nb_bit_rest'length) - ext(def_nb_bit_p_symb(rxv_datarate_ff1)(7 downto 0), nb_bit_rest'length);
                end if;  
            
                if ext(nb_bit_rest, nb_bit_rest'length) < ext(def_nb_bit_p_symb(rxv_datarate_ff1), nb_bit_rest'length) then
                  if cnt_mod4 = cnt_mod4_end then
                    phy_cca_ind  <= '0';
                    if rx_imm_stop = '0' then
                      agc_bb_state <= rxend_delay;  --  t r a n s i t i o n              
                    else 
                      agc_bb_state <= rampdown_delay;  --  t r a n s i t i o n              
                      rampdown_rest <= reg_rampdown;
                    end if;
                  else
                    nb_bit_rest <= (others => '0');
                    reload_count <= '1';
                  end if;  
                else
                  reload_count <= '1';
                end if;
              end if;  
            end if;                  

            --=---------------------------------------
            --  w a i t 2 _ s i g n a l _ v a l i d
            --=---------------------------------------
          when wait2_signal_valid =>

            -- THe following logic assumes that cca_flags_marker comes after
            -- five ticks
            
            if delay_over2 = '1' then         -- disable the modem 11a
              hiss_stream_enable     <= '0';  -- Stop 11a modem
              rx_11a_enable_internal <= '0';
            end if;

            if delay_over3 = '1' then   -- deassert the modem_a_fsm_rst_n
              modem_a_fsm_rst_n <= '1';
            end if;
            if cca_flags_marker = '1' and
              cca_flags (0) = '0' and cca_flags (5) = '1' then  -- signal valid on
              agc_bb_state <= delay_init_rx;  --  t r a n s i t i o n

              hiss_stream_enable     <= '1';  -- Start 11b modem
              rx_11b_enable_internal <= '1';

              
              -- additionnal information from the WiLDRF
              rxv_rssi       <= cca_add_flags(6 downto 0);
              rxv_rxant      <= cca_add_flags(7);
              rxv_ccaaddinfo <= cca_add_flags(15 downto 8);
              
            end if;  -- if cca_flags THEN

            if delay_over = '1' then    -- time out 9.6 us
              
              agc_bb_state <= idle;     --  t r a n s i t i o n

              rxonoff_req_internal   <= '0';
              a_b_mode               <= '0';
              hiss_stream_enable     <= '0';
              rx_11b_enable_internal <= '0';
              hiss_stream_enable     <= '0';
              energy_detect          <= '0';
              cca_busy_internal      <= '0';
              phy_cca_ind            <= '0';
              edtransmode_reset      <= '1';
              
            end if;  -- if delay_over

            --=----------------------------
            --  d e l a y _ i n i t _ r x
            --=----------------------------
          when delay_init_rx =>
            if delay_over = '1' then
              init_rx_internal  <= '1';
              agc_bb_state      <= search_sfd;  -- t r a n s i t i o n
              cca_busy_internal <= '1';  -- ??? should it be mode dependent

            end if;

            --=------------------------
            --  s e a r c h _ s f d 
            --=------------------------
          when search_sfd =>
            if prev_agc_bb_state = delay_init_rx then
              -- init_rx_internal is 2 cc. high because 44 MHz clock
              init_rx_internal <= '1';
            else
              init_rx_internal <= '0';
            end if;

            if sfd_found_ff2_resync = '1' then
              agc_bb_state <= continue_reception_11b;  --  t r a n s i t i o n
            end if;

            if delay_over = '1' then    -- time out 128 us       
              agc_bb_state <= idle;     --  t r a n s i t i o n

              rxonoff_req_internal   <= '0';
              a_b_mode               <= '0';
              hiss_stream_enable     <= '0';
              rx_11b_enable_internal <= '0';
              cca_busy_internal      <= '0';
              phy_cca_ind            <= '0';
              energy_detect          <= '0';
              edtransmode_reset      <= '1';
            end if;  -- if delay_over

            --=----------------------------------------------
            --  c o n t i n u e _ r e c e p t i o n _ 1 1 b
            --=----------------------------------------------
          when continue_reception_11b =>

            -- Stop the reception because the mac address does not match
            if rxv_macaddr_match_ff2 = '1' and rxv_macaddr_match_ff1 = '0' then
              hiss_stream_enable     <= '0';
              cca_busy_internal      <= '0';
              modem_a_fsm_rst_n      <= '0';
              rx_11a_enable_internal <= '0';
              agc_rfoff              <= '1';
              rx_imm_stop            <= '1';
              rx_11b_enable_internal <= '0';
            end if;  
            

            -- when a error accurs during the reception, abort the reception end go to stop_11b
            if phy_rxstartend_ind = '0' and phy_rxstartend_ind_ff1 = '1' then
              if rxe_errorstat /= "00" then
                if rxe_errorstat = "10" or rxe_errorstat = "01"  then
                  agc_bb_state           <= idle;     --  t r a n s i t i o n
                  phy_cca_ind            <= '0';
                  rxonoff_req_internal   <= '0';
                  a_b_mode               <= '0';
                  edtransmode_reset      <= '1';
                end if;
                hiss_stream_enable     <= '0';
                cca_busy_internal      <= '0';
                modem_a_fsm_rst_n      <= '0';
                rx_11a_enable_internal <= '0';
                agc_rfoff              <= '1';
                rx_imm_stop            <= '1';
                rx_11b_enable_internal <= '0';
                energy_detect          <= '0';
              end if;  
            end if;  

            if big_delay_over = '1' then
              if rx_imm_stop = '0' then
                agc_bb_state <= rxend_delay;     --  t r a n s i t i o n
                phy_cca_ind      <= '0';
              else
                agc_bb_state  <= rampdown_delay;     --  t r a n s i t i o n
                rampdown_rest <= reg_rampdown;
                phy_cca_ind      <= '0';
              end if;
            end if;

            --=----------------------------------------------
            --  r x e n d _ d e l a y
            --=----------------------------------------------
          when rxend_delay =>

            wlanrxind              <= '0';

            -- Stop the reception because the mac address does not match
            if rxv_macaddr_match_ff2 = '1' and rxv_macaddr_match_ff1 = '0' then
              hiss_stream_enable     <= '0';
              cca_busy_internal      <= '0';
--              energy_detect          <= '0';
              modem_a_fsm_rst_n      <= '0';
              rx_11a_enable_internal <= '0';
              agc_rfoff              <= '1';
              rx_11b_enable_internal <= '0';
              rx_imm_stop            <= '1'; 
            end if;  


            if phy_rxstartend_ind = '0' and phy_rxstartend_ind_ff1 = '1'  then
              agc_bb_state <= idle;     --  t r a n s i t i o n

              rxonoff_req_internal   <= '0';
              a_b_mode               <= '0';
              hiss_stream_enable     <= '0';
              modem_a_fsm_rst_n      <= '0';
              rx_11b_enable_internal <= '0';
              cca_busy_internal      <= '0';
              energy_detect          <= '0';
              rx_11a_enable_internal <= '0';
              edtransmode_reset      <= '1';

            end if;

            --=----------------------------------------------
            --  r a m p d o w n _ d e l a y
            --=----------------------------------------------
          when rampdown_delay =>

            rx_imm_stop    <= '0';
            reload_count   <= '0';
            wlanrxind      <= '0';

            if rampdown_rest = "000" then
              agc_bb_state <= idle;     --  t r a n s i t i o n
              rxonoff_req_internal   <= '0';
              a_b_mode               <= '0';
              hiss_stream_enable     <= '0';
              rx_11b_enable_internal <= '0';
              cca_busy_internal      <= '0';
              modem_a_fsm_rst_n      <= '1';
              energy_detect          <= '0';
              edtransmode_reset      <= '1';
            elsif delay_over = '1' then    --  rampdown delay us       
              rampdown_rest <= rampdown_rest - '1';
              reload_count <= '1';
            end if;  -- if delay_over
        end case;
      end if;

    end if;
  end process agc_fsm_hiss_bb_comb_p;


--=------------------------------------------------------------------
--=               E N D     S T A T E     M A C H I N E
--=------------------------------------------------------------------


--=---------------------------------------
--   P R O C E S S   T I M E   W H E E L
--=---------------------------------------

  --=-----------------------------------------------------------------------------
  -- This process detects state transitions and accordingly sets up a count up
  -- process. Once the count reaches the max value. delay_over signals are pulsed.
  --
  -- The max value is stored in count_max register. The register gets its
  -- value from WILD RF delay registers multiplied by the ratio of 80 MHZ to
  -- the clock at which the delay in WILD RF register is counted.
  --
  -- Some count_max values are calculated from constants like 3.2 us etc.
  --
  -- The count_max and delay register are reset at state transition
  -- A big delay counter runs in parallel that is not reset at state boundaries
  --=-----------------------------------------------------------------------------

  time_wheel_p : process (clk, reset_n)
    
    variable delay_v     : STD_LOGIC_VECTOR (14 downto 0);  -- the counter register
    variable big_delay_v : STD_LOGIC_VECTOR (21 downto 0);  -- the counter register for 3.65 ms

    -- the three target count registers
    variable count_max_v     : STD_LOGIC_VECTOR (14 downto 0);
    variable count_max2_v    : STD_LOGIC_VECTOR (2 downto 0);
    variable count_max3_v    : STD_LOGIC_VECTOR (2 downto 0);
    variable big_count_max_v : STD_LOGIC_VECTOR (21 downto 0);
    
  begin  -- PROCESS p_time_wheel
    
    if reset_n = '0' then               -- asynchronous reset (active low)    
      
      count_max_v           := (others => '0');
      count_max2_v          := (others => '0');
      count_max3_v          := (others => '0');
      big_count_max_v       := (others => '0');
      delay_v               := (others => '0');
      big_delay_v           := (others => '0');
      delay_over          <= '0';
      delay_over2         <= '0';
      delay_over3         <= '0';
      big_delay_over      <= '0';
      prev_agc_bb_state   <= idle;
      packet_length_ff1 <= (others => '0');
      
    elsif clk'event and clk = '1' then  -- rising clock edge

      delay_over  <= '0';
      delay_over2 <= '0';
      delay_over3 <= '0';

      big_delay_over    <= '0';
      prev_agc_bb_state <= agc_bb_state;  -- to be able to detect the next state transition

      if agc_bb_state = idle then
        delay_v               := (others => '1');
        count_max_v           := (others => '0');
        count_max2_v          := (others => '0');
        count_max3_v          := (others => '0');
        big_delay_v           := (others => '1');
        big_count_max_v       := (others => '0');
        packet_length_ff1     <= (others => '0');

      elsif prev_agc_bb_state /= agc_bb_state then  -- a state transition has occured

        case agc_bb_state is

          when wait1_signal_valid =>
            delay_v     := (others => '0');
            count_max_v := (others => '1');

          when wait_deldc =>
            delay_v     := (others => '0');
            if select_clk80 = '1' then
              count_max_v := ext(("100" * deldc2), 15) - '1';
            else
              count_max_v := ext(("010" * deldc2), 15) - '1';              
            end if;
            
          when wait_cs =>
            delay_v     := (others => '0');
            if select_clk80 = '1' then
              count_max_v := ext((wait_cs_max * US_to_80_MHZ_CT), 15) - '1';
            else                 
              count_max_v := ext((wait_cs_max * US_to_44_MHZ_CT), 15) - '1';
            end if;

          when continue_reception_11a =>
            delay_over  <= '1';
                        
          when wait2_signal_valid =>
            delay_v      := (others => '0');
            if select_clk80 = '1' then
              count_max_v  := ext((wait_sig_max * US_to_80_MHZ_CT), 15) - '1';
            else
              count_max_v  := ext((wait_sig_max * US_to_44_MHZ_CT), 15) - '1';              
            end if;
            
            count_max2_v := "010";        -- 3ticks(1 tick is added by the logic)
            count_max3_v := "100";        -- 5ticks(1 tick is added by the logic)

            big_delay_v     := CONV_STD_LOGIC_VECTOR (1, 22);
            if select_clk80 = '1' then
              
              big_count_max_v := DEL_3_65_MS_CT - '1';
            else
              big_count_max_v := DEL_3_65_MS_44MHZ_CT - '1';
            end if;

          when wait_16us =>
            delay_v     := (others => '0');
            if select_clk80 = '1' then
              count_max_v := DEL_16_US_CT - '1';
            else
              count_max_v := DEL_16_US_44MHZ_CT - '1';
            end if;
              
          when delay_init_rx =>
            delay_v     := (others => '0');
            count_max_v := CONV_STD_LOGIC_VECTOR (33, 15);
            
          when search_sfd =>
            delay_v     := (others => '0');
            if select_clk80 = '1' then
              count_max_v := DEL_144_US_CT - '1';
            else
              count_max_v := DEL_144_US_44MHZ_CT - '1';
            end if;
             
            
          when rampdown_delay =>
            delay_v     := (others => '0');
            count_max_v := DEL_1_US_CT - '1';


          when others =>
            delay_v     := (others => '1');
            count_max_v := (others => '0');
            
        end case;
      
      elsif agc_bb_state = continue_reception_11a or agc_bb_state = rampdown_delay then
        if reload_count = '1' then
          delay_v     := (others => '0');
          count_max_v := DEL_1_US_CT - '1';
        end if;
      end if;

      if (delay_v) < (count_max_v) then
        delay_v := (delay_v) + 1;

        if delay_v = count_max_v then
          delay_over  <= '1';
          count_max_v := (others => '0');
          --        delay_v      := (others => '0');
        end if;
      end if;

      if delay_v = count_max2_v then
        delay_over2 <= '1';
        count_max2_v  := (others => '0');
      elsif delay_v = count_max3_v then
        delay_over3 <= '1';
        count_max3_v  := (others => '0');
      end if;

      if phy_rxstartend_ind = '1' and phy_rxstartend_ind_ff1 = '0' then
        packet_length_ff1 <= packet_length;  -- resynch 44 MHz to 80 MHz data
      else
        packet_length_ff1 <= (others => '0');
      end if;

      if conv_integer (packet_length_ff1) /= 0 then
        if select_clk80 = '1' then
          big_count_max_v := ext(((unsigned(packet_length_ff1)+signed(reg_addestimdurb)) * US_to_80_MHZ_CT), 22);  --packet_length_ff1;
        else
          big_count_max_v := ext(((unsigned(packet_length_ff1)+signed(reg_addestimdurb)) * US_to_44_MHZ_CT), 22);  --packet_length_ff1;  
        end if;
        
        big_delay_v     := CONV_STD_LOGIC_VECTOR (1, 22);  -- one tick to set the delay
      elsif big_delay_v < big_count_max_v and
        (agc_bb_state = search_sfd or agc_bb_state = continue_reception_11b) then
        big_delay_v := big_delay_v + 1;
      elsif big_delay_v = big_count_max_v then
        big_delay_over <= '1';
        big_count_max_v  := (others => '0');
      end if;

      -- 


    end if; 

  end process time_wheel_p;


  --=---------------------------------------------------------------------------
  -- A S S I G N   G L O B A L   S I G N A L S
  --=---------------------------------------------------------------------------
-- ambit synthesis off
-- synopsys translate_off
-- synthesis translate_off
--  cca_busy_gbl           <= cca_busy_internal;
--  agc_bb_state_gbl       <= agc_bb_state;
--  phy_txstartend_req_gbl <= phy_txstartend_req;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on


  --=---------------------------------------------------------------------------
  -- A S S E R T I O N S 
  --=---------------------------------------------------------------------------


  -- The following assertion checks if the cca_flags is known

--   -- sugar property CCA_FLAG_UNKNOWN is never 
--   -- ((cca_flags = "XXXX01") and not (cca_flags = "000011")) 
--   -- @(falling_edge(cca_flags_marker));
--   -- sugar assert CCA_FLAG_UNKNOWN;

  
end RTL;
