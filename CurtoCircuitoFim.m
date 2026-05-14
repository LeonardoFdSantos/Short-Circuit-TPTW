%% Source Data

Ze=13.8^2/120*exp(i*atan(7));
% SCC=300 kVA
Zbase=13.8^2/0.3;
Ztri=2*(0.0048119 +i*0.018511)*Zbase;

%% TPTW Line Impedances
Za=Ze+Ztri+rp+i*2*pi*60*lp+Raf;
Zb=Ze+Ztri+rp+i*2*pi*60*lp+Rbf;
Zc=Ze+Ztri+rti+NRE+i*2*pi*60*le+Rcf; %% for faults before consumer transformer
Zm=rm+i*2*pi*60*lm;

%% Phase Voltages
Va=13800/sqrt(3)*exp(0);
Vb=13800/sqrt(3)*exp(-i*2*pi/3);
Vc=13800/sqrt(3)*exp(i*2*pi/3);

I1=(Va-Vb-(Vb-Vc)*(Zm-Zb)/(Zb+Zc))/(Za+Zb-2*Zm-(Zm-Zb)^2/(Zb+Zc));
I2=(Vb-Vc-(-Zb+Zm)*I1)/(Zb+Zc);

IA=abs(I1);
IB=abs(I2-I1);
IC=abs(-I2);
