

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of deserializer is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant TRANS_VAL_BPSK_CT  : std_logic_vector(2 downto 0):= "111";
  -- in bpsk there are 8 shifts to perform
  constant TRANS_VAL_QPSK_CT  : std_logic_vector(2 downto 0):= "011";
  -- in qpsk there are 4 shifts to perform
  constant TRANS_VAL_CCK55_CT  : std_logic_vector(2 downto 0):= "001";
  -- in cck 5.5there are 2 shifts to perform
  constant TRANS_VAL_CCK11_CT  : std_logic_vector(2 downto 0):= "000";
  -- in cck 11 there are 1 shifts to perform

  -- mode indication (for rec_mode)
  constant BPSK_MODE_CT       : std_logic_vector (1 downto 0) := "00";
  constant QPSK_MODE_CT       : std_logic_vector (1 downto 0) := "01";
  constant CCK55_MODE_CT      : std_logic_vector (1 downto 0) := "10";
  constant CCK11_MODE_CT      : std_logic_vector (1 downto 0) := "11";
  

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal deseria_reg        : std_logic_vector (6 downto 0);
  --                          deseria register
  signal rec_mode_reg       : std_logic_vector (1 downto 0);
  --                          rec_mode register
  signal trans_count        : std_logic_vector (2 downto 0);
  --                          count the number of shift operation to execute  
  signal trans_c_init_val   : std_logic_vector (2 downto 0);
  --                          nb of shift op to perform
  signal last_deseria_activate : std_logic;
  --                          used to know the first act of the block

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  ------------------------------------------------------------------------------
  -- Deserialization process
  ------------------------------------------------------------------------------
  deseria_proc:process (clk, reset_n)
  begin
    if reset_n ='0' then
      deseria_reg      <= (others => '0');     -- reset register
    
    elsif (clk'event and clk = '1') then
      if deseria_activate = '1' and symbol_sync = '1' then          
        -- shift op
        case rec_mode_reg is

          ---------------------------------------------------------------------
          -- BPSK Mode
          ---------------------------------------------------------------------
          when BPSK_MODE_CT  =>
            deseria_reg(6)          <= d_from_diff_dec(0);
            deseria_reg(5 downto 0) <= deseria_reg(6 downto 1);
            
          ---------------------------------------------------------------------
          -- QPSK Mode
          ---------------------------------------------------------------------
          when QPSK_MODE_CT  =>
            deseria_reg(5 downto 4) <=  d_from_diff_dec;
            deseria_reg(3 downto 2) <= deseria_reg(5 downto 4);
            deseria_reg(1 downto 0) <= deseria_reg(3 downto 2);

          ---------------------------------------------------------------------
          -- CCK55 Mode
          ---------------------------------------------------------------------   
          when CCK55_MODE_CT =>
            deseria_reg(3 downto 0) <= d_from_cck_dem(4) & d_from_cck_dem(0)
                                      & d_from_diff_dec;
          ---------------------------------------------------------------------
          -- CCK11 Mode
          ---------------------------------------------------------------------
          when others => null;
        end case;
      end if;
    end if;
  end process;
  
  ------------------------------------------------------------------------------
  -- Counter process
  ------------------------------------------------------------------------------
  counter_proc : process (clk, reset_n)
  begin
    if reset_n = '0' then
      trans_count           <= (others => '1');
      phy_data_ind          <= '0';
      last_deseria_activate <= '0';
      rec_mode_reg          <= (others => '0');

    elsif (clk'event and clk = '1') then
      phy_data_ind          <= '0';
      last_deseria_activate <= deseria_activate;

      if deseria_activate = '1' then
        if symbol_sync = '1' then
          trans_count <= trans_count - '1';

          if trans_count = "000" or packet_sync ='1'
            or (last_deseria_activate = '0' and deseria_activate = '1') then
            -- last byte finished - initialyze counter
            trans_count <= trans_c_init_val;
            rec_mode_reg <= rec_mode;
          elsif trans_count = "001" then
            -- last bit of the byte arrives - inform the Bup
            phy_data_ind <= '1';
          end if;

          -- in CCK 11 MHz, 1 byte per chip sync.
          if rec_mode = CCK11_MODE_CT then
            phy_data_ind <= '1';
          end if;
        end if;
      else
        trans_count   <= (others => '1');
        rec_mode_reg  <= (others => '0');
      end if;
    end if;
  end process;

  -- initial value of the counter (checked directely on rec_mode)
  with rec_mode select
    trans_c_init_val <=
    TRANS_VAL_BPSK_CT  when BPSK_MODE_CT,
    TRANS_VAL_QPSK_CT  when QPSK_MODE_CT,
    TRANS_VAL_CCK55_CT when CCK55_MODE_CT,
    TRANS_VAL_CCK11_CT when others;  -- CCK11_MODE_CT

  byte_sync <= '1' when symbol_sync = '1' and
               (trans_count = "000" or rec_mode_reg =CCK11_MODE_CT)
               else '0';
  -- as there should be glitches on transition of trans_count
  -- byte_sync must be used only to generate clocked signals !
               
 

  ------------------------------------------------------------------------------
  -- wiring....
  ------------------------------------------------------------------------------
  -- number of shift op to perform

  with rec_mode_reg select
    deseria_out <=
    d_from_diff_dec(0) & deseria_reg                when BPSK_MODE_CT,
    d_from_diff_dec & deseria_reg (5 downto 0)      when QPSK_MODE_CT,
    d_from_cck_dem(4) & d_from_cck_dem(0) & d_from_diff_dec
                      & deseria_reg(3 downto 0)     when CCK55_MODE_CT,
    d_from_cck_dem & d_from_diff_dec                when others;--CCK11_MODE_CT;

end RTL;
