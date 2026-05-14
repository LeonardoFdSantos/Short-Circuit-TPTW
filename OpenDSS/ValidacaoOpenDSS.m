%% ValidacaoOpenDSS.m
% Validation of TPTW analytical model using OpenDSS via COM
% Compares fault currents: Analytical vs OpenDSS
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
[Zp, Zm, Ze, Zl] = calcImpedanciasCarson(f, RI, rmgi, dij, h, rho);
fprintf('TPTW Impedances (ohm/km):\n');
fprintf('  Zp = %.6f + j%.6f\n', real(Zp), imag(Zp));
fprintf('  Zm = %.6f + j%.6f\n', real(Zm), imag(Zm));

%% Connect to OpenDSS via COM
fprintf('\n=== Connecting to OpenDSS ===\n');
DSSObj = actxserver('OpenDSSEngine.DSS');
if ~DSSObj.Start(0)
    error('Could not start OpenDSS');
end
DSSText = DSSObj.Text;
DSSCircuit = DSSObj.ActiveCircuit;
DSSSolution = DSSCircuit.Solution;

%% DSS file directory
dssPath = fileparts(mfilename('fullpath'));

%% ========== TEST 1: End-of-line fault ==========
fprintf('\n=== TEST 1: End-of-line fault (d=60km) ===\n');

fault_names = {'ABC', 'AC', 'BC', 'AB'};
results_analytical = zeros(4, 3);
results_opendss = zeros(4, 3);

for type = 1:4
    [Raf, Rbf, Rcf] = defineFaltaT2F(type, Rf_base);
    
    % Analytical calculation
    [IA_a, IB_a, IC_a] = calcCurtoT2F(Zp, Zm, d_base, 1, rti, rtc, ...
                                        Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f);
    results_analytical(type, :) = [IA_a, IB_a, IC_a];
    
    % OpenDSS
    DSSText.Command = ['Compile "' fullfile(dssPath, 'T2F_Base.dss') '"'];
    DSSText.Command = sprintf('Edit Line.LINHA_T2F length=%g', d_base);
    
    % Apply fault by type
    if type == 1  % ABC (three-phase)
        DSSText.Command = 'New Fault.F1 bus1=FALTA phases=3 r=0.0001';
    elseif type == 2  % AC (phase A - ground)
        DSSText.Command = sprintf('New Fault.F1 bus1=FALTA.1 phases=1 r=%g', Rf_base);
    elseif type == 3  % BC (phase B - ground)
        DSSText.Command = sprintf('New Fault.F1 bus1=FALTA.2 phases=1 r=%g', Rf_base);
    elseif type == 4  % AB (phase-to-phase)
        DSSText.Command = sprintf('New Fault.F1 bus1=FALTA.1 bus2=FALTA.2 phases=1 r=%g', Rf_base/2);
    end
    
    DSSText.Command = 'Solve';

    % Read line currents (2 phases, 2 terminals)
    DSSCircuit.SetActiveElement('Line.LINHA_T2F');
    currents = DSSCircuit.ActiveCktElement.CurrentsMagAng;
    IA_dss = currents(1);  % Phase 1 magnitude (terminal 1)
    IB_dss = currents(3);  % Phase 2 magnitude (terminal 1)
    % Ground current = vector sum of phases
    Ia_vec = currents(1)*exp(1i*currents(2)*pi/180);
    Ib_vec = currents(3)*exp(1i*currents(4)*pi/180);
    IC_dss = abs(Ia_vec + Ib_vec);  % earth return

    results_opendss(type, :) = [IA_dss, IB_dss, IC_dss];
end

% Table
fprintf('\n%-6s | %-28s | %-28s | %-8s\n', 'Fault', 'Analytical [IA IB IC](A)', 'OpenDSS [IA IB IC](A)', 'Error(%)');
fprintf('%s\n', repmat('-', 1, 80));
errors_end = zeros(4, 1);
for type = 1:4
    Ia = results_analytical(type, :);
    Id = results_opendss(type, :);
    Imax_a = max(Ia);
    Imax_d = max(Id);
    if Imax_d > 0
        err = abs(Imax_a - Imax_d) / Imax_d * 100;
    else
        err = 0;
    end
    errors_end(type) = err;
    fprintf('%-6s | %7.2f %7.2f %7.2f   | %7.2f %7.2f %7.2f   | %5.2f%%\n', ...
        fault_names{type}, Ia(1), Ia(2), Ia(3), Id(1), Id(2), Id(3), err);
end


%% ========== TEST 2: Varying line length ==========
fprintf('\n=== TEST 2: Validation by length (ABC Fault) ===\n');

d_vec = [20, 40, 60, 80, 100, 120, 180, 240];
results_d_analytical = zeros(length(d_vec), 3);
results_d_opendss = zeros(length(d_vec), 3);

[Raf, Rbf, Rcf] = defineFaltaT2F(1, Rf_base);

for id = 1:length(d_vec)
    d = d_vec(id);
    
    % Analytical
    [IA_a, IB_a, IC_a] = calcCurtoT2F(Zp, Zm, d, 1, rti, rtc, ...
                                        Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f);
    results_d_analytical(id, :) = [IA_a, IB_a, IC_a];
    
    % OpenDSS
    DSSText.Command = ['Compile "' fullfile(dssPath, 'T2F_Base.dss') '"'];
    DSSText.Command = sprintf('Edit Line.LINHA_T2F length=%g', d);
    DSSText.Command = 'New Fault.F1 bus1=FALTA phases=3 r=0.0001';
    DSSText.Command = 'Solve';
    
    DSSCircuit.SetActiveElement('Line.LINHA_T2F');
    currents = DSSCircuit.ActiveCktElement.CurrentsMagAng;
    results_d_opendss(id, :) = [currents(1), currents(3), 0];
end

fprintf('%-10s | %-12s | %-12s | %-8s\n', 'Dist(km)', 'Analytical(A)', 'OpenDSS(A)', 'Error(%)');
fprintf('%s\n', repmat('-', 1, 50));
errors_d = zeros(length(d_vec), 1);
for id = 1:length(d_vec)
    Ia_max = max(results_d_analytical(id, 1:2));
    Id_max = max(results_d_opendss(id, 1:2));
    if Id_max > 0
        err = abs(Ia_max - Id_max) / Id_max * 100;
    else
        err = 0;
    end
    errors_d(id) = err;
    fprintf('%6d    | %9.2f   | %9.2f   | %5.2f%%\n', d_vec(id), Ia_max, Id_max, err);
end

%% ========== TEST 3: Varying fault position ==========
fprintf('\n=== TEST 3: Fault along the line (ABC, d=60km) ===\n');

positions = [0.1, 0.25, 0.5, 0.75, 0.99];
results_pos_analytical = zeros(length(positions), 3);
results_pos_opendss = zeros(length(positions), 3);

for ip = 1:length(positions)
    m1 = positions(ip);
    d_fault = d_base * m1;
    d_rest = d_base * (1 - m1);
    
    % Analytical
    [IA_a, IB_a, IC_a] = calcCurtoT2F(Zp, Zm, d_base, m1, rti, rtc, ...
                                        Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f);
    results_pos_analytical(ip, :) = [IA_a, IB_a, IC_a];
    
    % OpenDSS - split line into 2 segments
    DSSText.Command = ['Compile "' fullfile(dssPath, 'T2F_Base.dss') '"'];
    DSSText.Command = 'Edit Line.LINHA_T2F Enabled=no';
    DSSText.Command = sprintf('New Line.L1 bus1=BARRAT2F.1.2 bus2=MEIO.1.2 linecode=T2F_CODE length=%g units=km', d_fault);
    DSSText.Command = sprintf('New Line.L2 bus1=MEIO.1.2 bus2=FALTA.1.2 linecode=T2F_CODE length=%g units=km', d_rest);
    
    % Grounding at fault point
    DSSText.Command = 'New Reactor.RTM phases=1 bus1=MEIO.3 bus2=MEIO.0 R=10 X=0';
    
    % Fault at midpoint
    DSSText.Command = 'New Fault.F1 bus1=MEIO phases=3 r=0.0001';
    DSSText.Command = 'Solve';
    
    DSSCircuit.SetActiveElement('Line.L1');
    currents = DSSCircuit.ActiveCktElement.CurrentsMagAng;
    results_pos_opendss(ip, :) = [currents(1), currents(3), 0];
end

fprintf('%-10s | %-12s | %-12s | %-8s\n', 'Position', 'Analytical(A)', 'OpenDSS(A)', 'Error(%)');
fprintf('%s\n', repmat('-', 1, 50));
errors_pos = zeros(length(positions), 1);
for ip = 1:length(positions)
    Ia_max = max(results_pos_analytical(ip, 1:2));
    Id_max = max(results_pos_opendss(ip, 1:2));
    if Id_max > 0
        err = abs(Ia_max - Id_max) / Id_max * 100;
    else
        err = 0;
    end
    errors_pos(ip) = err;
    fprintf('%5.0f%%     | %9.2f   | %9.2f   | %5.2f%%\n', positions(ip)*100, Ia_max, Id_max, err);
end

%% ========== TEST 4: Resistivity sensitivity (validation) ==========
fprintf('\n=== TEST 4: Resistivity sensitivity validation ===\n');

rho_vec = [100, 500, 1000, 5000, 10000];
results_rho_analytical = zeros(length(rho_vec), 3);
results_rho_opendss = zeros(length(rho_vec), 3);

for ir = 1:length(rho_vec)
    rho_val = rho_vec(ir);
    [Zp_r, Zm_r, ~, ~] = calcImpedanciasCarson(f, RI, rmgi, dij, h, rho_val);
    
    % Analytical
    [Raf, Rbf, Rcf] = defineFaltaT2F(1, Rf_base);
    [IA_a, IB_a, IC_a] = calcCurtoT2F(Zp_r, Zm_r, d_base, 1, rti, rtc, ...
                                        Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f);
    results_rho_analytical(ir, :) = [IA_a, IB_a, IC_a];
    
    % OpenDSS - update impedances
    DSSText.Command = ['Compile "' fullfile(dssPath, 'T2F_Base.dss') '"'];
    DSSText.Command = sprintf('Edit LineCode.T2F_CODE rmatrix=[%.6f | %.6f %.6f]', ...
        real(Zp_r), real(Zm_r), real(Zp_r));
    DSSText.Command = sprintf('Edit LineCode.T2F_CODE xmatrix=[%.6f | %.6f %.6f]', ...
        imag(Zp_r), imag(Zm_r), imag(Zp_r));
    DSSText.Command = sprintf('Edit Line.LINHA_T2F length=%g', d_base);
    DSSText.Command = 'New Fault.F1 bus1=FALTA phases=3 r=0.0001';
    DSSText.Command = 'Solve';
    
    DSSCircuit.SetActiveElement('Line.LINHA_T2F');
    currents = DSSCircuit.ActiveCktElement.CurrentsMagAng;
    results_rho_opendss(ir, :) = [currents(1), currents(3), 0];
end

fprintf('%-12s | %-12s | %-12s | %-8s\n', 'Rho(ohm.m)', 'Analytical(A)', 'OpenDSS(A)', 'Error(%)');
fprintf('%s\n', repmat('-', 1, 50));
errors_rho = zeros(length(rho_vec), 1);
for ir = 1:length(rho_vec)
    Ia_max = max(results_rho_analytical(ir, 1:2));
    Id_max = max(results_rho_opendss(ir, 1:2));
    if Id_max > 0
        err = abs(Ia_max - Id_max) / Id_max * 100;
    else
        err = 0;
    end
    errors_rho(ir) = err;
    fprintf('%8d    | %9.2f   | %9.2f   | %5.2f%%\n', rho_vec(ir), Ia_max, Id_max, err);
end


%% ========== PLOTS ==========
fprintf('\n=== Generating Plots ===\n');

set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 10);

% Plot 1: Validation by length
figure('Position', [100 100 700 450]);
plot(d_vec, max(results_d_analytical(:,1:2), [], 2), 'b-o', 'LineWidth', 1.5, 'MarkerSize', 7);
hold on;
plot(d_vec, max(results_d_opendss(:,1:2), [], 2), 'r--s', 'LineWidth', 1.5, 'MarkerSize', 7);
xlabel('Line Length [km]');
ylabel('Maximum Fault Current [A]');
legend({'Analytical Model', 'OpenDSS'}, 'Location', 'northeast');
grid on; box on;
saveas(gcf, 'Imagem25.png');
fprintf('Saved: Imagem25.png\n');

% Plot 2: Relative error
figure('Position', [100 100 700 350]);
bar(d_vec, errors_d, 'FaceColor', [0.3 0.6 0.9]);
xlabel('Line Length [km]');
ylabel('Relative Error [%%]');
grid on; box on;
saveas(gcf, 'Imagem26.png');
fprintf('Saved: Imagem26.png\n');

% Plot 3: Validation by position
figure('Position', [100 100 700 450]);
plot(positions*100, max(results_pos_analytical(:,1:2), [], 2), 'b-o', 'LineWidth', 1.5, 'MarkerSize', 7);
hold on;
plot(positions*100, max(results_pos_opendss(:,1:2), [], 2), 'r--s', 'LineWidth', 1.5, 'MarkerSize', 7);
xlabel('Fault Position [%% of line]');
ylabel('Maximum Fault Current [A]');
legend({'Analytical Model', 'OpenDSS'}, 'Location', 'northeast');
grid on; box on;
saveas(gcf, 'Imagem27.png');
fprintf('Saved: Imagem27.png\n');

% Plot 4: Resistivity validation
figure('Position', [100 100 700 450]);
semilogx(rho_vec, max(results_rho_analytical(:,1:2), [], 2), 'b-o', 'LineWidth', 1.5, 'MarkerSize', 7);
hold on;
semilogx(rho_vec, max(results_rho_opendss(:,1:2), [], 2), 'r--s', 'LineWidth', 1.5, 'MarkerSize', 7);
xlabel('Soil Resistivity [\Omega\cdotm]');
ylabel('Maximum Fault Current [A]');
legend({'Analytical Model', 'OpenDSS'}, 'Location', 'northeast');
grid on; box on;
saveas(gcf, 'Imagem28.png');
fprintf('Saved: Imagem28.png\n');

%% ========== EXPORT CSVs ==========
T1 = table();
T1.Fault_Type = fault_names';
T1.IA_Analytical = results_analytical(:,1);
T1.IB_Analytical = results_analytical(:,2);
T1.IC_Analytical = results_analytical(:,3);
T1.IA_OpenDSS = results_opendss(:,1);
T1.IB_OpenDSS = results_opendss(:,2);
T1.IC_OpenDSS = results_opendss(:,3);
T1.Error_pct = errors_end;
writetable(T1, fullfile(dssPath, 'validacao_fim_linha.csv'));

T2 = table();
T2.Length_km = d_vec';
T2.Imax_Analytical = max(results_d_analytical(:,1:2), [], 2);
T2.Imax_OpenDSS = max(results_d_opendss(:,1:2), [], 2);
T2.Error_pct = errors_d;
writetable(T2, fullfile(dssPath, 'validacao_comprimento.csv'));

T3 = table();
T3.Position_pct = (positions*100)';
T3.Imax_Analytical = max(results_pos_analytical(:,1:2), [], 2);
T3.Imax_OpenDSS = max(results_pos_opendss(:,1:2), [], 2);
T3.Error_pct = errors_pos;
writetable(T3, fullfile(dssPath, 'validacao_posicao.csv'));

T4 = table();
T4.Rho_ohm_m = rho_vec';
T4.Imax_Analytical = max(results_rho_analytical(:,1:2), [], 2);
T4.Imax_OpenDSS = max(results_rho_opendss(:,1:2), [], 2);
T4.Error_pct = errors_rho;
writetable(T4, fullfile(dssPath, 'validacao_resistividade.csv'));

fprintf('\n=== FINAL SUMMARY ===\n');
fprintf('Max error (length):      %.2f%%\n', max(errors_d));
fprintf('Max error (position):    %.2f%%\n', max(errors_pos));
fprintf('Max error (resistivity): %.2f%%\n', max(errors_rho));
fprintf('Max error (fault type):  %.2f%%\n', max(errors_end));
fprintf('\nOpenDSS validation completed successfully!\n');
