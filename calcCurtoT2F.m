function [IA, IB, IC] = calcCurtoT2F(Zp, Zm, d, m1, rti, rtc, Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f)
% CALCCURTOT2F Compute short-circuit currents for the TPTW system
%
% Inputs:
%   Zp      - Self impedance of the line (ohm/km)
%   Zm      - Mutual impedance of the line (ohm/km)
%   d       - Total line length (km)
%   m1      - Fraction of line to fault point (0 to 1). Use 1 for end-of-line.
%   rti     - Grounding resistance of isolation transformer (ohm)
%   rtc     - Grounding resistance of consumer transformer (ohm)
%   Raf     - Fault resistance phase A (ohm)
%   Rbf     - Fault resistance phase B (ohm)
%   Rcf     - Fault resistance phase C (ohm)
%   Vbase   - Base line-to-line voltage (V), e.g. 13800
%   SCC     - Source short-circuit power (MVA)
%   Ztri_pu - Isolation transformer impedance (pu, complex)
%   f       - Frequency (Hz)
%
% Outputs:
%   IA, IB, IC - Fault currents in phases A, B, C (A, magnitude)

% Source impedance
Ze_source = (Vbase/1000)^2 / SCC * exp(1i*atan(7));

% Transformer impedance (ohm)
Zbase = (Vbase/1000)^2 / 0.3;  % base 300 kVA
Ztri = 2 * Ztri_pu * Zbase;

% Line impedances to fault point
rp = real(Zp) * d * m1;
rm_val = real(Zm) * d * m1;
lp = (imag(Zp)/(2*pi*f)) * d * m1;
lm_val = (imag(Zm)/(2*pi*f)) * d * m1;

% Equalization impedance (Ze = Zp - 2*Zm)
Ze_comp = Zp - 2*Zm;
re = real(Ze_comp) * d * m1 - rti - rtc;
if re < 0
    NRE = 1e-12;
else
    NRE = re;
end
le = 1e-10;  % equalization inductance neglected

% Total mesh impedances
Za = Ze_source + Ztri + rp + 1i*2*pi*f*lp + Raf;
Zb = Ze_source + Ztri + rp + 1i*2*pi*f*lp + Rbf;
Zc = Ze_source + Ztri + rti + NRE + 1i*2*pi*f*le + Rcf;
ZmCC = rm_val + 1i*2*pi*f*lm_val;

% Phase voltages (star)
Va = Vbase/sqrt(3) * exp(0);
Vb = Vbase/sqrt(3) * exp(-1i*2*pi/3);
Vc = Vbase/sqrt(3) * exp(1i*2*pi/3);

% Mesh equations (KVL)
denom = (Za + Zb - 2*ZmCC) - (ZmCC - Zb)^2 / (Zb + Zc);
I1 = (Va - Vb - (Vb - Vc)*(ZmCC - Zb)/(Zb + Zc)) / denom;
I2 = (Vb - Vc - (-Zb + ZmCC)*I1) / (Zb + Zc);

% Phase currents
IA = abs(I1);
IB = abs(I2 - I1);
IC = abs(-I2);

end
