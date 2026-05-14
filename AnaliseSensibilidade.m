%% AnaliseSensibilidade.m
% Parametric sensitivity analysis of TPTW short-circuit
% Varies: soil resistivity, length, Rf, spacing, grounding resistance
% Does not require Simulink - purely analytical
%
% Authors: dos Santos et al. (UFSM)
% Date: 2025

clc; clear; close all;

%% Base parameters (reference case)
f = 60;                    % Frequency (Hz)
RI = 1.102;                % AC resistance 2 AWG (ohm/km)
rmgi = 0.00308;            % Geometric mean radius (m)
dij_base = 1.60;           % Conductor spacing (m)
h = 10.372;                % Conductor height (m)
rho_base = 100;            % Soil resistivity (ohm.m)
d_base = 60;               % Line length (km)
rti_base = 10;             % Isolation transformer grounding resistance (ohm)
rtc = 10;                  % Consumer transformer grounding resistance (ohm)
Vbase = 13800;             % Base voltage (V)
SCC = 120;                 % Short-circuit power (MVA)
Ztri_pu = 0.0048119 + 1i*0.018511;  % Transformer impedance (pu)
Rf_base = 40;              % Base fault resistance (ohm)

%% Variation vectors
rho_vec = [100, 500, 1000, 5000, 10000];       % ohm.m
d_vec = [20, 40, 60, 80, 100, 120, 180, 240];  % km
Rf_vec = [0.001, 10, 20, 40, 80, 100];         % ohm
dij_vec = [0.5, 0.92, 1.2, 1.6, 2.0];          % m
rti_vec = [5, 10, 15, 20, 30];                  % ohm

%% Fault type definitions
fault_names = {'ABC', 'AC', 'BC', 'AB'};

%% ========== SENSITIVITY 1: Soil Resistivity ==========
fprintf('=== Sensitivity: Soil Resistivity ===\n');
results_rho = zeros(length(rho_vec), 4, 3);

for ir = 1:length(rho_vec)
    rho = rho_vec(ir);
    [Zp, Zm, ~, ~] = calcImpedanciasCarson(f, RI, rmgi, dij_base, h, rho);
    for type = 1:4
        [Raf, Rbf, Rcf] = defineFaltaT2F(type, Rf_base);
        [IA, IB, IC] = calcCurtoT2F(Zp, Zm, d_base, 1, rti_base, rtc, ...
                                      Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f);
        results_rho(ir, type, :) = [IA, IB, IC];
    end
end

%% ========== SENSITIVITY 2: Line Length ==========
fprintf('=== Sensitivity: Line Length ===\n');
[Zp, Zm, ~, ~] = calcImpedanciasCarson(f, RI, rmgi, dij_base, h, rho_base);
results_d = zeros(length(d_vec), 4, 3);

for id = 1:length(d_vec)
    d = d_vec(id);
    for type = 1:4
        [Raf, Rbf, Rcf] = defineFaltaT2F(type, Rf_base);
        [IA, IB, IC] = calcCurtoT2F(Zp, Zm, d, 1, rti_base, rtc, ...
                                      Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f);
        results_d(id, type, :) = [IA, IB, IC];
    end
end

%% ========== SENSITIVITY 3: Fault Resistance ==========
fprintf('=== Sensitivity: Fault Resistance ===\n');
results_Rf = zeros(length(Rf_vec), 4, 3);

for irf = 1:length(Rf_vec)
    Rf = Rf_vec(irf);
    for type = 1:4
        [Raf, Rbf, Rcf] = defineFaltaT2F(type, Rf);
        [IA, IB, IC] = calcCurtoT2F(Zp, Zm, d_base, 1, rti_base, rtc, ...
                                      Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f);
        results_Rf(irf, type, :) = [IA, IB, IC];
    end
end

%% ========== SENSITIVITY 4: Conductor Spacing ==========
fprintf('=== Sensitivity: Conductor Spacing ===\n');
results_dij = zeros(length(dij_vec), 4, 3);

for idij = 1:length(dij_vec)
    dij = dij_vec(idij);
    [Zp_v, Zm_v, ~, ~] = calcImpedanciasCarson(f, RI, rmgi, dij, h, rho_base);
    for type = 1:4
        [Raf, Rbf, Rcf] = defineFaltaT2F(type, Rf_base);
        [IA, IB, IC] = calcCurtoT2F(Zp_v, Zm_v, d_base, 1, rti_base, rtc, ...
                                      Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f);
        results_dij(idij, type, :) = [IA, IB, IC];
    end
end

%% ========== SENSITIVITY 5: Grounding Resistance ==========
fprintf('=== Sensitivity: Grounding Resistance ===\n');
results_rti = zeros(length(rti_vec), 4, 3);

for irti = 1:length(rti_vec)
    rti = rti_vec(irti);
    for type = 1:4
        [Raf, Rbf, Rcf] = defineFaltaT2F(type, Rf_base);
        [IA, IB, IC] = calcCurtoT2F(Zp, Zm, d_base, 1, rti, rtc, ...
                                      Raf, Rbf, Rcf, Vbase, SCC, Ztri_pu, f);
        results_rti(irti, type, :) = [IA, IB, IC];
    end
end

%% ========== PLOTS ==========
fprintf('=== Generating Plots ===\n');

set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 10);
markers = {'k-o', 'b-s', 'r-^', 'g-d'};

figure('Position', [100 100 800 900]);

subplot(3,1,1);
for type = 1:4
    Imax = max(squeeze(results_rho(:, type, :)), [], 2);
    semilogx(rho_vec, Imax, markers{type}, 'LineWidth', 1.2, 'MarkerSize', 6);
    hold on;
end
xlabel('Soil Resistivity (\rho) [\Omega\cdotm]');
ylabel('Fault Current [A]');
title('(a) Sensitivity to \rho');
legend(fault_names, 'Location', 'best');
grid on; box on;

subplot(3,1,2);
for type = 1:4
    Imax = max(squeeze(results_d(:, type, :)), [], 2);
    plot(d_vec, Imax, markers{type}, 'LineWidth', 1.2, 'MarkerSize', 6);
    hold on;
end
xlabel('Line Length [km]');
ylabel('Fault Current [A]');
title('(b) Sensitivity to length d');
legend(fault_names, 'Location', 'best');
grid on; box on;

subplot(3,1,3);
for type = 1:4
    Imax = max(squeeze(results_Rf(:, type, :)), [], 2);
    plot(Rf_vec, Imax, markers{type}, 'LineWidth', 1.2, 'MarkerSize', 6);
    hold on;
end
xlabel('Fault Resistance [\Omega]');
ylabel('Fault Current [A]');
title('(c) Sensitivity to R_f');
legend(fault_names, 'Location', 'best');
grid on; box on;

saveas(gcf, 'img/Imagem_Sensibilidade.png');
fprintf('Saved: Imagem_Sensibilidade.png (3 subplots)\n');

figure('Position', [100 100 600 400]);
for type = 1:4
    Imax = max(squeeze(results_dij(:, type, :)), [], 2);
    plot(dij_vec, Imax, markers{type}, 'LineWidth', 1.2, 'MarkerSize', 6);
    hold on;
end
xlabel('Conductor Spacing [m]');
ylabel('Fault Current [A]');
legend(fault_names, 'Location', 'best');
grid on; box on;
saveas(gcf, 'img/Imagem18.png');

figure('Position', [100 100 600 400]);
for type = 1:4
    Imax = max(squeeze(results_rti(:, type, :)), [], 2);
    plot(rti_vec, Imax, markers{type}, 'LineWidth', 1.2, 'MarkerSize', 6);
    hold on;
end
xlabel('Grounding Resistance [\Omega]');
ylabel('Fault Current [A]');
legend(fault_names, 'Location', 'best');
grid on; box on;
saveas(gcf, 'img/Imagem19.png');

%% ========== EXPORT CSVs ==========
fprintf('=== Exporting CSVs ===\n');

T_rho = array2table([rho_vec', squeeze(results_rho(:,1,1)), squeeze(results_rho(:,2,1)), ...
    squeeze(results_rho(:,3,2)), squeeze(results_rho(:,4,1))], ...
    'VariableNames', {'Rho_ohm_m', 'I_ABC_A', 'I_AC_A', 'I_BC_A', 'I_AB_A'});
writetable(T_rho, 'sensibilidade_resistividade.csv');

T_d = array2table([d_vec', squeeze(results_d(:,1,1)), squeeze(results_d(:,2,1)), ...
    squeeze(results_d(:,3,2)), squeeze(results_d(:,4,1))], ...
    'VariableNames', {'Length_km', 'I_ABC_A', 'I_AC_A', 'I_BC_A', 'I_AB_A'});
writetable(T_d, 'sensibilidade_comprimento.csv');

T_Rf = array2table([Rf_vec', squeeze(results_Rf(:,1,1)), squeeze(results_Rf(:,2,1)), ...
    squeeze(results_Rf(:,3,2)), squeeze(results_Rf(:,4,1))], ...
    'VariableNames', {'Rf_ohm', 'I_ABC_A', 'I_AC_A', 'I_BC_A', 'I_AB_A'});
writetable(T_Rf, 'sensibilidade_Rf.csv');

T_dij = array2table([dij_vec', squeeze(results_dij(:,1,1)), squeeze(results_dij(:,2,1)), ...
    squeeze(results_dij(:,3,2)), squeeze(results_dij(:,4,1))], ...
    'VariableNames', {'Spacing_m', 'I_ABC_A', 'I_AC_A', 'I_BC_A', 'I_AB_A'});
writetable(T_dij, 'sensibilidade_espacamento.csv');

T_rti = array2table([rti_vec', squeeze(results_rti(:,1,1)), squeeze(results_rti(:,2,1)), ...
    squeeze(results_rti(:,3,2)), squeeze(results_rti(:,4,1))], ...
    'VariableNames', {'Rti_ohm', 'I_ABC_A', 'I_AC_A', 'I_BC_A', 'I_AB_A'});
writetable(T_rti, 'sensibilidade_aterramento.csv');

%% ========== SENSITIVITY INDEX SUMMARY TABLE ==========
fprintf('\n=== SENSITIVITY SUMMARY TABLE (ABC fault, phase A) ===\n');
fprintf('%-25s | %-15s | %-12s | %-12s | %-10s\n', ...
    'Parameter', 'Range', 'I variation(%)', 'Elasticity', 'Class.');
fprintf('%s\n', repmat('-', 1, 80));

calc_elast = @(I_ini, I_fim, p_ini, p_fim) ((I_fim-I_ini)/I_ini) / ((p_fim-p_ini)/p_ini);

dI_rho = (results_rho(end,1,1)-results_rho(1,1,1))/results_rho(1,1,1)*100;
S_rho = calc_elast(results_rho(1,1,1), results_rho(end,1,1), rho_vec(1), rho_vec(end));
fprintf('%-25s | %-15s | %+8.1f%%    | %+8.4f    | %-10s\n', ...
    'Resistivity (rho)', '100-10000 ohm.m', dI_rho, S_rho, classif_sens(S_rho));

dI_d = (results_d(end,1,1)-results_d(1,1,1))/results_d(1,1,1)*100;
S_d = calc_elast(results_d(1,1,1), results_d(end,1,1), d_vec(1), d_vec(end));
fprintf('%-25s | %-15s | %+8.1f%%    | %+8.4f    | %-10s\n', ...
    'Length (d)', '20-240 km', dI_d, S_d, classif_sens(S_d));

dI_Rf = (results_Rf(end,1,1)-results_Rf(1,1,1))/results_Rf(1,1,1)*100;
S_Rf = calc_elast(results_Rf(1,1,1), results_Rf(end,1,1), Rf_vec(1), Rf_vec(end));
fprintf('%-25s | %-15s | %+8.1f%%    | %+8.4f    | %-10s\n', ...
    'Fault resistance (Rf)', '0-100 ohm', dI_Rf, S_Rf, classif_sens(S_Rf));

dI_dij = (results_dij(end,1,1)-results_dij(1,1,1))/results_dij(1,1,1)*100;
S_dij = calc_elast(results_dij(1,1,1), results_dij(end,1,1), dij_vec(1), dij_vec(end));
fprintf('%-25s | %-15s | %+8.1f%%    | %+8.4f    | %-10s\n', ...
    'Spacing (dij)', '0.5-2.0 m', dI_dij, S_dij, classif_sens(S_dij));

dI_rti = (results_rti(end,1,1)-results_rti(1,1,1))/results_rti(1,1,1)*100;
S_rti = calc_elast(results_rti(1,1,1), results_rti(end,1,1), rti_vec(1), rti_vec(end));
fprintf('%-25s | %-15s | %+8.1f%%    | %+8.4f    | %-10s\n', ...
    'Grounding (rti)', '5-30 ohm', dI_rti, S_rti, classif_sens(S_rti));

fprintf('\nCriterion: |S| > 0.5 = High, 0.1 < |S| < 0.5 = Medium, |S| < 0.1 = Low\n');
fprintf('S = elasticity = (dI/I)/(dp/p)\n');

T_sens = table();
T_sens.Parameter = {'Resistivity'; 'Length'; 'Fault_resistance'; 'Spacing'; 'Grounding'};
T_sens.I_variation_pct = [dI_rho; dI_d; dI_Rf; dI_dij; dI_rti];
T_sens.Elasticity = [S_rho; S_d; S_Rf; S_dij; S_rti];
T_sens.Classification = {classif_sens(S_rho); classif_sens(S_d); classif_sens(S_Rf); classif_sens(S_dij); classif_sens(S_rti)};
writetable(T_sens, 'sensibilidade_indices.csv');

fprintf('\nSensitivity analysis complete! Figures and CSVs saved.\n');

%% Classification function
function c = classif_sens(S)
    if abs(S) > 0.5
        c = 'HIGH';
    elseif abs(S) > 0.1
        c = 'MEDIUM';
    else
        c = 'LOW';
    end
end
