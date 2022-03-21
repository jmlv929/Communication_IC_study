

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of carrier_detect is
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal nb_accu   : std_logic_vector (5 downto 0);--NEW rev. 1.4 - was (3 downto 0)
  signal carrier_s : std_logic; -- carrier sense

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  -----------------------------------------------------------------------------
  -- Fast Carrier Detection
  -----------------------------------------------------------------------------
  -- A pulse is generated each time the a16m signal (autoccorelation) is higher
  -- than the level estimation. 
  fast_car_detect_p: process (clk, reset_n)
  begin  -- process fast_car_detect_p
    if reset_n = '0' then               -- asynchronous reset (active low)
      fast_carrier_s_o   <= '0';
      fast_99carrier_s_o <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
       if autocorr_enable_i = '1' and init_i = '0' then
         if a16m_data_valid_i = '1' then
        
          if a16m_i > at0_i then  -- unsigned comparison        
            -- Treshold Detection
            fast_carrier_s_o   <= '1';
          else
            fast_carrier_s_o   <= '0';
          end if;
        
          if a16m_i > at1_i then  -- unsigned comparison        
            -- Treshold Detection (99%)
            fast_99carrier_s_o <= '1';
          else
            fast_99carrier_s_o <= '0';
          end if; 
        end if;       
      else
        fast_carrier_s_o   <= '0';        
        fast_99carrier_s_o <= '0';                
      end if;
    end if;
  end process fast_car_detect_p;

  -----------------------------------------------------------------------------
  -- Carrier Detection
  -----------------------------------------------------------------------------
  -- Accumulate the nb of time that the a16m > at1. When this nb reachs a
  -- treshold DETTHR, set the carrier_s_o.
  car_detect_p: process (clk, reset_n)
  begin  -- process car_detect_p
    if reset_n = '0' then             -- asynchronous reset (active low)
      carrier_s <= '0';
      nb_accu     <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      if init_i = '1' then
        -- init
        nb_accu <= (others => '0');
        carrier_s <= '0';

      else
        -- Accumulate       
        if    a16m_data_valid_i = '1'
          and autocorr_enable_i = '1'
          and cs_accu_en        = '1'    -- NEW rev. 1.4         
          and a16m_i            >  at1_i -- unsigned comparison
          and nb_accu          /= detthr_reg_i then
           
          nb_accu  <=  nb_accu + '1';
          
        end if;

        -- Compare to treshold DETTHR
        if nb_accu = detthr_reg_i then
          carrier_s <= '1';
        else
          carrier_s <= '0';          
        end if;
      end if;
    end if;
  end process car_detect_p;  

  -- Output linking
  carrier_s_o <= carrier_s;

end RTL;
