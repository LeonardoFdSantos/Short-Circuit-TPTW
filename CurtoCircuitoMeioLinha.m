%% Source Data

Ze=13.8^2/120*exp(i*atan(7));
% SCC=300 kVA
Zbase=13.8^2/0.3;
Ztri=2*(0.0048119 +i*0.018511)*Zbase;

%% TPTW Line Impedances (mid-line fault)

Za = Ze+Ztri+((rp)*m1)+i*2*pi*60*((lp)*m1)+Raf;
Zb = Ze+Ztri+((rp)*m1)+i*2*pi*60*((lp)*m1)+Rbf;

% Conditional Zc: AC/BC uses Zp*d, ABC/AB uses NRE
is_single_phase_ground = (Raf > 1e4 || Rbf > 1e4) && (Rcf < 1e4);
if is_single_phase_ground
    Zc = Ze+Ztri+((rp)*m1)+i*2*pi*60*((lp)*m1)+rti+Rcf;
else
    NRE_val = real(Zp-2*Zm)*d*m1 - rti - rtc;
    if NRE_val < 0, NRE_val = 1e-12; end
    Zc = Ze+Ztri+rti+NRE_val+Rcf;
end
% Zm defined for fault at HV side, before consumer transformers
ZmCC = ((rm)*m1)+i*2*pi*60*((lm)*m1);

%% Mesh Voltage Equations

Va = 13800/sqrt(3)*exp(0);
Vb = 13800/sqrt(3)*exp(-i*2*pi/3);
Vc = 13800/sqrt(3)*exp(i*2*pi/3);

I1 = (Va-Vb-(Vb-Vc)*(ZmCC-Zb)/(Zb+Zc))/(Za+Zb-2*ZmCC-(ZmCC-Zb)^2/(Zb+Zc));
I2 = (Vb-Vc-(-Zb+ZmCC)*I1)/(Zb+Zc);

%% Short-Circuit Current Values
IA = abs(I1);
IB = abs(I2 - I1);
IC = abs(-I2);
