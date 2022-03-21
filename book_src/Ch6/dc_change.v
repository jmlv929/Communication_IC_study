DC(1)={Amp_adj，5'd0}  @AD_EN_core上升沿
dcreg=DC(N-1)
If GAIN_change  & 增益变化后的32个clock
   DC=dcreg+(Signal_RF-dcreg)/8
else  if  DC_est_Change
    DC=dcreg+(Signal_RF-dcreg)/256
  else 
    DC(N)= dcreg+(Signal_RF-dcreg)/32;
  end
end

S_r =  real(Signal)   - Ang*imag(Signal);
S_i =  imag(Signal)*Amp - Ang*real(Signal) *Amp;
Signal = S_r + j*S_i;
