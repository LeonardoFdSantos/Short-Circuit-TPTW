%% Source Data

Ze=13.8^2/120*exp(i*atan(7));
% SCC=300 kVA
Zbase=13.8^2/0.3;
Ztri=2*(0.0048119 +i*0.018511)*Zbase;

%% TPTW Line Impedances
Za=Ze+Ztri+rp+i*2*pi*60*lp+Raf;
Zb=Ze+Ztri+rp+i*2*pi*60*lp+Rbf;

% Conditional Zc: AC/BC uses Zp*d, ABC/AB uses NRE
is_single_phase_ground = (Raf > 1e4 || Rbf > 1e4) && (Rcf < 1e4);
if is_single_phase_ground
    Zc=Ze+Ztri+rp+i*2*pi*60*lp+rti+Rcf;
else
    NRE_val = real(Zp-2*Zm)*d - rti - rtc;
    if NRE_val < 0, NRE_val = 1e-12; end
    Zc=Ze+Ztri+rti+NRE_val+Rcf;
end
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
