

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of iq_mismatch is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal data_abs_i       : std_logic_vector(6 downto 0); -- abs(data_in_i)
  signal data_abs_q       : std_logic_vector(6 downto 0); -- abs(data_in_q)

  signal data_rescal_i    : std_logic_vector(6 downto 0); -- data I after Rescaling
  signal data_rescal_q    : std_logic_vector(6 downto 0); -- data Q after Rescaling

  signal acc_i_p0         : std_logic_vector(17 downto 0); -- accumulated data I (n-1)
  signal acc_q_p0         : std_logic_vector(17 downto 0); -- accumulated data Q (n-1)
  
  signal acc_i_p1         : std_logic_vector(17 downto 0); -- accumulated data I (n)
  signal acc_q_p1         : std_logic_vector(17 downto 0); -- accumulated data Q (n)

  signal iq_gain          : std_logic_vector(6 downto 0); -- gain for the multipliction.
  signal iq_gain_sat      : std_logic_vector(6 downto 0); -- gain saturated.
  
  signal data_i_comp      : std_logic_vector(7 downto 0); -- data Q after compensation
  signal data_q_comp      : std_logic_vector(7 downto 0); -- data Q after compensation
  signal data_q_comp_inv  : std_logic_vector(7 downto 0); -- not (data Q) after compensation

  signal data_in_q_abs    : std_logic_vector(7 downto 0); -- abs(data Q) for

  signal rescaling        : std_logic_vector(2 downto 0); -- data Q after 
    
  --signal divisor_s       : std_logic_vector(17 downto 0); -- divisor  --- For debug only
  --signal new_dividend_s  : std_logic_vector(17 downto 0); -- divident --- For debug only
  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin


--
--                                                  acc_i_p0                       
--            data_abs_i                        ,-----------------.         
--                |  ____________               |          ______ |
-- data_i |   |   | |           |data_rescal_i _|__       |     | |
--  ------|ABS|-----| Rescaling |-------------|_+_|-------|Delay|-----,    
--        |   |     |___________|                acc_i_p1 |_____|    _|__ 
--                                                                  |   |iq_gain
--                                                  acc_q_p0        | / |-------          
--            data_abs_q                        ,-----------------. |___|       
--                |  ____________               |          ______ |  | 
-- data_q |   |   | |           |data_rescal_q _|__       |     | |  |
--  ------|ABS|-----| Rescaling |-------------|_+_|-------|Delay|----'    
--        |   |     |___________|                acc_q_p1 |_____|
--
--
--
--         ______       
-- data_i |     |  data_i_comp 
--  ------|Delay|---------------> data_out_i
--        |_____|   
--
-- iq_gain
--  --------,
--         _|__       
-- data_q |   |  data_q_comp 
--  ------| X |---------------> data_out_q
--        |___|   
--

  -------------------------------------------------------------------------------
  -- Absolute value of data_in_i and data_in_q with overflow detect.
  -------------------------------------------------------------------------------


  data_abs_i   <=   data_in_i(6 downto 0) when data_in_i(7) = '0'        else    
                    (others=>'1') when data_in_i(6 downto 0) = "0000000" else    
                    not data_in_i(6 downto 0) + '1';                             

  data_abs_q   <=   data_in_q(6 downto 0) when data_in_q(7) = '0'        else    
                    (others=>'1') when data_in_q(6 downto 0) = "0000000" else    
                    not data_in_q(6 downto 0) + '1';                             


  -- Input Rescaling
  ------------------

  with rescaling select
    data_rescal_q(6 downto 0) <= data_abs_q(6 downto 0)           when "000",
                                 "0" & data_abs_q(6 downto 1)     when "001",
                                 "00" & data_abs_q(6 downto 2)    when "010",
                                 "000" & data_abs_q(6 downto 3)   when "011",
                                 "0000" & data_abs_q(6 downto 4)  when "100",
                                 "00000" & data_abs_q(6 downto 5) when "101",
                                 "000000" & data_abs_q(6)         when "110",
                                 data_abs_q(6 downto 0)           when others;

  with rescaling select
    data_rescal_i(6 downto 0) <= data_abs_i(6 downto 0)           when "000",
                                 "0" & data_abs_i(6 downto 1)     when "001",
                                 "00" & data_abs_i(6 downto 2)    when "010",
                                 "000" & data_abs_i(6 downto 3)   when "011",
                                 "0000" & data_abs_i(6 downto 4)  when "100",
                                 "00000" & data_abs_i(6 downto 5) when "101",
                                 "000000" & data_abs_i(6)         when "110",
                                 data_abs_i(6 downto 0)           when others;

  -- Accumulator
  --------------

  acc_i_p1 <= acc_i_p0 + data_rescal_i(6 downto 0);
  acc_q_p1 <= acc_q_p0 + data_rescal_q(6 downto 0);
  

  acc_p : process (clk,reset_n)
  variable cnt : std_logic;
  begin
    if reset_n='0' then
      acc_i_p0 <= (others => '0');
      acc_q_p0 <= (others => '0');
      cnt := '0';
      rescaling <= "000";      
    elsif clk'event and clk='1' then
      if cnt='0' and iq_estimation_enable = '1' then      
        acc_i_p0 <= acc_i_p1;
        acc_q_p0 <= acc_q_p1;
      end if;
      if iq_estimation_enable = '0' and iq_compensation_enable   = '0' then    
        acc_i_p0 <= (others => '0');
        acc_q_p0 <= (others => '0');
        rescaling <= "000"; 
      end if;  
      -- division / 2;
      if acc_q_p0(17)='1' then
        rescaling <= rescaling + '1';
        acc_i_p0 <= '0' & acc_i_p0(17 downto 1);
        acc_q_p0 <= '0' & acc_q_p0(17 downto 1);
      elsif acc_i_p0(17)='1' then
        rescaling <= rescaling + '1';
        acc_i_p0 <= '0' & acc_i_p0(17 downto 1);
        acc_q_p0 <= '0' & acc_q_p0(17 downto 1);
      end if;
        
      cnt := not cnt;  
    end if;
  end process acc_p;   
      
  -- Divisor
  -----------
  --
  -- divide  acc_i_p0 by acc_q_p0
  --
  div_p : process (clk,reset_n)
  variable cnt           : integer; -- counter
  variable divisor       : std_logic_vector(17 downto 0); -- divisor
  variable new_dividend  : std_logic_vector(17 downto 0); -- divident (updated
                                                          -- at each iteration
  variable rest          : std_logic_vector(17 downto 0); -- rest of the division
  variable result        : std_logic_vector(17 downto 0); -- result
  begin
    --divisor_s      <= divisor;      --------------- !! For debug only !!
    --new_dividend_s <= new_dividend; --------------- !! For debug only !!
    
    if reset_n='0' then
      rest := (others => '0');
      cnt := 0;
      divisor  := (others => '0');
      new_dividend  := (others => '0');
      rest  := (others => '0');
      iq_gain <= (others => '0');
      result := (others => '0');
    elsif clk'event and clk='1' then
      
      if cnt > 36 then
        
        if cnt = 37 then          
          new_dividend := acc_i_p0;
          divisor      := acc_q_p0;
          result       := (others => '0');
          rest         := (others => '0');

        end if;
      
        if new_dividend >= divisor then
          rest      := new_dividend - divisor;
          result(0) := '1';
        else 
          result(0) := '0';
          rest      := new_dividend;
        end if;
      
        new_dividend(17 downto 0) :=   rest(16 downto 0) & '0';
        result(17 downto 0)       := result(16 downto 0) & '0';
        cnt := cnt + 1;

        if cnt = 44 then    
          iq_gain <= result(7 downto 1);
          cnt     := 0;
        end if;
        
      else
        cnt := cnt + 1;
      end if;
                        
      if iq_estimation_enable='0' then
        cnt := 0;
      end if;
        
     -- Compensation bypass
     if iq_compensation_enable = '0' then   
       iq_gain <=  "1000000";
     end if;  

    end if;
  end process div_p; 
  ----------------------------------------------------------------------------- 
  --Saturation of iq_gain : 0.75 < iq_gain_sat < 1.325   
  -----------------------------------------------------------------------------     
  -- Gain saturation

    iq_gain_sat  <= "0110000" when iq_gain < "0110000" else 
                    "1011000" when iq_gain > "1011000" else 
                    iq_gain;

  -----------------------------------------------------------------------------
  -- Multipication.
  -----------------------------------------------------------------------------
  -- Multiply data_in_q by iq_gain_sat.
  --
    
  multi_p : process (clk,reset_n)
   
   variable cnt : std_logic; -- counter
   variable interm_result_q : std_logic_vector(15 downto 0); -- divisor 
  
  begin   
    if reset_n='0' then
      cnt                  := '0';
      interm_result_q      := (others => '0');                 
      data_out_q           <= (others => '0');
      data_out_i           <= (others => '0'); 
  
    elsif clk'event and clk='1' then 
      
       cnt := not cnt;
       
       if cnt = '1' then
         interm_result_q   := signed(data_in_q) * unsigned(iq_gain_sat);
         data_out_q        <= sat_signed_slv(interm_result_q(15 downto 6),2);
         data_out_i        <= data_in_i;
       end if;
  
    end if;
  end process multi_p;     

  -----------------------------------------------------------------------------
  -- Output of status register iq_gain_sat_stat.
  -----------------------------------------------------------------------------
  iq_gain_sat_stat_p: process (clk, reset_n)
  begin
    if reset_n = '0' then
      iq_gain_sat_stat <= (others => '0');
    elsif clk'event and clk = '1' then
      iq_gain_sat_stat <= iq_gain_sat;
    end if;
  end process iq_gain_sat_stat_p;
  
  ------------------------------------------------------------------------------
  -- Global Signals for test
  ------------------------------------------------------------------------------
-- ambit synthesis off
-- synopsys translate_off
-- synthesis translate_off 
--  acc_i_p0_gbl <= acc_i_p0;
--  acc_q_p0_gbl <= acc_q_p0;
--  iq_gain_sat_gbl <= iq_gain_sat;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on
end RTL;
