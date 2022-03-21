function filter_serial_generatehdl(filtobj)
%  FILTER_SERIAL_GENERATEHDL   Function to generate HDL for filter object.
% 
%  Generated by MATLAB(R) 7.12 and the Filter Design HDL Coder 2.8.
% 
%  Generated on: 2015-01-01 16:37:22
% 
%  -------------------------------------------------------------
%  HDL Code Generation Options:
%  ResetType: Synchronous
%  ResetInputPort: syn_rst
%  TargetDirectory: E:\�ٶ���ͬ����\�鼮\���\������
%  AddOutputRegister: off
%  Name: filter_serial
%  RemoveResetFrom: ShiftRegister
%  SerialPartition: 6
%  TargetLanguage: Verilog
%  TestBenchStimulus: impulse step ramp chirp noise 
%  GenerateHDLTestbench: on
% 
%  Filter Settings:
%  Discrete-Time FIR Filter (real)
%  -------------------------------
%  Filter Structure  : Direct-Form FIR
%  Filter Length     : 6
%  Stable            : Yes
%  Linear Phase      : Yes (Type 2)
%  Arithmetic        : fixed
%  Numerator         : s16,16 -> [-5.000000e-001 5.000000e-001)
%  Input             : s16,15 -> [-1 1)
%  Filter Internals  : Specify Precision
%    Output          : s16,15 -> [-1 1)
%    Product         : s31,31 -> [-5.000000e-001 5.000000e-001)
%    Accumulator     : s33,31 -> [-2 2)
%    Round Mode      : convergent
%    Overflow Mode   : wrap

%  -------------------------------------------------------------

% Generating HDL code
generatehdl(filtobj, 'ResetType', 'Synchronous',... 
               'ResetInputPort', 'syn_rst',... 
               'TargetDirectory', 'E:\�ٶ���ͬ����\�鼮\���\������',... 
               'AddOutputRegister', 'off',... 
               'Name', 'filter_serial',... 
               'RemoveResetFrom', 'ShiftRegister',... 
               'SerialPartition', 6,... 
               'TargetLanguage', 'Verilog',... 
               'TestBenchStimulus',  {'impulse', 'step', 'ramp', 'chirp', 'noise'},... 
               'GenerateHDLTestbench', 'on');

% [EOF]