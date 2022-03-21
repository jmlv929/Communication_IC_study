

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of cordic_vect is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant ZEROS_CT : std_logic_vector(datasize_g downto 0) := (others => '0');
  constant ONES_CT  : std_logic_vector(datasize_g downto 0) := (others => '1');
  -- Part of 001111111...  = pi/2 scaled
  constant PI2_SCALED_CT : std_logic_vector(errorsize_g-2 downto 0) := (others =>'1');
  -- Part of 110000000...  = - pi/2 scaled
  constant MPI2_SCALED_CT : std_logic_vector(errorsize_g-2 downto 0) := (others =>'0');
  

  ------------------------------------------------------------------------------
  -- Types
  ------------------------------------------------------------------------------
  type ArrayOfSLVdsize is array (natural range <>) of 
                                     std_logic_vector(datasize_g downto 0);

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- arctan value from look-up table.
  signal arctan          : std_logic_vector(errorsize_g-1 downto 0);
  -- arctan value extended to align comas with z_n data.
  signal arctan_ext      : std_logic_vector(errorsize_g downto 0);
  -- The index value is the current step n.
  signal index           : std_logic_vector(4 downto 0);
  signal index_int       : integer range datasize_g downto 0;
  -- x, y and z values at time n and n+1.
  signal x_n             : std_logic_vector(datasize_g downto 0);
  signal y_n             : std_logic_vector(datasize_g downto 0);
  signal x_n1            : std_logic_vector(datasize_g downto 0);
  signal y_n1            : std_logic_vector(datasize_g downto 0);
  signal z_n             : std_logic_vector(errorsize_g downto 0); 
  signal z_n1            : std_logic_vector(errorsize_g downto 0); 
  signal z_n1_sat        : std_logic_vector(errorsize_g downto 0); 
  signal s_n             : std_logic; -- sign of z_n.
  -- x, y and z steps from time n to time n+1.
  signal xn_step         : std_logic_vector(datasize_g downto 0); 
  signal yn_step         : std_logic_vector(datasize_g downto 0); 
  signal zn_step         : std_logic_vector(errorsize_g downto 0); 
  -- x and y values shifted of n bits.
  signal xn_shift        : std_logic_vector(datasize_g downto 0); 
  signal yn_shift        : std_logic_vector(datasize_g downto 0); 
  signal xn_shift_array  : ArrayOfSLVdsize(datasize_g downto 0); 
  signal yn_shift_array  : ArrayOfSLVdsize(datasize_g downto 0); 

  signal angle_ready     : std_logic;
  signal angle_ready_ff  : std_logic;

  -- Signals for Synopsys work around (HDL-123)
  signal temp_syn_y            : std_logic_vector(datasize_g downto 0);

  -- Define the min of datasize_g/errorsize_g
  signal min_size              : integer;

  -- Memorize null x_in and y_in
  signal input_eq_zero : std_logic;

  
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin

  -- Result Saturation
  -- When the cordic is scaled, there is a risk of saturation, with low value
  -- at pi/2, (eg :  [0,13] can give 99 deg). If it occurs, the result is saturated
  -- at 90 deg(-1) , which is more accurate.
  sat_scaled_gen: if scaling_g = 1 generate
    z_n1_sat <= "00" & PI2_SCALED_CT when z_n1(z_n1'high) = '0' and z_n1(z_n1'high-1) = '1'-- more than  90 deg => 90 deg
           else "11" &MPI2_SCALED_CT when z_n1(z_n1'high) = '1' and z_n1(z_n1'high-1) = '0'-- less than -90 deg => -90 deg
           else z_n1;   
  end generate sat_scaled_gen;

  no_sat_gen: if scaling_g = 0 generate
    z_n1_sat <= z_n1;   
  end generate no_sat_gen;

  
  -- Assign output port.
  -- angle(0, 0) = 0 for compatibility with matlab simulations.
  -- can be removed
  output_p: process(input_eq_zero, z_n1_sat)
  begin
    if input_eq_zero = '1' then
      angle_out <= (others => '0');
    else
      angle_out <= z_n1_sat(errorsize_g-1 downto 0);
    end if;
  end process output_p;


  
  -- Define the min of datasize_g/errorsize_g, which will be the nb of
  -- iterations. Indeed, no need to iterate more, when errorsize_g < datasize_g,
  -- as only zeros are added during the last iterations.
  min_size <= datasize_g when datasize_g  < errorsize_g else errorsize_g; 
  
  -- This process increases the index from 0 to dsize_g-1.
  -- The value in the index is the iteration number ('n').
  control_p: process (clk, reset_n)
  begin
    if reset_n = '0' then
      index_int      <= 0;
      angle_ready    <= '0';
      angle_ready_ff <= '0';
    elsif clk'event and clk = '1' then
      angle_ready_ff <= angle_ready;

      if load = '1' then              -- Reset index when a new value is loaded.
        angle_ready    <= '0';
        index_int      <= 0;       
      else
        if (index_int = min_size - 1) then
          angle_ready <= '1';
        end if;
        if (index_int <= min_size - 1) then
          index_int <= index_int + 1;  -- Increase index from 0 to min_size.          
        end if;
      end if;
    end if;
  end process control_p;
  cordic_ready <= angle_ready and not angle_ready_ff;

  -- Remaining angle sign, to determine direction of next microrotation.
  s_n <= y_n(y_n'high);
  
  -- Extend sign bit of arctan look-up table value.
  arctan_ext <=  "000" & arctan(errorsize_g-1 downto 2);
  
  -- Calculate next angle microrotation:
  --   z_n1 = z_n - s_n*arctan(2^-n)  with  s_n = -1  if z_n <  0 
  --                                               1  if z_n >= 0
  with s_n select
    zn_step <=
      arctan_ext             when '0',
      not(arctan_ext) + '1'  when others;
  z_n1 <= z_n + zn_step;

  -- Accu: load input value or store microrotation result.
  accu_p: process (clk, reset_n)
  begin
    if reset_n = '0' then
      x_n <= (others => '0');
      y_n <= (others => '0');
      z_n <= (others => '0');
      input_eq_zero <= '0';
    elsif clk'event and clk = '1' then
      if load = '1' then
        -- Load angle init value.
        x_n <= '0' & x_in;
        y_n <= sxt(y_in,datasize_g+1);
        z_n <= (others => '0');
        -- Memorize inputs eq to zero
        if x_in = ZEROS_CT(datasize_g-1 downto 0)
        and y_in = ZEROS_CT(datasize_g-1 downto 0) then
          input_eq_zero <= '1';
        else
          input_eq_zero <= '0';
        end if;

      else                             -- Store microrotation result.
        x_n <= x_n1;
        y_n <= y_n1;
        z_n <= z_n1;                   -- Angle microrotation.
      end if;    
    end if;
  end process accu_p;
  

  -- Microrotation to calculate x_n1 uses the value yn_shift = y_n*2^-n.
  -- The value n is stored in the index signal.
  shifty_p: process(index_int, yn_shift_array)
  begin
    yn_shift <= yn_shift_array(index_int);
  end process shifty_p;


  -- Microrotation to calculate y_n1 uses the value xn_shift = x_n*2^-n.
  -- The value n is stored in the index signal.
  shiftx_p: process(index_int, xn_shift_array)
  begin
    xn_shift <= xn_shift_array(index_int);
  end process shiftx_p;


  -- Calculate next X value:
  -- x_n1 = x_n - s_n*(2^-n)*y_n.
  with s_n select
    xn_step <=
      yn_shift             when '0',  
      not(yn_shift) + '1'  when others;
  x_n1 <= x_n + xn_step;
      
  -- Calculate next Y value:
  -- y_n1 = y_n + s_n*(2^-n)*x_n.
  with s_n select
    yn_step <=
      xn_shift             when '1',
      not(xn_shift) + '1'  when others;
  y_n1 <= y_n + yn_step;


  xn_shift_array(0) <=  x_n;
  yn_shift_array(0) <=  y_n;

  -- Use temp_syn signals for Synopsys work-around.
  temp_syn_y <= (others => y_n(datasize_g));
  array_gen: for i in 1 to datasize_g generate
  -- xn is always positive - MSB to add will always be 0 .
    xn_shift_array(i)(datasize_g downto datasize_g-i+1) <= ZEROS_CT(datasize_g downto datasize_g-i+1);
    xn_shift_array(i)(datasize_g-i downto 0) <=  x_n(datasize_g downto i);

  --  yn_shift_array(i)(datasize_g downto datasize_g-i+1) <= (others => y_n(datasize_g));
    yn_shift_array(i)(datasize_g downto datasize_g-i+1) <= temp_syn_y(datasize_g downto datasize_g-i+1);
    yn_shift_array(i)(datasize_g-i downto 0) <=  y_n(datasize_g downto i);
  end generate array_gen;
   
  ------------------------------------------------------------------------------
  -- Port map
  ------------------------------------------------------------------------------
  -- conv index_into into std_logic_vector
  index <= conv_std_logic_vector(index_int,5);
  arctan_lut_1 : arctan_lut
    generic map (
      dsize_g    => errorsize_g, -- To align comas.
      scaling_g  => scaling_g -- 1:Perform scaling (pi/2 = 2^errosize_g=~ 01111....) 
      )
    port map (
      index   => index,
      arctan  => arctan
      );

------------------------------------------------------------------------------
-- Global Signals for test
------------------------------------------------------------------------------
-- ambit synthesis off
-- synopsys translate_off
-- synthesis translate_off
--  global_gen : if datasize_g=14 generate
--  x_n_gbl <= x_n;
--  y_n_gbl <= y_n;
--  end generate global_gen;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on

end RTL;
