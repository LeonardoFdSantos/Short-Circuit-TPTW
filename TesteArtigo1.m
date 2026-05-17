% Short-Circuit Validation - Main Script
% Runs Simulink models and compares with analytical equations
% Generates CSV files with simulation and calculation results
%
% Requirements: MATLAB/Simulink with Simscape Electrical
% Authors: dos Santos et al. (UFSM)
% Date: 2025
%
% NOTE: This script requires Simulink models (.slx) which are not included
% in this repository. The CSV output files are provided for reproducibility.
% Use gerar_figuras_validacao.py to generate figures from the CSV data.

clc;
clear all; 
close all;

load('trif2awg.mat');

v=220*sqrt(3);
fp=[1];
S=[120e3];

% Line parameters
f=60;                  % Frequency (Hz)
DI=8.01e-3;           % Conductor diameter (m)
RI=1.102;             % AC resistance at 60Hz 75C (ohm/km)
rmgi=0.00308;         % Geometric mean radius (m)
Dotima=1.60;
ri=RI*1.609344;       % Convert to ohm/mile
rd=((pi)^2*f*10^(-4))/0.621371; % Earth return resistance (ohm/mile)
GMRi=rmgi*3.28084;    % Convert to feet
dij=1.2;
dij=[ Dotima];        % Conductor spacing (m)
Dij=dij*3.28084;      % Convert to feet
h1=10.372;            % Conductor height (m)
h=10.372;
rti=10;               % Isolation transformer grounding (ohm)
rtc=10;               % Consumer transformer grounding (ohm)

% Self and mutual impedances (Carson)
zp = ri+rd+(0.12134i)*(log(1/GMRi)+7.93402); % ohm/mile
Zp=zp*0.621371192;   % Convert to ohm/km
zm = rd+(0.12134i)*(log(1/Dij)+7.93402);     % ohm/mile
Zm=zm*0.621371192;    % Convert to ohm/km

% Shunt capacitances
Ri=(DI/2)*3.28084;
Rj=(DI/2)*3.28084;
sii=2*h;
Sii=sii*3.28084;
Sjj=Sii;
sij=sqrt(((dij)^2)+(sii^2));
Sij=sij*3.28084;
Sji=Sij;
Pii= 11.17689*log(Sii/Ri)*10^6;
Pjj= 11.17689*log(Sjj/Rj)*10^6;
Pij= 11.17689*log(Sij/Dij)*10^6;
Pji= 11.17689*log(Sji/Dij)*10^6;
Mp=[Pii Pij; Pji Pjj];
C = inv(Mp);
C=C*0.621371192;      % Convert mile to km
Cct=C(1,1)+C(2,1);   % Conductor-to-ground capacitance (F/km)
Ccc=-C(2,1);          % Conductor-to-conductor capacitance (F/km)
Ceq=Cct-Ccc;          % Equalization capacitance (F/km)

% Equalization impedance (informational only, not used in fault calc)
Ze = Zp-2*Zm;         % ohm/km

% Series impedance
Zl = Zp-Zm;           % ohm/km

dd =[60];
for compensada=[0 1 2]
    for z = 1:length(dd)
    d=dd(z);
    cequa=Ceq*d;
    ccc=Ccc*d;
    cct=Cct*d;
    rp=real(Zp)*d;
    rm=real(Zm)*d;
    lp=(imag(Zp)/(2*pi*f))*d;
    lm=(imag(Zm)/(2*pi*f))*d;

        if compensada==0
        cequa=0;
        % No compensation
        elseif compensada==1
        % C compensation
        elseif compensada==2
        % RC compensation (capacitive only, Re removed)
        end
    end
end

valores_resultados_fim_linha_com_compensacao(1, :) = string({'tipoCurto' 'IA_Sim' 'IB_Sim' 'IC_Sim' 'IA_Calc' 'IB_Calc' 'IC_Calc'});
valores_resultados_meio_linha_com_compensacao(1, :) = string({'n' 'tipoCurto' 'IA_Sim' 'IB_Sim' 'IC_Sim' 'IA_Calc' 'IB_Calc' 'IC_Calc'});

valores_resultados_simulacao_meio_linha_com_comp(1, :) = string({'n' 'tipoCurto' 'Raf' 'Rbf' 'Rcf' 'RaTrif' 'RbTrif' 'RcTrif' 'IA_T2F' 'IB_T2F' 'IC_T2F' 'IA_TRIF' 'IB_TRIF' 'IC_TRIF'});
valores_resultados_simulacao_fim_linha_com_comp(1, :) = string({'tipoCurto' 'Raf' 'Rbf' 'Rcf' 'RaTrif' 'RbTrif' 'RcTrif' 'IA_T2F' 'IB_T2F' 'IC_T2F' 'IA_TRIF' 'IB_TRIF' 'IC_TRIF'});

Parametros_testes = [0.001 .1 .15 .2 .25 .3 .35 .4 .45 .5 .55 .6 .65 .7 .75 .8 .85 .9 .95 .999];

% Fault types:
% 1 = Three-phase (ABC)
% 2 = Phase A-Ground (AC)
% 3 = Phase B-Ground (BC)
% 4 = Phase-to-Phase (AB)
% 5 = No fault (normal operation)

for b = [1:1:5]
    if b == 1
        Raf = 1e-5; Rbf = 1e-5; Rcf = 1e-5;
        RaTrif = 1e-5; RbTrif = 1e-5; RcTrif = 1e-5;
        tipoCurto = 1;
    elseif b == 2
        Raf = 1e-5; Rbf = 1e6; Rcf = 1e-5;
        RaTrif = 1e-5; RbTrif = 1e6; RcTrif = 1e-5;
        tipoCurto = 2;
    elseif b == 3
        RaTrif = 1e6; RbTrif = 1e-5; RcTrif = 1e-5;
        Raf = 1e6; Rbf = 1e-5; Rcf = 1e-5;
        tipoCurto = 3;
    elseif b == 4
        RaTrif = 1e-5; RbTrif = 1e-5; RcTrif = 1e6;
        Raf = 1e-5; Rbf = 1e-5; Rcf = 1e6;
        tipoCurto = 4;
    elseif b == 5
        RaTrif = 1e6; RbTrif = 1e6; RcTrif = 1e6;
        Raf = 1e6; Rbf = 1e6; Rcf = 1e6;
        tipoCurto = 5;
    end

    sim('.\SimCurtoCircuitoComCompensacao.slx')
    Corrente_T2F_Ensaio = abs(CorrenteT2F)/sqrt(2);
    run('.\CurtoCircuitoFim.m');
    valores_resultados_fim_linha_com_compensacao(b+1, :) = [tipoCurto Corrente_T2F_Ensaio IA IB IC];

    sim('.\SimCurtoCircuitoFimLinhaT2FComp.slx')
    sim('.\SimTrifasicoFimLinha.slx')
    Corrente_T2F_Ensaio = abs(CorrenteT2F);
    Corrente_Trifasica_Ensaio = abs(CorrenteTrifasica)/sqrt(2);
    valores_resultados_simulacao_fim_linha_com_comp(b+1, :) = [tipoCurto Raf Rbf Rcf RaTrif RbTrif RcTrif Corrente_T2F_Ensaio Corrente_Trifasica_Ensaio];
end

fprintf('End-of-line complete!\n');
b = 0;
c = 1;
e = 1;

for n = Parametros_testes
    m1 = n;
    for b = [1:1:5]
        if b == 1
            Raf = 1e-5; Rbf = 1e-5; Rcf = 1e-5;
            RaTrif = (1e-5); RbTrif = (1e-5); RcTrif = (1e-5);
            tipoCurto = 1;
        elseif b == 2
            Raf = 1e-5; Rbf = 1e6; Rcf = 1e-5;
            RaTrif = (1e-5); RbTrif = 1e6; RcTrif = (1e-5);
            tipoCurto = 2;
        elseif b == 3
            RaTrif = 1e6; RbTrif = (1e-5); RcTrif = (1e-5);
            Raf = 1e6; Rbf = 1e-5; Rcf = 1e-5;
            tipoCurto = 3;
        elseif b == 4
            RaTrif = 1e-5; RbTrif = 1e-5; RcTrif = 1e6;
            Raf = 1e-5; Rbf = 1e-5; Rcf = 1e6;
            tipoCurto = 4;
        elseif b == 5
            RaTrif = 1e6; RbTrif = 1e6; RcTrif = 1e6;
            Raf = 1e6; Rbf = 1e6; Rcf = 1e6;
            tipoCurto = 5;
        end

        sim('.\SimCurtoCircuitoMeioLinhaComCompensacao.slx')
        Corrente_T2F_Ensaio = abs(CorrenteT2F)/sqrt(2);
        run('.\CurtoCircuitoMeioLinha.m');
        valores_resultados_meio_linha_com_compensacao(c+1, :) = [m1 tipoCurto Corrente_T2F_Ensaio IA IB IC];

        sim('.\SimCurtoCircuitoMeioLinhaT2FComp.slx') 
        sim('.\SimTrifasicoMeioLinha.slx')
        Corrente_T2F_Ensaio = abs(CorrenteT2F)/sqrt(2);
        Corrente_Trifasica_Ensaio = abs(CorrenteTrifasica);
        valores_resultados_simulacao_meio_linha_com_comp(c+1, :) = [m1 tipoCurto Raf Rbf Rcf RaTrif RbTrif RcTrif Corrente_T2F_Ensaio Corrente_Trifasica_Ensaio];
        c = c + 1;
    end
end

fprintf('Mid-line complete!\n');

writematrix(valores_resultados_fim_linha_com_compensacao, 'valores_resultados_fim_linha_com_compensacao_Artigo.csv');
writematrix(valores_resultados_meio_linha_com_compensacao, 'valores_resultados_meio_linha_com_compensacao_Artigo.csv');
writematrix(valores_resultados_simulacao_meio_linha_com_comp, 'valores_resultados_simulacao_meio_linha_com_comp_Artigo.csv');
writematrix(valores_resultados_simulacao_fim_linha_com_comp, 'valores_resultados_simulacao_fim_linha_com_comp_Artigo.csv');

fprintf('Three-phase TPTW complete!\n');
fprintf('\nData exported to CSV files.\n');
