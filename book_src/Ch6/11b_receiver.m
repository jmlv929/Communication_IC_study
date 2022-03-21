001 function y=receive(Signal)
002   Si=[0 0 1 1 0 1 1];                 %解扰初始状态
003   Index=1;
004   State=0;
005   SFD=-1;
006   Pi=0;
007   Hi=0;
008   Di=0;   %PREAMBLE搜索解调
009   while (SFD==-1)&(Index<(length(Signal)-9));
010     [a,In,State]=DEB(Signal(:,Index:Index+10),State);
011     Index=Index+In;
012     if a>-1;
013       Pi=Pi+1;
014       [a,Si]=descramble(a,Si);
015       y(Pi)=a;
016       if Pi>15;                                %SFD检测
017         if y(Pi-15:Pi)==[1 1 1 1 0 0 1 1 1 0 1 0 0 0 0 0];
018           SFD=1;  break
019         elseif y(Pi-15:Pi)==[0 0 0 0 0 1 0 1 1 1 0 0 1 1 1 1 ];
020           SFD=0; break
021         end
022       end
023     end
024   end
025   if SFD==1;              %HEADER DBPSK接收
026     while Hi<48;
027       [a,In,State]=DEB(Signal(:,Index:Index+10),State);
028       Index=Index+In;
029       if a>-1;
030           Hi=Hi+1;
031           [a,Si]=descramble(a,Si);
032           y(Pi+Hi)=a;
033       end
034     end
035   else
036     Hi=-1;
037     State=State*2;
038     while Hi<47;                  %HEADER DQPSK接收
039       [a,In,State]=DEQ(Signal(:,Index:Index+10),State);
040       Index=Index+In;
041       if a(1,1)>-1;
042           Hi=Hi+2;
043           [a,Si]=descramble(a,Si);
044           y(Pi+Hi:Pi+Hi+1)=a;
045       end
046     end
047   end
048   Hi=48;
049   if y(Pi+7)==1;                     %下面是PSDU解调
050     if SFD==1;
051         State=State*2;
052     end
053     R=11;
054     Di=-7;
055     while Index<(length(Signal)-6);  %CCK解调（11Mbit/s）
056       [a,In,State]=DEC(Signal(:,Index:Index+7),State,R);
057       Index=Index+In;
058       if a(1,1)>-1;
059           Di=Di+8;
060           [a,Si]=descramble(a,Si);
061           y(Pi+Hi+Di:Pi+Hi+Di+7)=a;
062           if mod(Di-1,16)==0;
063               State=State+2;
064           end
065       end
066     end
067   elseif y(Pi+6)==1;
068     if SFD==1;
069         State=State*2;
070     end
071     R=5.5;
072     Di=-3;
073     while Index<(length(Signal)-6); %CCK解调（5.5Mbit/s）
074       [a,In,State]=DEC(Signal(:,Index:Index+7),State,R);
075       Index=Index+In;
076       if a(1,1)>-1;
077           Di=Di+4;
078           [a,Si]=descramble(a,Si);
079           y(Pi+Hi+Di:Pi+Hi+Di+3)=a;
080           if mod(Di-1,8)==0;
081               State=State+2;
082           end
083       end
084     end
085   elseif y(Pi+5)==1;
086     if SFD==1;
087         State=State*2;
088     end
089     Di=-1;
090     while Index<(length(Signal)-9);         %DQPSK解调
091       [a,In,State]=DEQ(Signal(:,Index:Index+10),State);
092       Index=Index+In;
093       if a(1,1)>-1;
094           Di=Di+2;
095           [a,Si]=descramble(a,Si);
096           y(Pi+Hi+Di:Pi+Hi+Di+1)=a;
097       end
098      end
099    else
100      while Index<(length(Signal)-9);          %DBPSK解调
101        [a,In,State]=DEB(Signal(:,Index:Index+10),State);
102        Index=Index+In;
103        if a(1,1)>-1;
104            Di=Di+1;
105            [a,Si]=descramble(a,Si);
106            y(Pi+Hi+Di)=a;
107        end
108      end
109    end
110  end