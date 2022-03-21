

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of err_phasor is

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Scale T1 T2
  signal t1_scale_re         : std_logic_vector(5 downto 0);
  signal t1_scale_im         : std_logic_vector(5 downto 0);
  signal t2_scale_re         : std_logic_vector(5 downto 0);
  signal t2_scale_im         : std_logic_vector(5 downto 0);
  -- T1 * T2
  signal t1_mult_t2_re       : std_logic_vector(12 downto 0);
  signal t1_mult_t2_im       : std_logic_vector(12 downto 0);
  -- Truncature
  signal t1_mult_t2_shr4_re  : std_logic_vector(9 downto 0);
  signal t1_mult_t2_shr4_im  : std_logic_vector(9 downto 0);
  signal t1_mult_t2_trunc_re : std_logic_vector(7 downto 0);
  signal t1_mult_t2_trunc_im : std_logic_vector(7 downto 0);
  -- Accumulation
  signal re_acc              : std_logic_vector(12 downto 0);
  signal im_acc              : std_logic_vector(12 downto 0);
  -- Max Module Calc
  signal re_err_module       : std_logic_vector(12 downto 0);
  signal im_err_module       : std_logic_vector(12 downto 0);
  signal max_mod             : std_logic_vector(12 downto 0);  -- max of the 2 modules

--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -----------------------------------------------------------------------------
  -- Rescale T1 and T2
  -----------------------------------------------------------------------------
  -- ext is a fake extension that will only change (SVL(X downto 
  rescale_p: process (shift_param_i, t1coarse_im_i, t1coarse_re_i,
                      t2coarse_im_i, t2coarse_re_i)
  begin  -- process rescale_p
    case shift_param_i is
      when "000" =>
        t1_scale_re <= sat_signed_slv(t1coarse_re_i,dsize_g-6);
        t1_scale_im <= sat_signed_slv(t1coarse_im_i,dsize_g-6);
        t2_scale_re <= sat_signed_slv(t2coarse_re_i,dsize_g-6);
        t2_scale_im <= sat_signed_slv(t2coarse_im_i,dsize_g-6);

      when "001" =>
        t1_scale_re <= sat_signed_slv(ext(t1coarse_re_i(dsize_g-1 downto 1),dsize_g-1),dsize_g-7);
        t1_scale_im <= sat_signed_slv(ext(t1coarse_im_i(dsize_g-1 downto 1),dsize_g-1),dsize_g-7);
        t2_scale_re <= sat_signed_slv(ext(t2coarse_re_i(dsize_g-1 downto 1),dsize_g-1),dsize_g-7);
        t2_scale_im <= sat_signed_slv(ext(t2coarse_im_i(dsize_g-1 downto 1),dsize_g-1),dsize_g-7);

      when "010" =>
        t1_scale_re <= sat_signed_slv(ext(t1coarse_re_i(dsize_g-1 downto 2),dsize_g-2),dsize_g-8);
        t1_scale_im <= sat_signed_slv(ext(t1coarse_im_i(dsize_g-1 downto 2),dsize_g-2),dsize_g-8);
        t2_scale_re <= sat_signed_slv(ext(t2coarse_re_i(dsize_g-1 downto 2),dsize_g-2),dsize_g-8);
        t2_scale_im <= sat_signed_slv(ext(t2coarse_im_i(dsize_g-1 downto 2),dsize_g-2),dsize_g-8);
        
      when "011" =>
        t1_scale_re <= sat_signed_slv(ext(t1coarse_re_i(dsize_g-1 downto 3),dsize_g-3),dsize_g-9);
        t1_scale_im <= sat_signed_slv(ext(t1coarse_im_i(dsize_g-1 downto 3),dsize_g-3),dsize_g-9);
        t2_scale_re <= sat_signed_slv(ext(t2coarse_re_i(dsize_g-1 downto 3),dsize_g-3),dsize_g-9);
        t2_scale_im <= sat_signed_slv(ext(t2coarse_im_i(dsize_g-1 downto 3),dsize_g-3),dsize_g-9);

      when "100" =>
        t1_scale_re <= sat_signed_slv(ext(t1coarse_re_i(dsize_g-1 downto 4),dsize_g-4),dsize_g-10);
        t1_scale_im <= sat_signed_slv(ext(t1coarse_im_i(dsize_g-1 downto 4),dsize_g-4),dsize_g-10);
        t2_scale_re <= sat_signed_slv(ext(t2coarse_re_i(dsize_g-1 downto 4),dsize_g-4),dsize_g-10);
        t2_scale_im <= sat_signed_slv(ext(t2coarse_im_i(dsize_g-1 downto 4),dsize_g-4),dsize_g-10);

      when others => -- no need to saturate as all MSB are kept
        t1_scale_re <= t1coarse_re_i(dsize_g-1 downto dsize_g-6);
        t1_scale_im <= t1coarse_im_i(dsize_g-1 downto dsize_g-6);
        t2_scale_re <= t2coarse_re_i(dsize_g-1 downto dsize_g-6);
        t2_scale_im <= t2coarse_im_i(dsize_g-1 downto dsize_g-6);

    end case;  
  end process rescale_p;

  -----------------------------------------------------------------------------
  -- T1 * T2
  -----------------------------------------------------------------------------
   -- error signal generation : correlation product
  t1_mult_t2_re <=sxt(signed(t1_scale_re)*signed(t2_scale_re),13)
                 +sxt(signed(t1_scale_im)*signed(t2_scale_im),13);
                                                
  t1_mult_t2_im <=sxt(signed(t1_scale_re)*signed(t2_scale_im),13)
                 -sxt(signed(t1_scale_im)*signed(t2_scale_re),13);

  -- truncature : approximation : nearest val
  t1_mult_t2_shr4_re <= t1_mult_t2_re(12 downto 3) + '1'; -- 10 bits
  t1_mult_t2_shr4_im <= t1_mult_t2_im(12 downto 3) + '1'; -- 10 bits

  t1_mult_t2_trunc_re <= sat_signed_slv(ext(t1_mult_t2_shr4_re (9 downto 1),9),1);
  t1_mult_t2_trunc_im <= sat_signed_slv(ext(t1_mult_t2_shr4_im (9 downto 1),9),1);
  
   -----------------------------------------------------------------------------
  -- Accumulator
  -----------------------------------------------------------------------------
  -- Accumulate Results of mult
  accu_mult_p: process (clk, reset_n)
  begin  -- process accu_mult_p
    if reset_n = '0' then               -- asynchronous reset (active low)
      re_acc <= (others => '0');
      im_acc <= (others => '0');
      
    elsif clk'event and clk = '1' then  -- rising clock edge
      if start_of_symbol_i = '1' or init_i = '1' then
        re_acc <= (others => '0');
        im_acc <= (others => '0');      
      
      elsif data_valid_i = '1' then
        re_acc <=  re_acc + sxt(t1_mult_t2_trunc_re,13);
        im_acc <=  im_acc + sxt(t1_mult_t2_trunc_im,13);
      end if;
    end if;
  end process accu_mult_p;
 

  -----------------------------------------------------------------------------
  -- Determination of second scaling
  -----------------------------------------------------------------------------
  re_err_module <= abs(signed(re_acc));
  im_err_module <= abs(signed(im_acc));

  -- determine the max of re_err_module/im_err_module
  max_mod <= (re_err_module) when re_err_module > im_err_module
        else (im_err_module);

 
  -----------------------------------------------------------------------------
  -- Scale the accumulation
  -----------------------------------------------------------------------------
  shift_p: process (im_acc, max_mod, re_acc)
    variable re_shr : std_logic_vector(11 downto 0);
    variable im_shr : std_logic_vector(11 downto 0);
  begin  -- process shift_p
    if max_mod(12 downto 10) = "000" then
      -- Saturation only
      re_err_phasor_acc_o <= sat_signed_slv(re_acc,2);
      im_err_phasor_acc_o <= sat_signed_slv(im_acc,2);
    elsif max_mod(12 downto 11) = "00" then
      -- Saturation and rounding
      re_err_phasor_acc_o <= sat_round_signed_slv(re_acc,1,1);
      im_err_phasor_acc_o <= sat_round_signed_slv(im_acc,1,1);
    else
      -- Rounding only
      re_shr := re_acc(12 downto 1) + '1';
      im_shr := im_acc(12 downto 1) + '1';       
      re_err_phasor_acc_o <= re_shr(11 downto 1);
      im_err_phasor_acc_o <= im_shr(11 downto 1);
    end if;
  end process shift_p; 

end RTL;
