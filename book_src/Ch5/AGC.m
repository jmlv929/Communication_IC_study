if AGC_CTRL==1 %% Manual Setting Mode
	IF_Gain=(Gain_Manual<0)*((IF_Gain_Before+Gain_Manual)*((IF_Gain_Before+Gain_Manual)>=IF_Gain_Min)+IF_Gain_Min*((IF_Gain_Before+Gain_Manual)<IF_Gain_Min))+(Gain_Manual>=0)*(IF_Gain_Before*((RF_Gain_Before+Gain_Manual)<=RF_Gain_Max)+(RF_Gain_Before+IF_Gain_Before+Gain_Manual-RF_Gain_Max)*((RF_Gain_Before+Gain_Manual)>RF_Gain_Max));
	IF_Gain=max(IF_Gain_Min,min(IF_Gain_Max,IF_Gain));
	%% Distribute Gain_Manual to IF_Gain
	RF_Gain=(Gain_Manual<0)*(RF_Gain_Before*((IF_Gain_Before+Gain_Manual)>=IF_Gain_Min)+(RF_Gain_Before+IF_Gain_Before+Gain_Manual-IF_Gain_Min)*((IF_Gain_Before+Gain_Manual)<IF_Gain_Min))+(Gain_Manual>=0)*((RF_Gain_Before+Gain_Manual)*((RF_Gain_Before+Gain_Manual)<=RF_Gain_Max)+RF_Gain_Max*((RF_Gain_Before+Gain_Manual)>RF_Gain_Max));
	RF_Gain=max(RF_Gain_Min,min(RF_Gain_Max,RF_Gain));
	%% Distribute Gain_Manual to RF_Gain
else %% Automatic Adjusting Mode
	P_Root=sum((max(abs(real(Data_Out(LEN_Out+1:min(LEN_Out+N_Measure,LEN_In)))),abs(imag(Data_Out(LEN_Out+1:min(LEN_Out+N_Measure,LEN_In)))))+0.5*(min(abs(real(Data_Out(LEN_Out+1:min(LEN_Out+N_Measure,LEN_In)))),abs(imag(Data_Out(LEN_Out+1:min(LEN_Out+N_Measure,LEN_In))))))))/length(Data_Out(LEN_Out+1:min(LEN_Out+N_Measure,LEN_In))); %% Measure the mean of the absolute value of Data_In
	[indx,Power]=quantiz(P_Root,P_R(1:end-1),P_R);
	if indx==0
		P_Root=P_dB(1);
	elseif P_Root>P_R(end)
		P_Root=P_dB(end);
	else
		P_Root=Slope(indx)*P_Root+Intercept(indx);
	end %% Calculate its dB value
	
	RF_Gain=max(RF_Gain_Min,min(RF_Gain_Max,Milestone+RF_Gain_Max-2*P_Root+RF_Gain_Before+IF_Gain_Before-60.5));
	IF_Gain=max(IF_Gain_Min,min(IF_Gain_Max,Milestone+IF_Gain_Min-2*P_Root+RF_Gain_Before+IF_Gain_Before-60.5));
	%% Calculate the new gain values for the RF VGA and the IF VGA
	DIFF_Array=[((RF_Gain+IF_Gain-RF_Gain_Before-IF_Gain_Before)) DIFF_Array(1:end-1)];
	RF_Gain=(abs(DIFF_Array(1))>resolution)*(((Out_EN(end)==0)*RF_Gain)+((Out_EN(end)==1)*((floor(((sum(DIFF_Array>resolution)==N_Filter)+(sum(DIFF_Array<-resolution)==N_Filter))/2)*RF_Gain)+((1-floor(((sum(DIFF_Array>resolution)==N_Filter)+(sum(DIFF_Array<-resolution)==N_Filter))/2))*RF_Gain_Before))))+(abs(DIFF_Array(1))<=resolution)*RF_Gain_Before;
	IF_Gain=(abs(DIFF_Array(1))>resolution)*(((Out_EN(end)==0)*IF_Gain)+((Out_EN(end)==1)*((floor(((sum(DIFF_Array>resolution)==N_Filter)+(sum(DIFF_Array<-resolution)==N_Filter))/2)*IF_Gain)+((1-floor(((sum(DIFF_Array>resolution)==N_Filter)+(sum(DIFF_Array<-resolution)==N_Filter))/2))*IF_Gain_Before))))+(abs(DIFF_Array(1))<=resolution)*IF_Gain_Before;
	%% Decide whether to keep the original values or to update the new gain	values
	Out_EN(end+1:min(end+N_Measure+N,LEN_In))=ceil(((sum(abs(DIFF_Array)<=resolution)==N_Filter)+(Out_EN(end)==1)*(length(find(abs(DIFF_Array)<=resolution))>0))/2); %% Update the state of the AGC
end
