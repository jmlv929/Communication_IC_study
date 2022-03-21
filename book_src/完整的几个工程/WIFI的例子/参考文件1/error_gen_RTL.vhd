

--------------------------------------------------------------------------------
-- Architecture
--------------------------------------------------------------------------------
architecture RTL of error_gen is

  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  -- Signals for multiplication of demodulated data with demapped data conjugate
  signal neg_data_i    : std_logic_vector(datasize_g-1 downto 0); -- (- data_i).
  signal neg_data_q    : std_logic_vector(datasize_g-1 downto 0); -- (- data_q).
  -- Detected error, cartesian coordonates.
  signal error_cart_i  : std_logic_vector(datasize_g-1 downto 0); -- real part.
  signal error_cart_q  : std_logic_vector(datasize_g-1 downto 0); -- Imaginary part
 
  signal phase_error_o : std_logic_vector(errorsize_g-1 downto 0); -- Error detected.
--------------------------------------------------------------------------------
-- Architecture Body
--------------------------------------------------------------------------------
begin
  
  -- error_cart = input data * demap_data conjugate.
  neg_data_i <= not(data_i) + '1';
  neg_data_q <= not(data_q) + '1';
  
  with demap_data select
    error_cart_i <=
      data_i      when "00",
      data_q      when "01",
      neg_data_q  when "10",
      neg_data_i  when others;

  with demap_data select
    error_cart_q <=
      data_q      when "00",
      neg_data_i  when "01",
      data_i      when "10",
      neg_data_q  when others;
           
                  
  -- Block for cordic algorithm: the angle output belongs to [-pi/2, pi/2].
  cordic_vect_1 : cordic_vect
    generic map (
      datasize_g          =>  datasize_g,
      errorsize_g         =>  errorsize_g,
      scaling_g           =>  0 -- no scaling needed
      
      )
    port map (
      -- clock and reset.
      clk                 => clk,
      reset_n             => reset_n,
      --
      load                => symbol_sync,  -- Load input values.
      x_in                => error_cart_i, -- Real part in.
      y_in                => error_cart_q, -- Imaginary part in.
      --
      angle_out           => phase_error_o,  -- Angle out.
      cordic_ready        => error_ready   -- Angle ready.
      );
      
      
  phase_error <= phase_error_o when enable_error='1' else (others=> '0');
    
end RTL;
