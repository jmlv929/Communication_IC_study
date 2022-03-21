function [ma,ua,datax,datay,deltaf,fai0,syn_pos] = ...
     demod_timing4v5(xt, yt,osr, SYN0, SYN1, Tchip)
SYN0 = 1-2*SYN0;
xn = [xt(1+osr), xt(osr/2+1), xt(1)];
yn = [yt(1+osr), yt(osr/2+1), yt(1)];
time_error0 = 0; pace_ordinate = 0; w = 2/osr; ita = 0.1;
c0 = 0.99;
k = 64; c1 = 0.0014/k; c2 = 1*10^(-6)/k;

ma = zeros(1,length(xt)*2/osr);
syn0_buff0 = zeros(1,63*63);
ua = zeros(1,length(xt)*2/osr);
datax = zeros(1,8256);
datay = zeros(1,8256);
zr = zeros(1,17921);
r = zeros(1,3969);
r0 = zeros(1,10);
tmp0 = zeros(1,3000);

deltaf = 0;
fai0 = 0;
syn_pos = 0;
sym_count = 0;
deltaf_fai = 0;
state = 0;
mm = 0;
fh = -1;
mk = osr+1;
while mk<length(xt)-osr

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 定时部分
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ita = ita-w;
%   mk = mk+1;
%   if ita<=w
    time_error = xn(2)*(xn(1)-xn(3))+yn(2)*(yn(1)-yn(3)); % 同步定时误差提取
    fh = fh*(-1);
    time_error = time_error*fh;
    pace_ordinate = c0 * pace_ordinate + c1 * (time_error - time_error0) + c2 * time_error;
    w = w + pace_ordinate;     % if pace_ordinate>0, 内插位置提前
    time_error0 = time_error;

    u = ita/w;%分数间隔
    if u>1
      u = u-1;
      ita = ita - w;
      mk = mk+1;
    elseif u<0
      u = u+1;
      ita = ita + w;
      mk = mk-1;
    end

    x = [xt(mk+2),xt(mk+1),xt(mk),xt(mk-1)];
    y = [yt(mk+2),yt(mk+1),yt(mk),yt(mk-1)];

    a1 = 0.5*x(1) - 0.5*x(2) - 0.5*x(3) + 0.5*x(4);
    a2 = -0.5*x(1)+ 1.5*x(2) - 0.5*x(3) - 0.5*x(4);
    a3 = x(3);
    xk = (a1*u+ a2) *u + a3;
    a1 = 0.5*y(1) - 0.5*y(2) - 0.5*y(3) + 0.5*y(4);
    a2 = -0.5*y(1)+ 1.5*y(2) - 0.5*y(3) - 0.5*y(4);
    a3 = y(3);
    yk = (a1*u+ a2) *u + a3;

    mm = mm+1;
    ua(mm)=u;
    ma(mm) = mk;

    xn = [xk,xn(1:2)];
    yn = [yk,yn(1:2)];
    ita = ita-w+1; %求模运算
    mk = mk+1;

    % 防失锁模块
    if (w>3/osr) || (w<1/osr)
      ita = 1;
      w = 2/osr;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 解调部分
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if (fh==-1)
      switch state
        case 0 %利用SYN0进行帧捕获
          tmp = xk+j*yk;
          sym_count = sym_count+1;
          tmp0(sym_count) = tmp;
          % 频偏粗略前向估计
          if sym_count == 3000
            L0 = sym_count;
            N = 50;
            zr = tmp0.^2;
            for m = 1:N
              r0(m) = mean(zr(1+m:L0) .* conj(zr(1:L0-m)));
            end
            deltaf = angle(sum(r0))/(pi*(N+1)*Tchip)/2;
            tmp0 = tmp0 .* exp(-j*2*pi*deltaf*(1:sym_count)*Tchip);
            deltaf_fai = 2*pi*deltaf*sym_count*Tchip;
            syn0_buff0(969+1:3969) = tmp0;
          end
          if sym_count>3000
            deltaf_fai = deltaf_fai+2*pi*deltaf*Tchip;
            tmp = tmp * exp(-j*deltaf_fai);
            syn0_buff0(1:end-1) = syn0_buff0(2:end); % left-shift
            syn0_buff0(end) = tmp;
            rval0 = sum(syn0_buff0 .* SYN0);
            r(ceil(mm/2)) = abs(rval0);
            if sym_count>4000
              break;
            end
            if (abs(rval0)>1000)
%               plot(r)
              disp('SYN0 have been found');
              fprintf('mk=%d,',mk);
              fprintf('rval0=%5.1f\n',abs(rval0));
              state = 1;
              sym_count = 0;
              syn_pos = mk;
            end
          end
        case 1 %利用SYN1进行细频偏估计
          sym_count = sym_count+1;
          SYN1(sym_count)= 1-SYN1(sym_count)*2;
          zr(sym_count) = ((xk+j*yk) * SYN1(sym_count));
          if (sym_count == 17921)
            L0 = 17921;
            N = 50;
            % 自相关
            for m = 1:N
              r1(m) = mean(zr(1+m:L0) .* conj(zr(1:L0-m)));
            end
            %L&R method
            deltaf = angle(sum(r1(1:N)))/(pi*(N+1)*Tchip);

            % Initial Phase Estimation
            t = (0:17920)*Tchip;
            zr = zr.* exp(-j*2*pi*deltaf*t);
            fai0 = angle(mean(zr));
            deltaf_fai = 2*pi*deltaf*17920*Tchip;
            state = 2;
            sym_count = 0;
          end

        case 2
          deltaf_fai = deltaf_fai+2*pi*deltaf*Tchip;
          sym_count = sym_count+1;
          if sym_count>=(4096+32)
            state = 3;
            sym_count = 0;
          end
        case 3
          deltaf_fai = deltaf_fai+2*pi*deltaf*Tchip;
          tmp = (xk+j*yk) * exp(-j*deltaf_fai) * exp(-j*fai0);
          % 导频1
          if (sym_count>=1008) && (sym_count<(1008*3+48))
            if sym_count<(1008+48)
              tmp1(sym_count - 1007) = tmp;
            end
            if sym_count==(1008+48)
              fai1 = angle(mean(tmp1*1));
            end
            if sym_count>=(1008+48)
              tmp = tmp * exp(-j*fai1);
            end
          end
          % 导频2
          if (sym_count>=(3*1008+48)) && (sym_count<(1008*5+48*2))
            if sym_count<(1008*3+48*2)
              tmp1(sym_count - 1008*3 - 47) = tmp;
            end
            if sym_count==(1008*3+48*2)
              fai2 = angle(mean(tmp1*1));
            end
            if sym_count>=(1008*3+48*2)
              tmp = tmp * exp(-j*fai2);
            end
          end
          % 导频3
          if (sym_count>=(5*1008+48*2)) && (sym_count<(1008*7+48*3))
            if sym_count<(1008*5+48*3)
              tmp1(sym_count - 1008*5 - 48-47) = tmp;
            end
            if sym_count==(1008*5+48*3)
              fai3 = angle(mean(tmp1*1));
            end
            if sym_count>=(1008*5+48*3)
              tmp = tmp * exp(-j*fai3);
            end
          end
          % 导频3
          if sym_count>=(7*1008+48*3)
            if sym_count<(1008*7+48*4)
              tmp1(sym_count - 1008*7 -48*2-47) = tmp;
            end
            if sym_count==(1008*7+48*4)
              fai4 = angle(mean(tmp1*1));
            end
            if sym_count>=(1008*7+48*4)
              tmp = tmp * exp(-j*fai4);
            end
          end

          xk = real(tmp);
          yk = imag(tmp);
          sym_count = sym_count+1;
          datax(sym_count) = (xk<0);
          datay(sym_count) = (yk<0);
        otherwise
          disp('no this case!');
      end
    end
%   end
end

% figure,plot(ua(1:end-4))
                                   