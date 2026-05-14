%% IEEE13_T2F_Substituicao.m
% Substitutes single-phase/two-phase sections of IEEE 13-bus with TPTW
% Compares 3 scenarios: TPTW (2 wires + ground), Three-phase (3 wires), SWER (1 wire + ground)
% Generates figures for the paper
%
% Authors: dos Santos et al. (UFSM)
% Date: 2025

clc; clear; close all;

%% ========== SYSTEM PARAMETERS ==========
f = 60;
Vbase = 13800;  % V (13.8 kV)
Vfase = Vbase / sqrt(3);

% Source impedance (SCC = 120 MVA, X/R = 7)
Scc = 120e6;
Zfonte_mod = Vbase^2 / Scc;
ang_fonte = atan(7);
Zfonte = Zfonte_mod * exp(1i * ang_fonte);

% Isolation + consumer transformers (2 in series)
% Each: 300 kVA, Z = 0.48% + j1.85% (|Z| = 1.91%)
Sn_tri = 300e3;  % VA
Ztri_pu = 0.0048119 + 1i*0.018511;
Zbase_tri = Vbase^2 / Sn_tri;
Ztri = 2 * Ztri_pu * Zbase_tri;  % 2 transformers

% Total source impedance seen by the branch
Z_fonte = Zfonte + Ztri;

%% ========== TPTW PARAMETERS (2 AWG) ==========
RI_t2f = 1.102;
rmgi_t2f = 0.00308;
dij_t2f = 1.60;
h_t2f = 10.372;
rho = 100;
rti = 10;
rtc = 10;

[Zp_t2f, Zm_t2f, Ze_t2f, ~] = calcImpedanciasCarson(f, RI_t2f, rmgi_t2f, dij_t2f, h_t2f, rho);

%% ========== CONVENTIONAL THREE-PHASE PARAMETERS ==========
Zp_trif = Zp_t2f;
Zm_trif = Zm_t2f;
Z1_pos = Zp_trif - Zm_trif;  % positive-sequence impedance

%% ========== SINGLE-PHASE (SWER) PARAMETERS ==========
Zp_mono = Zp_t2f;  % self impedance of conductor

%% ========== TEST DISTANCES ==========
distancias_teste = [0.5, 1, 2, 5, 10, 20, 40, 60];  % km

fault_names = {'ABC', 'AC', 'BC', 'AB'};
Rf = 40;  % ohm (ground fault resistance)
Rf_ab = 20;  % ohm per phase (AB fault)

fprintf('=== IEEE 13-Bus - TPTW vs Three-phase vs SWER Comparison (13.8 kV) ===\n\n');

%% ========== CALCULATION FOR EACH DISTANCE ==========

Z_fonte_total = Z_fonte;

resultados_T2F = zeros(length(distancias_teste), 4, 3);
resultados_TRIF = zeros(length(distancias_teste), 4, 3);
resultados_MONO = zeros(length(distancias_teste), 4, 3);

for id = 1:length(distancias_teste)
    d = distancias_teste(id);

    for tipo = 1:4
        if tipo == 4  % AB: 20 ohm per phase
            [Raf, Rbf, Rcf] = defineFaltaT2F(tipo, Rf_ab);
        else
            [Raf, Rbf, Rcf] = defineFaltaT2F(tipo, Rf);
        end

        %% --- TPTW (2 wires + ground) using mesh method ---
        Zs = rti + rtc + Ze_t2f;
        Z1p = Zp_t2f*d + Raf + Rcf + Zs + Z_fonte_total;
        Z2p = Zp_t2f*d + Rbf + Rcf + Zs + Z_fonte_total;
        Zmp = Zm_t2f*d + Rcf;

        Va = Vfase;
        Vb = Vfase * exp(-1i*2*pi/3);

        det_val = Z1p*Z2p - Zmp^2;
        I1 = (Va*Z2p - Vb*Zmp) / det_val;
        I2 = (Vb*Z1p - Va*Zmp) / det_val;

        IA = abs(I1);
        IB = abs(I2);
        IC = abs(I1 + I2);
        resultados_T2F(id, tipo, :) = [IA, IB, IC];

        %% --- Conventional three-phase (3 symmetric phases) ---
        if tipo == 1  % ABC (symmetric three-phase fault)
            I_trif = abs(Vfase / (Z1_pos*d + Z_fonte_total));
            Ia_trif = I_trif; Ib_trif = I_trif; Ic_trif = I_trif;
        elseif tipo == 2  % AC (single-phase-to-ground in three-phase)
            Z1 = Z1_pos*d + Z_fonte_total;
            Z2 = Z1;
            Z0 = (Zp_trif + 2*Zm_trif)*d + Z_fonte_total + 3*(rti + rtc + Ze_t2f);
            I_falta = abs(3*Vfase / (Z1 + Z2 + Z0 + 3*Rf));
            Ia_trif = I_falta; Ib_trif = 0; Ic_trif = 0;
        elseif tipo == 3  % BC (single-phase-to-ground in three-phase)
            Z1 = Z1_pos*d + Z_fonte_total;
            Z2 = Z1;
            Z0 = (Zp_trif + 2*Zm_trif)*d + Z_fonte_total + 3*(rti + rtc + Ze_t2f);
            I_falta = abs(3*Vfase / (Z1 + Z2 + Z0 + 3*Rf));
            Ia_trif = 0; Ib_trif = I_falta; Ic_trif = 0;
        elseif tipo == 4  % AB (phase-to-phase fault)
            Z1 = Z1_pos*d + Z_fonte_total;
            Z2 = Z1;
            I_falta = abs(Vfase*sqrt(3) / (Z1 + Z2 + 2*Rf_ab));
            Ia_trif = I_falta; Ib_trif = I_falta; Ic_trif = 0;
        end
        resultados_TRIF(id, tipo, :) = [Ia_trif, Ib_trif, Ic_trif];

        %% --- Single-phase SWER (1 wire + earth return) ---
        Z_swer = Zp_mono*d + Z_fonte_total + rti + rtc + Ze_t2f + Rf;
        I_mono = abs(Vfase / Z_swer);
        resultados_MONO(id, tipo, :) = [I_mono, 0, 0];
    end
end

%% ========== RESULTS TABLE ==========
fprintf('%-10s | %-6s | %-18s | %-18s | %-18s\n', ...
    'Dist (km)', 'Fault', 'TPTW (A)', 'Three-phase (A)', 'SWER (A)');
fprintf('%s\n', repmat('-', 1, 80));

for id = 1:length(distancias_teste)
    for tipo = 1:4
        It = max(squeeze(resultados_T2F(id, tipo, :)));
        Itr = max(squeeze(resultados_TRIF(id, tipo, :)));
        Im = max(squeeze(resultados_MONO(id, tipo, :)));
        fprintf('%8.1f  | %-6s | %8.1f         | %8.1f         | %8.1f\n', ...
            distancias_teste(id), fault_names{tipo}, It, Itr, Im);
    end
    if id < length(distancias_teste)
        fprintf('%s\n', repmat('-', 1, 80));
    end
end

%% ========== PLOTS ==========
fprintf('\n=== Generating Figures ===\n');

set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 10);

% --- Figure: ABC Fault ---
figure('Position', [100 100 700 450]);
Imax_t2f_abc = max(squeeze(resultados_T2F(:, 1, :)), [], 2);
Imax_trif_abc = max(squeeze(resultados_TRIF(:, 1, :)), [], 2);
Imax_mono_abc = max(squeeze(resultados_MONO(:, 1, :)), [], 2);

semilogy(distancias_teste, Imax_t2f_abc, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 7);
hold on;
semilogy(distancias_teste, Imax_trif_abc, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 7);
semilogy(distancias_teste, Imax_mono_abc, 'k--^', 'LineWidth', 1.2, 'MarkerSize', 6);
xlabel('Branch Length [km]');
ylabel('Fault Current [A]');
title('Three-Phase Fault (ABC) - 13.8 kV with Isolation Transformer');
legend({'TPTW (2 wires + ground)', 'Three-phase (3 wires)', 'SWER (1 wire + ground)'}, ...
    'Location', 'northeast');
grid on; box on;
xlim([0 65]);
saveas(gcf, 'img/Imagem20.png');
fprintf('Saved: Imagem20.png (ABC Fault)\n');

% --- Figure: AC Fault ---
figure('Position', [100 100 700 450]);
Imax_t2f_ac = max(squeeze(resultados_T2F(:, 2, :)), [], 2);
Imax_trif_ac = max(squeeze(resultados_TRIF(:, 2, :)), [], 2);
Imax_mono_ac = max(squeeze(resultados_MONO(:, 2, :)), [], 2);

semilogy(distancias_teste, Imax_t2f_ac, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 7);
hold on;
semilogy(distancias_teste, Imax_trif_ac, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 7);
semilogy(distancias_teste, Imax_mono_ac, 'k--^', 'LineWidth', 1.2, 'MarkerSize', 6);
xlabel('Branch Length [km]');
ylabel('Fault Current [A]');
title('Phase-to-Ground Fault (AC) - 13.8 kV with Isolation Transformer');
legend({'TPTW (2 wires + ground)', 'Three-phase (3 wires)', 'SWER (1 wire + ground)'}, ...
    'Location', 'northeast');
grid on; box on;
xlim([0 65]);
saveas(gcf, 'img/Imagem21.png');
fprintf('Saved: Imagem21.png (AC Fault)\n');

% --- Figure: AB Fault ---
figure('Position', [100 100 700 450]);
Imax_t2f_ab = max(squeeze(resultados_T2F(:, 4, :)), [], 2);
Imax_trif_ab = max(squeeze(resultados_TRIF(:, 4, :)), [], 2);
Imax_mono_ab = max(squeeze(resultados_MONO(:, 4, :)), [], 2);

semilogy(distancias_teste, Imax_t2f_ab, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 7);
hold on;
semilogy(distancias_teste, Imax_trif_ab, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 7);
semilogy(distancias_teste, Imax_mono_ab, 'k--^', 'LineWidth', 1.2, 'MarkerSize', 6);
xlabel('Branch Length [km]');
ylabel('Fault Current [A]');
title('Phase-to-Phase Fault (AB) - 13.8 kV with Isolation Transformer');
legend({'TPTW (2 wires + ground)', 'Three-phase (3 wires)', 'SWER (1 wire + ground)'}, ...
    'Location', 'northeast');
grid on; box on;
xlim([0 65]);
saveas(gcf, 'img/Imagem22.png');
fprintf('Saved: Imagem22.png (AB Fault)\n');

% --- Figure: All fault types - TPTW only ---
figure('Position', [100 100 700 450]);
markers = {'k-o', 'b-s', 'r-^', 'g-d'};
for tipo = 1:4
    Imax = max(squeeze(resultados_T2F(:, tipo, :)), [], 2);
    semilogy(distancias_teste, Imax, markers{tipo}, 'LineWidth', 1.5, 'MarkerSize', 7);
    hold on;
end
xlabel('Branch Length [km]');
ylabel('Fault Current [A]');
title('TPTW System - Fault Currents by Type (13.8 kV)');
legend(fault_names, 'Location', 'northeast');
grid on; box on;
xlim([0 65]);
saveas(gcf, 'img/Imagem23.png');
fprintf('Saved: Imagem23.png (TPTW all types)\n');

% --- Figure: Protection reach (recloser pickup) ---
figure('Position', [100 100 700 450]);
for tipo = 1:4
    Imax = max(squeeze(resultados_T2F(:, tipo, :)), [], 2);
    semilogy(distancias_teste, Imax, markers{tipo}, 'LineWidth', 1.5, 'MarkerSize', 7);
    hold on;
end
yline(50, 'k--', 'Pickup 50A', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
yline(100, 'k-.', 'Pickup 100A', 'LineWidth', 1.2, 'LabelHorizontalAlignment', 'left');
xlabel('TPTW Branch Length [km]');
ylabel('Fault Current [A]');
title('Protection Reach - TPTW Branch (13.8 kV)');
legend([fault_names, {'Pickup 50A', 'Pickup 100A'}], 'Location', 'northeast');
grid on; box on;
xlim([0 65]);
saveas(gcf, 'img/Imagem24.png');
fprintf('Saved: Imagem24.png (Protection reach)\n');

%% ========== EXPORT CSV ==========
T = table();
idx = 1;
for id = 1:length(distancias_teste)
    for tipo = 1:4
        T.Distance_km(idx) = distancias_teste(id);
        T.Fault_Type(idx) = fault_names(tipo);
        T.Imax_TPTW(idx) = max(squeeze(resultados_T2F(id, tipo, :)));
        T.Imax_ThreePhase(idx) = max(squeeze(resultados_TRIF(id, tipo, :)));
        T.Imax_SWER(idx) = max(squeeze(resultados_MONO(id, tipo, :)));
        idx = idx + 1;
    end
end
writetable(T, 'IEEE13_substituicao_resultados.csv');

fprintf('\n=== Complete! ===\n');
fprintf('CSV: IEEE13_substituicao_resultados.csv\n');
