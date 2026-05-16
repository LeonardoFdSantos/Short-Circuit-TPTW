%% ValidacaoZe.m
% Validates that adding Ze to OpenDSS eliminates the 20% error in AC/BC faults
% Compares: Analytical vs OpenDSS (without Ze) vs OpenDSS (with Ze)
%
% The "with Ze" model uses a 3-phase line where phase 3 = ground path
% with impedance Ze = real(Zp-2Zm) ohm/km distributed along the line.
% Faults involving ground go to phase 3 (not node .0).
%
% Requirements: OpenDSS installed (https://www.epri.com/pages/sa/opendss)
% Authors: dos Santos et al. (UFSM)
% Date: 2025

clc; clear; close all;

%% Add function path
addpath('..');

%% Base parameters
f = 60;
RI = 1.102;
rmgi = 0.00308;
dij = 1.60;
h = 10.372;
rho = 100;
d_base = 60;
rti = 10;
rtc = 10;
Vbase = 13800;
SCC = 120;
Ztri_pu = 0.0048119 + 1i*0.018511;
Rf_base = 40;

%% Compute TPTW impedances
[Zp, Zm, Ze_line, Zl] = calcImpedanciasCarson(f, RI, rmgi, dij, h, rho);
fprintf('TPTW Impedances (ohm/km):\n');
fprintf('  Zp = %.6f + j%.6f\n', real(Zp), imag(Zp));
fprintf('  Zm = %.6f + j%.6f\n', real(Zm), imag(Zm));
fprintf('  Ze (Zp-2Zm) = %.6f + j%.6f\n', real(Ze_line), imag(Ze_line));
fprintf('  Ze*d (d=60km) = %.2f ohm\n', real(Ze_line)*d_base);

%% Connect to OpenDSS via COM
fprintf('\n=== Connecting to OpenDSS ===\n');
DSSObj = actxserver('OpenDSSEngine.DSS');
if ~DSSObj.Start(0)
    error('Could not start OpenDSS');
end
DSSText = DSSObj.Text;
DSSCircuit = DSSObj.ActiveCircuit;

%% DSS file directory
dssPath = fileparts(mfilename('fullpath'));

%% ========== TEST: End-of-line fault - With vs Without Ze ==========
fprintf('\n=== Validation: Effect of Ze on fault currents (d=60km) ===\n');

fault_names = {'ABC', 'AC', 'BC', 'AB'};
results_analytical = zeros(4, 3);
results_sem_ze = zeros(4, 3);
results_com_ze = zeros(4, 3);

for type = 1:4
    [Raf, Rbf, Rcf] = defineFaltaT2F(type, Rf_base);

    % Analytical calculation
    [IA_a, IB_a, IC_a] = calcCurtoT2F(Zp, Zm, d_base, 1, rti, rtc, ...
                                        Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f);
    results_analytical(type, :) = [IA_a, IB_a, IC_a];

    % --- OpenDSS WITHOUT Ze (T2F_Base.dss, 2-phase line) ---
    DSSText.Command = ['Compile "' fullfile(dssPath, 'T2F_Base.dss') '"'];
    applyFaultBase(DSSText, type, Rf_base);
    DSSText.Command = 'Solve';
    results_sem_ze(type, :) = readCurrentsBase(DSSCircuit);

    % --- OpenDSS WITH Ze (T2F_ComZe.dss, 3-phase line) ---
    DSSText.Command = ['Compile "' fullfile(dssPath, 'T2F_ComZe.dss') '"'];
    applyFaultZe(DSSText, type, Rf_base);
    DSSText.Command = 'Solve';
    results_com_ze(type, :) = readCurrentsZe(DSSCircuit);
end

% Display results
fprintf('\n%-6s | %-10s | %-10s | %-10s | %-10s | %-10s\n', ...
    'Fault', 'Analyt(A)', 'NoZe(A)', 'WithZe(A)', 'Err NoZe', 'Err WithZe');
fprintf('%s\n', repmat('-', 1, 70));

errors_sem = zeros(4, 1);
errors_com = zeros(4, 1);

for type = 1:4
    Imax_a = max(results_analytical(type, :));
    Imax_sem = max(results_sem_ze(type, :));
    Imax_com = max(results_com_ze(type, :));

    if Imax_sem > 0
        err_sem = abs(Imax_a - Imax_sem) / Imax_sem * 100;
    else
        err_sem = 0;
    end
    if Imax_com > 0
        err_com = abs(Imax_a - Imax_com) / Imax_com * 100;
    else
        err_com = 0;
    end

    errors_sem(type) = err_sem;
    errors_com(type) = err_com;

    fprintf('%-6s | %8.2f  | %8.2f  | %8.2f  | %6.2f%%   | %6.2f%%\n', ...
        fault_names{type}, Imax_a, Imax_sem, Imax_com, err_sem, err_com);
end

%% ========== Validation by length WITH Ze (AC fault) ==========
fprintf('\n=== Validation by length: AC fault with Ze ===\n');

d_vec = [20, 40, 60, 80, 100, 120, 180, 240];
results_len_analytical = zeros(length(d_vec), 1);
results_len_sem_ze = zeros(length(d_vec), 1);
results_len_com_ze = zeros(length(d_vec), 1);

[Raf, Rbf, Rcf] = defineFaltaT2F(2, Rf_base);  % AC fault

for id = 1:length(d_vec)
    d = d_vec(id);

    % Analytical
    [IA_a, ~, ~] = calcCurtoT2F(Zp, Zm, d, 1, rti, rtc, ...
                                  Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f);
    results_len_analytical(id) = IA_a;

    % OpenDSS without Ze
    DSSText.Command = ['Compile "' fullfile(dssPath, 'T2F_Base.dss') '"'];
    DSSText.Command = sprintf('Edit Line.LINHA_T2F length=%g', d);
    applyFaultBase(DSSText, 2, Rf_base);
    DSSText.Command = 'Solve';
    currents = readCurrentsBase(DSSCircuit);
    results_len_sem_ze(id) = max(currents);

    % OpenDSS with Ze (3-phase line)
    DSSText.Command = ['Compile "' fullfile(dssPath, 'T2F_ComZe.dss') '"'];
    DSSText.Command = sprintf('Edit Line.LINHA_T2F length=%g', d);
    applyFaultZe(DSSText, 2, Rf_base);
    DSSText.Command = 'Solve';
    currents = readCurrentsZe(DSSCircuit);
    results_len_com_ze(id) = max(currents);
end

fprintf('%-8s | %-10s | %-10s | %-10s | %-8s | %-8s\n', ...
    'd(km)', 'Analyt(A)', 'NoZe(A)', 'WithZe(A)', 'Err NoZe', 'Err wZe');
fprintf('%s\n', repmat('-', 1, 70));

for id = 1:length(d_vec)
    Ia = results_len_analytical(id);
    Is = results_len_sem_ze(id);
    Ic = results_len_com_ze(id);
    err_s = abs(Ia - Is) / Is * 100;
    err_c = abs(Ia - Ic) / Ic * 100;
    fprintf('%5d    | %8.2f  | %8.2f  | %8.2f  | %6.2f%% | %6.2f%%\n', ...
        d_vec(id), Ia, Is, Ic, err_s, err_c);
end

%% ========== Export CSV ==========
T = table();
T.Fault_Type = fault_names';
T.Imax_Analytical = max(results_analytical, [], 2);
T.Imax_OpenDSS_NoZe = max(results_sem_ze, [], 2);
T.Imax_OpenDSS_WithZe = max(results_com_ze, [], 2);
T.Error_NoZe_pct = errors_sem;
T.Error_WithZe_pct = errors_com;
writetable(T, fullfile(dssPath, 'validacao_ze.csv'));
fprintf('\nSaved: validacao_ze.csv\n');

T2 = table();
T2.Length_km = d_vec';
T2.Imax_Analytical_AC = results_len_analytical;
T2.Imax_NoZe_AC = results_len_sem_ze;
T2.Imax_WithZe_AC = results_len_com_ze;
T2.Error_NoZe_pct = abs(results_len_analytical - results_len_sem_ze) ./ results_len_sem_ze * 100;
T2.Error_WithZe_pct = abs(results_len_analytical - results_len_com_ze) ./ results_len_com_ze * 100;
writetable(T2, fullfile(dssPath, 'validacao_ze_comprimento.csv'));
fprintf('Saved: validacao_ze_comprimento.csv\n');

%% ========== Summary ==========
fprintf('\n=== SUMMARY ===\n');
fprintf('Without Ze: AC/BC error = %.1f%% / %.1f%%\n', errors_sem(2), errors_sem(3));
fprintf('With Ze:    AC/BC error = %.1f%% / %.1f%%\n', errors_com(2), errors_com(3));
fprintf('ABC error:  %.1f%% -> %.1f%%\n', errors_sem(1), errors_com(1));
fprintf('AB error:   %.1f%% -> %.1f%%\n', errors_sem(4), errors_com(4));
fprintf('\n');

%% ========== Helper Functions ==========

function applyFaultBase(DSSText, type, Rf)
    % Faults for 2-phase model (T2F_Base.dss)
    % Ground faults go to node .0 via grounding reactors
    switch type
        case 1  % ABC - 3-phase fault
            DSSText.Command = 'New Fault.F1 bus1=FALTA phases=3 r=0.0001';
        case 2  % AC - phase A to ground
            DSSText.Command = sprintf('New Fault.F1 bus1=FALTA.1 phases=1 r=%g', Rf);
        case 3  % BC - phase B to ground
            DSSText.Command = sprintf('New Fault.F1 bus1=FALTA.2 phases=1 r=%g', Rf);
        case 4  % AB - phase to phase
            DSSText.Command = sprintf('New Fault.F1 bus1=FALTA.1 bus2=FALTA.2 phases=1 r=%g', Rf/2);
    end
end

function applyFaultZe(DSSText, type, Rf)
    % Faults for 3-phase model (T2F_ComZe.dss)
    % Ground faults go to phase 3 (the ground conductor)
    switch type
        case 1  % ABC - all 3 phases
            DSSText.Command = 'New Fault.F1 bus1=FALTA phases=3 r=0.0001';
        case 2  % AC - phase 1 to phase 3 (ground conductor)
            DSSText.Command = sprintf('New Fault.F1 bus1=FALTA.1 bus2=FALTA.3 phases=1 r=%g', Rf);
        case 3  % BC - phase 2 to phase 3 (ground conductor)
            DSSText.Command = sprintf('New Fault.F1 bus1=FALTA.2 bus2=FALTA.3 phases=1 r=%g', Rf);
        case 4  % AB - phase 1 to phase 2
            DSSText.Command = sprintf('New Fault.F1 bus1=FALTA.1 bus2=FALTA.2 phases=1 r=%g', Rf/2);
    end
end

function currents = readCurrentsBase(DSSCircuit)
    % Read currents from 2-phase line
    DSSCircuit.SetActiveElement('Line.LINHA_T2F');
    c = DSSCircuit.ActiveCktElement.CurrentsMagAng;
    IA = c(1);  % Phase 1 magnitude
    IB = c(3);  % Phase 2 magnitude
    % Ground current = vector sum
    Ia_vec = c(1)*exp(1i*c(2)*pi/180);
    Ib_vec = c(3)*exp(1i*c(4)*pi/180);
    IC = abs(Ia_vec + Ib_vec);
    currents = [IA, IB, IC];
end

function currents = readCurrentsZe(DSSCircuit)
    % Read currents from 3-phase line
    DSSCircuit.SetActiveElement('Line.LINHA_T2F');
    c = DSSCircuit.ActiveCktElement.CurrentsMagAng;
    IA = c(1);  % Phase 1 magnitude
    IB = c(3);  % Phase 2 magnitude
    IC = c(5);  % Phase 3 magnitude (ground conductor)
    currents = [IA, IB, IC];
end
