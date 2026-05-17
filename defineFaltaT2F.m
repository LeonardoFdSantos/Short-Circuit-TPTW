function [Raf, Rbf, Rcf] = defineFaltaT2F(type, Rf)
% DEFINEFALTAT2F Define fault resistances for each TPTW short-circuit type
%
% Types:
%   1 - ABC (three-phase): Raf~0, Rbf~0, Rcf=Rf (ground)
%   2 - AC (phase A-ground): Raf~0, Rbf=open, Rcf=Rf
%   3 - BC (phase B-ground): Raf=open, Rbf~0, Rcf=Rf
%   4 - AB (phase-to-phase aerial): Raf=Rf/2, Rbf=Rf/2, Rcf=open
%        (Rf/2 per phase so total fault resistance between phases = Rf)

switch type
    case 1  % ABC (three-phase)
        Raf = 1e-5;
        Rbf = 1e-5;
        Rcf = Rf;
    case 2  % AC (phase A - ground)
        Raf = 1e-5;
        Rbf = 1e6;
        Rcf = Rf;
    case 3  % BC (phase B - ground)
        Raf = 1e6;
        Rbf = 1e-5;
        Rcf = Rf;
    case 4  % AB (phase-to-phase aerial)
        Raf = Rf/2;
        Rbf = Rf/2;
        Rcf = 1e6;
    otherwise
        error('Invalid fault type: %d', type);
end

end
