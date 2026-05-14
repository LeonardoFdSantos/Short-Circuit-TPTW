function [Zp, Zm, Ze, Zl] = calcImpedanciasCarson(f, RI, rmgi, dij, h, rho)
% CALCIMPEDANCIASCARSON Compute self and mutual impedances via Carson's equations
%
% Inputs:
%   f    - Frequency (Hz)
%   RI   - AC resistance of conductor (ohm/km)
%   rmgi - Geometric mean radius (m)
%   dij  - Distance between conductors (m)
%   h    - Conductor height (m)
%   rho  - Soil resistivity (ohm.m)
%
% Outputs:
%   Zp - Self impedance (ohm/km)
%   Zm - Mutual impedance (ohm/km)
%   Ze - Equalization impedance (ohm/km)
%   Zl - Series impedance (ohm/km)

% Conversion to miles (Carson uses imperial system)
ri = RI * 1.609344;          % ohm/mile
GMRi = rmgi * 3.28084;      % feet
Dij = dij * 3.28084;        % feet

% Earth return resistance (ohm/mile)
rd = (pi^2 * f * 1e-4) / 0.621371;

% Carson's constant with parameterized resistivity
% De = 2160*sqrt(rho/f) feet -> ln(De) = ln(2160) + 0.5*ln(rho/f)
% For rho=100, f=60: ln(De) = 7.93402
% General: ln(De) = 7.93402 + 0.5*ln(rho/100)
lnDe = 7.93402 + 0.5*log(rho/100);

% Self impedance (ohm/mile)
zp = ri + rd + (0.12134i) * (log(1/GMRi) + lnDe);

% Mutual impedance (ohm/mile)
zm = rd + (0.12134i) * (log(1/Dij) + lnDe);

% Conversion to ohm/km
Zp = zp * 0.621371192;
Zm = zm * 0.621371192;

% Derived impedances
Ze = Zp - 2*Zm;  % equalization (ohm/km)
Zl = Zp - Zm;    % series (ohm/km)

end
