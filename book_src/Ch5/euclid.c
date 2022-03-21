if (deg_R > deg_Q ){
  cur_A = ABuf(8);
  if (cnt_l > (8-abs(deg_R-deg_Q)))
    cur_U = 0;
  else
    cur_U = UBuf(abs(8-abs(deg_R-deg_Q)));
} else if (deg_R == deg_Q) {
  cur_A = ABuf(8);
  cur_U = UBuf(8);
} else {
  if (cnt_l > 8-abs(deg_R-deg_Q))  /* the last byte.*/
    cur_A = 0;
  else
    cur_A = ABuf(abs(8-abs(deg_R-deg_Q)));
  cur_U = UBuf(8);
}


if (a=0 or b=0)
  next_A=Abuf(8);
else
  next_A=new_A;

if (a=0 or b=0)
  next_U=UBuf(8);
else if(deg_R>=deg_Q)
  next_U=UBuf(8);
else
  next_U=ABuf(8);

if (deg_R < deg_Q) {/* Omega = R(x), Delta = A(x) */
  for (i=0; i<=8; i++) {
    if (i <= 7)
      Omega(7-i) = RBuf(15-i);
    else
      Omega(i) = 0;
  }
  Delt = ABuf;
} else { /* else Omega = Q(x), Delt = U(x);*/
  for (i=0; i<=8; i++) {
    if (i <= 7)
      Omega(7-i) = QBuf(15-i);
    else
      Omega(i) = 0;
  }
  Delt = UBuf;
}