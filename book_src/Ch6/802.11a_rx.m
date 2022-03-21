 1 function 11a_rx
 2 path( strcat(pwd,'/script/'), path  );   % 把当前路径下的/script/设为工作路径
 3 path( pwd,path  );    % 把当前路径设为工作路径
 4 tblen = 96;  % 设定维特比译码深度
 5 pilots = [1 1 1 -1];     % --- 四个导频的极性
 6 ShortS = sqrt(13/6)*[0 0 1+j 0 0 0 -1-j 0 0 0 1+j 0 0 0 -1-j 0 0 0 -1-j 0 0 0 1+j 0 0 0 0 ...
 7   0 0 0 -1-j 0 0 0 -1-j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0 0 1+j 0 0];
 8 ShortPreample = difft64(ShortS);
 9 ShortPreample = num2fixpt(ShortPreample*2^4, sfix(3), 2^(0), 'Nearest', 'on');
10 LongS = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 0 ...
11   1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1];
12 DataPilot = [0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 ...
13 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0 0 0 0 0];
14
15 LongPreample = difft64(LongS);
16 LongPreample = num2fixpt(LongPreample*2^4, sfix(3), 2^(0), 'Nearest', 'on');
17
18 FDataPilot = difft64(DataPilot);
19 FDataPilot = resample(FDataPilot, 2, 1);
20 length(LongPreample);
21
22 pscale = [ 1 1 1 1 -1 -1 -1 1 -1 -1 -1 -1 1 1 -1 1 -1 -1 1 1 -1 1 1 -1 1 1 1 1 1 ...
 1 -1 1 1 1 -1 1 1 -1 -1 1 1 1 -1 1 -1 -1 -1 1 -1 1 -1 -1 1 -1 -1 1 1 1 1 1 -1 -1 ...
  1 1 -1 -1 1 -1 1 -1 1 1 -1 -1 -1 1 1 -1 -1 -1 -1 1 -1 -1 1 -1 1 1 1 1 -1 1 -1 1 ...
 -1 1 -1 -1 -1 -1 -1 1 -1 1 1 -1 1 -1 1 1 1 –1 -1 1 -1 -1 -1 1 1 1 -1 -1 -1 -1 -1 -1 -1];
25 FreqCompenLen = 10;  % 定义频域计算时的量化bit
26 AngleLen = 11;    % 定义求角度计算时的量化bit
27 FFTLenWhole = 4;   % 定义FFT计算时的量化bit的整数位bit
28 FFTLenFrac = 5;     % 定义FFT计算时的量化bit的小数位bit
29 CheWWhole = 8;     % 定义求权重计算时的量化bit的整数位bit
30 CheWFrac = 5;     % 定义求权重计算时的量化bit的小数位bit
31
32 AddSampleNum = 0; %定义采样偏差1: add 1 sample every 10000 samples;-1: delete 1 sample every 10000 samples
33 multipath_model = 2;%多径类型：1 for ETSI－A； 2 for ETSI－B；3 for ETSI－C；4 for ETSI－D；5 for ETSI－E
34 IsFixpt = 1;    % 进行量化计算时为1   进行全浮点数计算时为0
35 IsDataFixpt = 1;  % 是否对接收机收到的数据进行量化，1进行量化；0不进行量化
36 Diversity = 0;  % 是否进行分集接收，0不分集（单天线）；1分集（双天线）
37 for  data_rate = [54];    %  data rate [6 9 12 18 24 36 48 54]
38   for offset = [300]    % 设定固定频偏，实际最大为300KHz
39     for SNR = [26]
40 % 以上的参数设置仅为读取相应方式下发射机的输出数据，便于分析比对用。它们与接收机的处理过程无关。
41       times = 0;   % 在一种固定方式（SNR、频偏、速率、多径）测试多包数据时的测试次数统计
42       for run_times=[1:500];   % 在一种固定方式下测试的总包数为500
43         root_  th = sprintf('Data64\\model% d\\% dM_data\\f% dK\\SNR% d\\data_% d', ...
             multipath_model, data_rate, offset,SNR,run_times);
44         fpsdu_name = sprintf('% s\\psdu.txt',  root_path); %定义发射机发出的数据和原始PSDU的存放位置
45         fSignal_fi_name = sprintf('% s\\data_fi.txt', root_path);
46         fSignal_fq_name = sprintf('% s\\data_fq.txt', root_path);
47         fSignal_fi = fopen(fSignal_fi_name, 'r');
48         fSignal_fq = fopen(fSignal_fq_name, 'r');
49         s_fi =  fscanf(fSignal_fi, '% f');
50         s_fq =  fscanf(fSignal_fq, '% f');  % 读A路天线收到的I、Q路数据，浮点数
51         fclose(fSignal_fi);
52         fclose(fSignal_fq);
53         Signal = s_fi' + j*s_fq';
54         Signal = resample(Signal, 2, 1); % 接收机为40M时钟处理，而发射机输出为20MHz，将发射机输出数据加倍
55
56         fSignal_fi_name = sprintf('% s\\data_fiB.txt', root_path);
57         fSignal_fq_name = sprintf('% s\\data_fqB.txt', root_path);
58         fSignal_fi = fopen(fSignal_fi_name, 'r');
59         fSignal_fq = fopen(fSignal_fq_name, 'r');
60         s_fi =  fscanf(fSignal_fi, '% f');
61         s_fq =  fscanf(fSignal_fq, '% f');
62         fclose(fSignal_fi);
63         fclose(fSignal_fq);
64         SignalB = s_fi' + j*s_fq';
65         SignalB = resample(SignalB, 2, 1);
66         fpsdu = fopen(fpsdu_name, 'r');   % 读发射机发射前的PSDU原始数据，为作比对用
67         psdu = fscanf(fpsdu, '% d');
68         fclose(fpsdu);
69
70    % timing offset ---
71         DataLen = 10000;
72         Signal = resample(Signal, DataLen, DataLen+AddSampleNum);     %  设定采样偏差--
73         SignalB = resample(SignalB, DataLen, DataLen+AddSampleNum);
74    % ADC ------ % BackOff值的选取与量化bit相互影响
75         BackOff = -9;  %  BackOff为接收机基带要处理的数据的平均功率比接收机收到的峰值功率低9dB
76         target_rms = 10^( BackOff/20 );  % 确定要基带要处理的信号的rms
77         [Signal, gain] = adjust_rms( Signal, target_rms );% 调整输入信号的rms
78         [SignalB, gain] = adjust_rms( SignalB, target_rms );
79
80         if IsDataFixpt == 1   % 是否对接收机收到的数据量化
81                 Signal = num2fixpt(Signal, sfix(8), 2^(-7), 'Nearest', 'on');
82                 SignalB = num2fixpt(SignalB, sfix(8), 2^(-7), 'Nearest', 'on');
83         end
84         Signal2 = num2fixpt(Signal, sfix(4), 2^(-3), 'Nearest', 'on');
85 %  进行包检测，判断是否为有效数据包。短头同步--
86         Plateu264(1)=0;
87         for i = 1:800 % 用短头上的相邻的两个短头t_slot进行互相关 
88           Plateu2(i) = Signal2(i:2:i+31)*Signal2(i+32:2:i+31+32)';   
89           Plateu264(i+1) = Plateu264(i)*(1-1/16) + Plateu2(i)/16;
90         end
91         Index = 80*2;
92         for i=1:16*2
93           ShortSync(i) = Signal(Index+i:2:Index+i+32*2-1) * ShortPreample(1:32)';
94         end
95         [ShortPeak, I] = max(ShortSync(1:16*2));
96         Index = Index + I;
97 %  第一种方法的频偏估计，在本项目的初期时采用，后被其它优化算法代替 
98         ShortPeak = Signal(Index:2:Index+32*2-1) * ShortPreample(1:32)';
99         P0 = angle(ShortPeak);
100
101         Index = Index + 16*2;
102         ShortPeak = Signal(Index:2:Index+32*2-1) * ShortPreample(1:32)';
103         P1 = angle(ShortPeak);
104
105         if IsFixpt== 1      % 是否进行量化 %s4.4
106         P0 = num2fixpt(P0, sfix(AngleLen), 2^(-AngleLen+1)*pi, 'Nearest', 'on'); 
107         P1 = num2fixpt(P1, sfix(AngleLen), 2^(-AngleLen+1)*pi, 'Nearest', 'on');
108         end
109 % 第一种方法结束--――――――――――――
110 % 目前使用的效果明显较好的短头频偏估计，
111         [Plateu, I] = max(abs(Plateu264(1:320)));
112         Fs = -angle(Plateu264(I));  %  coarse freq. offset
113         Fsc = Fs/16/2;
114         Ps = P1;
115 %  --对长头的检测（同步，纠相偏、精同步、信道估计和均衡）--
116         FC_End = Index + 160*2;
117         for I = Index:FC_End
118           Ps=Ps+Fsc;
119           S = exp(-j*Ps);
120           if IsFixpt== 1 %  s4.4
121             S=num2fixpt(S,sfix(FreqCompenLen),2^(-FreqCompenLen+1),'Nearest','on');
122           end
123           Signal(I)=Signal(I)*S; % 对收到的两路长头纠相偏
124           SignalB(I)=SignalB(I)*S;
125         end
126
127         for i=1:96*2
128           LongSync(i)=Signal(Index+i:2:Index+i+64*2-1)*([LongPreample(49:64)LongPreample(1:48)])';
129         end
130         [LongPeak, I] = max(LongSync);     % 对长头相关检测，记录峰值和位置
131         Index = Index + I;% 长头同步
132         SyncIndex = Index;
133         LongPeak = Signal(Index:2:Index+64*2-1) * ([LongPreample(49:64) LongPreample(1:48)])';
134         if IsFixpt== 1 %  s4.4
135            LongPeak = num2fixpt(LongPeak, sfix(9), 2^(-2), 'Nearest', 'on'); 
136         end
137         P0 = angle(LongPeak);  % 长头第1个匹配峰值的角度
138
139         Che0 = dfft64( Signal(Index:2:Index+64*2-1), 16 );% 天线1支路的第1次信道估计
140         CheB0 = dfft64( SignalB(Index:2:Index+64*2-1), 16 );    % 天线2支路的第1次信道估计
141
142         Index = Index + 64*2;
143         for I = FC_End+1:Index + 64*2-1
144           Ps=Ps+Fsc; % 相邻两个采样点间的相位差
145           S = exp(-j*Ps);    % 对长头数据纠相偏
146           if IsFixpt== 1 %  s4.4
147           S = num2fixpt(S, sfix(FreqCompenLen), 2^(-FreqCompenLen+1), 'Nearest', 'on'); 
148           end
149           Signal(I)=Signal(I)*S;
150           SignalB(I)=SignalB(I)*S;
151         end
152         LongPeak=Signal(Index:2:Index+64*2-1)*([LongPreample(49:64),LongPreample(1:48)])';
153         if IsFixpt== 1 %  s4.4 
154         LongPeak = num2fixpt(LongPeak, sfix(9), 2^(-2), 'Nearest', 'on'); 
155         end
156         P1 = angle(LongPeak);    % 长头第2个匹配峰值的角度
157         Che1 = dfft64( Signal(Index:2:Index+64*2-1), 16);  % 长头上两支路的第2次信道估计
158         CheB1 = dfft64( SignalB(Index:2:Index+64*2-1), 16);
159
160         Che = (Che0 + Che1)/2.*[LongS(1:26) LongS(28:53)];% 对两支路上两次信道求平均并纠极性
161         CheB = (CheB0 + CheB1)/2.*[LongS(1:26) LongS(28:53)];
162         if IsFixpt== 1
163         Che  = num2fixpt(Che,sfix(1+FFTLenWhole+FFTLenFrac),2^(-FFTLenFrac),'Nearest','on'); 
164         CheB = num2fixpt(CheB,sfix(1+FFTLenWhole+FFTLenFrac),2^(-FFTLenFrac),'Nearest','on');
165         end
166         Che = Che_filter(Che);    % 对两路信道估计低通滤波  Che_filter为自定义函数
167         CheB = Che_filter(CheB);
168
169         if Diversity == 0   % 如果未进行分集接收，则将B支路的信道估计参数设为零
170           CheB = zeros(1,52);
171         end
172         Pilot_Che = [Che(6) Che(20) Che(33) Che(47)];
173         Pilot_CheB = [CheB(6) CheB(20) CheB(33) CheB(47)];
174         CheW =abs(Che).^2+abs(CheB).^2;  
175         % 两路合成后4个导频信道权重，提供最小二乘拟合相位估计用。参见文档“802.11a接收机设计”
176         if IsFixpt== 1 %  u8.3
177            CheW  = num2fixpt(CheW, ufix(CheWWhole+CheWFrac), 2^(-CheWFrac), 'Nearest', 'on'); 
178         end % 48个子载波的权重，用于解映射时考虑分母的影响 
179         CheW48 = [CheW(1:5) CheW(7:19) CheW(21:32) CheW(34:46) CheW(48:52)];   
180         Pilot_Che_Sync = [CheW(6) CheW(20) CheW(33) CheW(47)];
181
182 %  ----------精频偏估计------
183         if IsFixpt== 1 %  s4.4
184           P0 = num2fixpt(P0, sfix(AngleLen), 2^(-AngleLen+1)*pi, 'Nearest', 'on');  
185           P1 = num2fixpt(P1, sfix(AngleLen), 2^(-AngleLen+1)*pi, 'Nearest', 'on');  
186         end
187         Fs = P1-P0;  %  fine freq. Offset % 长头上两次相关峰的相位差
188         if Fs >= pi
189           Fs = Fs -2*pi;
190         else if  Fs <= -pi
191             Fs = Fs +2*pi;
192           end
193         end
194         Fsc = Fsc + Fs/64/2;   % 短头和长头累计底相邻两采样点间的相位差
195         Ps = Ps + P1;     % 将累计总的相位存于P
196     % ---Signal段处理----------
197         Index = Index + 80*2;
198         for I = Index:Index+80*2-1
199           Ps=Ps+Fsc;
200           S = exp(-j*Ps);
201           if IsFixpt== 1 %  s4.4
202             S = num2fixpt(S, sfix(FreqCompenLen), 2^(-FreqCompenLen+1), 'Nearest', 'on'); 
203           end
204           Signal(I)=Signal(I)*S;    % 对Signal的数据纠相偏
205           SignalB(I)=SignalB(I)*S;
206         end
207         Preset = 8; % 优选FFT的开始点，此处选择的原则尚待商讨
208         subcarry = dfft64([Signal(Index+16*2:2:Index+64*2-1+Preset*2) Signal(Index+Preset*2:2:Index+15*2)],0);
209         subcarryB= dfft64([SignalB(Index+16*2:2:Index+64*2-1+Preset*2) SignalB(Index+Preset*2:2:Index+15*2)],0);
210         if IsFixpt== 1 %  s4.4 
211           subcarry=num2fixpt(subcarry,sfix(1+FFTLenWhole+FFTLenFrac),2^(-FFTLenFrac),'Nearest','on');
212           subcarryB=num2fixpt(subcarryB,sfix(1+FFTLenWhole+FFTLenFrac),2^(-FFTLenFrac),'Nearest','on'); 
213         end
214         SignalCheSub = subcarry;
215         SignalCheSubB = subcarryB;
216    % --作首次均衡：最大比合成。参见文档“802.11a接收机设计” 未执行./(abs(Che).^2+abs(CheB).^2);
217         subcarryCheS = (subcarry.*conj(Che) + subcarryB.*conj(CheB));   %
218         if IsFixpt== 1 %  s8.3
219           subcarryCheS=num2fixpt(subcarryCheS,sfix(1+CheWWhole+CheWFrac),2^(-CheWFrac),'Nearest','on');
220         end
221    %  -----作第二次均衡：纠相偏-------
222           pilot = [subcarryCheS(6) subcarryCheS(20) subcarryCheS(33) -subcarryCheS(47)];
223           angle_p = angle(pilot);   % 求四个导频的相位
224 % 作正交最小二乘拟合，MinSqurePhaseLine为自定义函数
225        [Phase, kF, aF, b, PhasePilot] = MinSqurePhaseLine(angle_p, Pilot_Che_Sync);
226        subcarry = subcarryCheS.*exp(-j*Phase);   % 对52个子载波纠相偏
227        SIGNAL = [subcarry(1:5) subcarry(7:19) subcarry(21:32) subcarry(34:46) subcarry(48:52)];
228        % SoftDecide为demap，deinter，depuncture并量化后的1～128间7位量化数，
           % CheW48为作Demap时输入数据的“权重” 参见文档“802.11a接收机设计
229         SoftDecide = DecideASymbol(SIGNAL, 1, 48, 1, CheW48);
230    %  ---解Signal段---
231         trellis=poly2trellis(7,[133,171]);
232         if IsFixpt== 1
233           SoftDecide = num2fixpt(SoftDecide, sfix(7), 2^(-3), 'Nearest', 'on');
234         end
235         SIGNAL_Data = vitdec(-SoftDecide,trellis,24, 'term', 'unquant');
236         SIGNAL_Error = mod(sum(SIGNAL_Data(1:18)),2);
237
238         Rate = DecideRate(SIGNAL_Data);   % 从Signal中解出Rate
239         if Rate ~= data_rate
240           SIGNAL_Error = 1;
241         end
242         Rate = data_rate;
243         % 由Rate解出其它相关参数。 
244         [Ncbps Ndbps modmethod codingrate] = DecidePara(Rate);     
245         length = bi2de(SIGNAL_Data(6:17)); %由Signal解出PSDU的长度，输出为10进制
246         if length ~= length(psdu)/8
247           SIGNAL_Error = 1;
248         end
249
250         length = length(psdu)/8;
251         numSymbol = ceil((16+length*8+6)/Ndbps); % 解出OFDM Symbole的个数
252         % Data段处理 
253         K4 = 0; % K4为52个子载波相位的变化，拟和后的直线的斜率
254         for i =1:numSymbol
255           Index = Index + 80*2;
256           for I = Index:Index+80*2-1
257             Ps=Ps+Fsc;
258             S = exp(-j*Ps);
259             if IsFixpt== 1  %  s4.4
260               S=num2fixpt(S,sfix(FreqCompenLen),2^(-FreqCompenLen+1),'Nearest','on'); 
261             end
262             Signal(I)=Signal(I)*S;% 对Data纠相偏
263             SignalB(I)=SignalB(I)*S;
264           end
265
266         subcarry=dfft64([Signal(Index+16*2:2:Index+64*2-1+Preset*2),Signal(Index+Preset*2:2:Index+15*2)],0);
267         subcarryB=dfft64([SignalB(Index+16*2:2:Index+64*2-1+Preset*2),SignalB(Index+Preset*2:2:Index+15*2)],0);
268
269          if IsFixpt== 1 %  s4.4
270            subcarry=num2fixpt(subcarry,sfix(1+FFTLenWhole+FFTLenFrac),2^(-FFTLenFrac),'Nearest','on');
271            subcarryB=num2fixpt(subcarryB,sfix(1+FFTLenWhole+FFTLenFrac),2^(-FFTLenFrac),'Nearest','on');
272          end
273
274  %  对Data作第1次信道均衡最大比合成,注意此处未进行除(abs(Che).^2+abs(CheB).^2);
275           subcarryCheS = (subcarry.*conj(Che) + subcarryB.*conj(CheB)); 
276         if IsFixpt== 1%  s8.3
277          subcarryCheS=num2fixpt(subcarryCheS,sfix(1+CheWWhole+CheWFrac),2^(-CheWFrac),'Nearest','on');
278         end
279
280  %  Data段第2次信道均衡-- % 纠正4个导频的极性
281           pilot = pscale(mod(i,127)+1)*[subcarryCheS(6) subcarryCheS(20) subcarryCheS(33) -subcarryCheS(47)];  
282           angle_p = angle(pilot);  % 4个导频的相位
283           [Phase, k, a, b, PhasePilot] = MinSqurePhaseLine(angle_p, Pilot_Che_Sync); 
284           k=0;
285           if IsFixpt== 1
286             k  = num2fixpt(k, sfix(10), 2^(-15)*pi, 'Nearest', 'on'); %
287           end
288           Phase = a + ([(-26:-1) (1:26)]-7*b)*k/7;
289           K4 = (1-0.25)*K4 + 0.25*k;  % 对相位变化的斜率K作平滑，输出为K4
290           All_k(i) = k;
291           subcarry = subcarryCheS.*exp(-j*Phase);% 对合成后的子载波纠相偏
292           SIGNAL = [subcarry(1:5) subcarry(7:19) subcarry(21:32) subcarry(34:46) subcarry(48:52)];
293           SoftDecide = DecideASymbol(SIGNAL, modmethod, Ncbps, codingrate, CheW48);  
294           SoftDecideAll((i-1)*Ndbps*2+1:i*Ndbps*2) = SoftDecide;
295
296  %  ----- 同步跟踪调整--------
297           if K4*64/pi > 0.5 %当频偏及采样偏差引起的采样点漂移超过了半个采样间隔时，
298             Index = Index - 1; %将Index向后移一个点用以纠正
299             Ps = Ps - Fsc;  % 当前的相位也向后移一个点
300           end
301
302           if K4*64/pi < -0.5  % 同理判断采样点漂移,调整Index的位置
303             Index = Index + 1;
304             Ps = Ps + Fsc;
305           end
306         end
307
308    %  ------Vitdec译码-------
309         DecodeLen = (16+length*8+6)*2; % 必须对送入Vitdec译码器的数据长度进行限制
310         if IsFixpt== 1
311           SoftDecideAll = num2fixpt(SoftDecideAll, sfix(7), 2^(-3), 'Nearest', 'on');
312         end
313         SoftDecideAll = num2fixpt(SoftDecideAll, sfix(7), 2^(-3), 'Nearest', 'on');
314         Decode = vitdec(-SoftDecideAll(1:DecodeLen),trellis,tblen, 'term', 'unquant');
315
316         DeScr = scramble(Decode, [1 0 1 1 1 0 1]);   % 解扰
317         out = DeScr(17:length*8+16);     % -接收机输出PSDU
318         De=xor(out,psdu');    % 与原始PSDU比对
319         times =times + 1;
320         Eb(times)=sum(De)/(length(out));   % 统计当前包的误码率
321         if SIGNAL_Error
322           Eb(times) = 1;
323         end
324         sumDe(times)=sum(De);
325         Per=sum(Eb'>0)/times;  % 统计当前包的误包率
326         ferror(times) = Fsc/2/pi*40000 - offset;% 统计经过纠频偏后仍然存在的由噪声引起的随机频率偏差
327         f_result = fopen('screen.txt', 'a');
328         str_result = sprintf('% 3d, maxW=% 6.3f, rate: % d  SNR: % .1f  freq: % d multipath: 
            % d SyncIndex = % d ferror: %  5.1f bit error: %  4d Eb: % 4.1f% %  Per = % 5.1f% % ', ...
            run_times, abs(LongPeak), data_rate, SNR, offset,multipath_model,SyncIndex,  ...
            ferror(times),sum(De), 100*Eb(times), Per*100);
330         disp(str_result);
331         fprintf(f_result, '% s\n', str_result);
332         fclose(f_result);
333       end% run_times
334       Per=sum(Eb'>0)/times;    % 统计最终的误包率
335       Ber = sum(sumDe)/times/8/length;     % 统计最终的误码率
336
337       f_result = fopen('result.txt', 'a');
338       str_result = sprintf('rate: % d  SNR: % .1f  freq off: % d multipath: % d ferror = % 4.2f ...
339         Ber =%.2e Per=%3.2f% %', data_rate,SNR,offset,multipath_model,std(ferror), Ber, Per*100);
340       disp(str_result);
341       fprintf(f_result, '% s\n', str_result);
342       fclose(f_result);
343       f_result = fopen('screen.txt', 'a');
344       fprintf(f_result, '% s\n', str_result);% 将最终的统计结果保存在screen.txt
345       fclose(f_result);
346
347       Eb = zeros(1, times);
348       sumDe  = zeros(1, times);
349
350     end% frequency offset
351   end% EbNo
352 end% data_rate
353
354 disp('program end');
