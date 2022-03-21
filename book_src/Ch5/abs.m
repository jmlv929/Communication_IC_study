001 function [ma,ua,datax,datay,deltaf,fai0,syn_pos] = ...
002      demod_timing4v5(xt, yt,osr, SYN0, SYN1, Tchip)
003 SYN0 = 1-2*SYN0;
004 xn = [xt(1+osr), xt(osr/2+1), xt(1)];
005 yn = [yt(1+osr), yt(osr/2+1), yt(1)];
006 time_error0 = 0; pace_ordinate = 0; w = 2/osr; ita = 0.1;
007 c0 = 0.99;
008 k = 64; c1 = 0.0014/k; c2 = 1*10^(-6)/k;
009 
010 ma = zeros(1,length(xt)*2/osr);
011 syn0_buff0 = zeros(1,63*63);
012 ua = zeros(1,length(xt)*2/osr);
013 datax = zeros(1,8256);
014 datay = zeros(1,8256);
015 zr = zeros(1,17921);
016 r = zeros(1,3969);
017 r0 = zeros(1,10);
018 tmp0 = zeros(1,3000);
019 
020 deltaf = 0;
021 fai0 = 0;
022 syn_pos = 0;
023 sym_count = 0;
024 deltaf_fai = 0;
025 state = 0;
026 mm = 0;
027 fh = -1;
028 mk = osr+1;
029 while mk<length(xt)-osr
030 
031   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
032   %定时部分
033   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
034 %   ita = ita-w;
035 %   mk = mk+1;
036 %   if ita<=w
037    time_error = xn(2)*(xn(1)-xn(3))+yn(2)*(yn(1)-yn(3));%同步定时误差提取
038 
039     fh = fh*(-1);
040     time_error = time_error*fh;
041     pace_ordinate = c0 * pace_ordinate + c1 * (time_error - 
042                     time_error0) + c2 * time_error;
043     w = w + pace_ordinate;     % if pace_ordinate>0, 内插位置提前
044     time_error0 = time_error;
045 
046     u = ita/w;% 分数间隔
047     if u>1
048       u = u-1;
049       ita = ita - w;
050       mk = mk+1;
051     elseif u<0
052       u = u+1;
053       ita = ita + w;
054       mk = mk-1;
055     end
056 
057     x = [xt(mk+2),xt(mk+1),xt(mk),xt(mk-1)];
058     y = [yt(mk+2),yt(mk+1),yt(mk),yt(mk-1)];
059 
060     a1 = 0.5*x(1) - 0.5*x(2) - 0.5*x(3) + 0.5*x(4);
061     a2 = -0.5*x(1)+ 1.5*x(2) - 0.5*x(3) - 0.5*x(4);
062     a3 = x(3);
063     xk = (a1*u+ a2) *u + a3;
064     a1 = 0.5*y(1) - 0.5*y(2) - 0.5*y(3) + 0.5*y(4);
065     a2 = -0.5*y(1)+ 1.5*y(2) - 0.5*y(3) - 0.5*y(4);
066     a3 = y(3);
067     yk = (a1*u+ a2) *u + a3;
068 
069     mm = mm+1;
070     ua(mm)=u;
071     ma(mm) = mk;
072 
073     xn = [xk,xn(1:2)];
074     yn = [yk,yn(1:2)];
075     ita = ita-w+1; %求模运算
076     mk = mk+1;
077 
078     %防失锁模块
079     if (w>3/osr) || (w<1/osr)
080       ita = 1;
081       w = 2/osr;
082     end
083     %解调部分
084     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
085     if (fh==-1)
086       switch state
087         case 0 %利用SYN0进行帧捕获
088           tmp = xk+j*yk;
089           sym_count = sym_count+1;
090           tmp0(sym_count) = tmp;
091           %频偏粗略前向估计
092           if sym_count == 3000
093             L0 = sym_count;
094             N = 50;
095             zr = tmp0.^2;
096             for m = 1:N
097               r0(m) = mean(zr(1+m:L0) .* conj(zr(1:L0-m)));
098             end
099             deltaf = angle(sum(r0))/(pi*(N+1)*Tchip)/2;
100             tmp0 = tmp0 .* exp(-j*2*pi*deltaf*(1:sym_count)*Tchip);
101             deltaf_fai = 2*pi*deltaf*sym_count*Tchip;
102             syn0_buff0(969+1:3969) = tmp0;
103           end
104           if sym_count>3000
105             deltaf_fai = deltaf_fai+2*pi*deltaf*Tchip;
106             tmp = tmp * exp(-j*deltaf_fai);
107             syn0_buff0(1:end-1) = syn0_buff0(2:end); % left-shift
108             syn0_buff0(end) = tmp;
109             rval0 = sum(syn0_buff0 .* SYN0);
110             r(ceil(mm/2)) = abs(rval0);
111             if sym_count>4000
112               break;
113             end
114             if (abs(rval0)>1000)
115               disp('SYN0 have been found');
116               fprintf('mk=%d,',mk);
117               fprintf('rval0=%5.1f\n',abs(rval0));
118               state = 1;
119               sym_count = 0;
120               syn_pos = mk;
121             end
122           end
123         case 1 %利用SYN1进行细频偏估计
124           sym_count = sym_count+1;
125           SYN1(sym_count)= 1-SYN1(sym_count)*2;
126           zr(sym_count) = ((xk+j*yk) * SYN1(sym_count));
127           if (sym_count == 17921)
128             L0 = 17921;
129             N = 50;
130             %自相关
131             for m = 1:N
132               r1(m) = mean(zr(1+m:L0) .* conj(zr(1:L0-m)));
133             end
134             %采用L&R 方法，该方法为前面章节提到的频偏估计
135             deltaf = angle(sum(r1(1:N)))/(pi*(N+1)*Tchip);
136 
137             % Initial Phase Estimation
138             t = (0:17920)*Tchip;
139             zr = zr.* exp(-j*2*pi*deltaf*t);
140             fai0 = angle(mean(zr));
141             deltaf_fai = 2*pi*deltaf*17920*Tchip;
142             state = 2;
143             sym_count = 0;
144           end
145 
146         case 2
147           deltaf_fai = deltaf_fai+2*pi*deltaf*Tchip;
148           sym_count = sym_count+1;
149           if sym_count>=(4096+32)
150             state = 3;
151             sym_count = 0;
152           end
153         case 3
154           deltaf_fai = deltaf_fai+2*pi*deltaf*Tchip;
155           tmp = (xk+j*yk) * exp(-j*deltaf_fai) * exp(-j*fai0);
156           %导频1
157           if (sym_count>=1008) && (sym_count<(1008*3+48))
158             if sym_count<(1008+48)
159               tmp1(sym_count - 1007) = tmp;
160             end
161             if sym_count==(1008+48)
162               fai1 = angle(mean(tmp1*1));
163             end
164             if sym_count>=(1008+48)
165               tmp = tmp * exp(-j*fai1);
166             end
167           end
168           %导频2
169           if (sym_count>=(3*1008+48)) && (sym_count<(1008*5+48*2))
170             if sym_count<(1008*3+48*2)
171               tmp1(sym_count - 1008*3 - 47) = tmp;
172             end
173             if sym_count==(1008*3+48*2)
174               fai2 = angle(mean(tmp1*1));
175             end
176             if sym_count>=(1008*3+48*2)
177               tmp = tmp * exp(-j*fai2);
178             end
179           end
180           %导频3
181           if (sym_count>=(5*1008+48*2)) && (sym_count<(1008*7+48*3)
182               )
183             if sym_count<(1008*5+48*3)
184               tmp1(sym_count - 1008*5 - 48-47) = tmp;
185             end
186             if sym_count==(1008*5+48*3)
187               fai3 = angle(mean(tmp1*1));
188             end
189             if sym_count>=(1008*5+48*3)
190               tmp = tmp * exp(-j*fai3);
191             end
192           end
193           %导频4
194           if sym_count>=(7*1008+48*3)
195             if sym_count<(1008*7+48*4)
196               tmp1(sym_count - 1008*7 -48*2-47) = tmp;
197             end
198             if sym_count==(1008*7+48*4)
199               fai4 = angle(mean(tmp1*1));
200             end
201             if sym_count>=(1008*7+48*4)
202               tmp = tmp * exp(-j*fai4);
203             end
204           end
205           xk = real(tmp);
206           yk = imag(tmp);
207           sym_count = sym_count+1;
208           datax(sym_count) = (xk<0);
209           datay(sym_count) = (yk<0);
210         otherwise
211           disp('no this case!');
212       end
213     end
214 end
215