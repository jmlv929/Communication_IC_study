function [k, a] = PhaseLine(angle, Wk, Wa, MaxI)
  for i=1:4
    ang(i) = angle(i) - angle(MaxI);
    if ang(i) > 1 %这一部分是将信号限到[-1，+1]之间
      ang(i) = ang(i) - 2*1;
    elseif ang(i) < - 1
      ang(i) = ang(i) + 2*1;
    end
  end
  a = sum(ang.*Wa) + angle(MaxI);
  if a > 1  % 这一部分是将信号限到[-1，+1]之间
    a = a - 2*1;
  elseif a < - 1
    a = a + 2*1;
  end

  k = sum(ang.*Wk);
  a=num2fixpt(a, sfix(12), 2^(-12+1), 'Nearest', 'on');
  k=num2fixpt(k, sfix(10), 2^(-12), 'Nearest', 'on');
 