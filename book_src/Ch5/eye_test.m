%% 16QAM
hMod = comm.RectangularQAMModulator('ModulationOrder', 16); 
hAWGN = comm.AWGNChannel('NoiseMethod', 'Signal to noise ratio (SNR)',...
                         'SNR', 20); 
                     
hScope = comm.ConstellationDiagram('ReferenceConstellation', hMod.constellation);
d = randi([0 15], 1000, 1);
sym = step(hMod, d);
rcv = step(hAWGN, sym);
step(hScope, rcv)

%% 3QAM
 hQAMMod = comm.GeneralQAMModulator;     
  % Setup a three point constellation
       hQAMMod.Constellation = [1 1i -1];
       data = randi([0 2],100,1);
       modData = step(hQAMMod, data);
       scatterplot(modData)

%% 8QAM       
% Create binary data for 32, 3-bit symbols
    data = randi([0 1],96,1);
% Create a rectangular 8-QAM modulator System object with bits as inputs and Gray-coded signal constellation
    hModulator = comm.RectangularQAMModulator(8,'BitInput',true);
% Rotate the constellation by pi/4 radians
    hModulator.PhaseOffset = pi/4;
% Modulate and plot the data
    modData = step(hModulator, data); 
    constellation(hModulator)
    
 %% 16QAM       
% Create binary data for 100, 4-bit symbols
    data = randi([0 1],2000,1);
% Create a rectangular 8-QAM modulator System object with bits as inputs and Gray-coded signal constellation
    hModulator = comm.RectangularQAMModulator(16,'BitInput',true);
% Rotate the constellation by pi/4 radians
    hModulator.PhaseOffset = 0;%pi/4;
% Modulate and plot the data
    modData = step(hModulator, data); 
    constellation(hModulator)
    
     %% 64QAM       
% Create binary data for 100, 4-bit symbols
    data = randi([0 1],64*6,1);
% Create a rectangular 8-QAM modulator System object with bits as inputs and Gray-coded signal constellation
    hModulator = comm.RectangularQAMModulator(64,'BitInput',true);
% Rotate the constellation by pi/4 radians
    hModulator.PhaseOffset = 0;%pi/4;
% Modulate and plot the data
    modData = step(hModulator, data); 
    constellation(hModulator)