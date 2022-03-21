function my_cic_generatehdl(filtobj)
%  MY_CIC_GENERATEHDL   Function to generate HDL for filter object.
%  Generated by MATLAB(R) 8.3 and the Filter Design HDL Coder 2.9.5.
%  Generated on: 2014-12-24 21:44:13
%  -------------------------------------------------------------
%  HDL Code Generation Options:
%  ResetType: Synchronous
%  OptimizeForHDL: on
%  ResetInputPort: syn_rst
%  TargetDirectory: E:\百度云同步盘\书籍\书稿\第三章
%  AddInputRegister: off
%  InputPort: cic_in
%  OutputPort: cic_out
%  Name: my_cic
%  TargetLanguage: Verilog
%  TestBenchStimulus: step ramp chirp noise 
%  GenerateHDLTestbench: on
% 
%  Filter Settings:
%  Discrete-Time FIR Multirate Filter (real)
%  -----------------------------------------
%  Filter Structure        : Cascaded Integrator-Comb Decimator
%  Decimation Factor       : 5
%  Differential Delay      : 1
%  Number of Sections      : 1
%  Stable                  : Yes
%  Linear Phase            : Yes (Type 1)
%
%  Input                   : s16,15
%  Output                  : s19,15
%  Filter Internals        : Full Precision
%    Integrator Section 1  : s19,15
%    Comb Section 1        : s19,15

%  -------------------------------------------------------------

% Generating HDL code
generatehdl(filtobj, 'ResetType', 'Synchronous',... 
               'OptimizeForHDL', 'on',... 
               'ResetInputPort', 'syn_rst',... 
               'TargetDirectory', 'E:\百度云同步盘\书籍\书稿\第三章',... 
               'AddInputRegister', 'off',... 
               'InputPort', 'cic_in',... 
               'OutputPort', 'cic_out',... 
               'Name', 'my_cic',... 
               'TargetLanguage', 'Verilog',... 
               'TestBenchStimulus',  {'step', 'ramp', 'chirp', 'noise'},... 
               'GenerateHDLTestbench', 'on');

% [EOF]
