%% run_all.m
% Master script - runs all analyses and generates all figures
% No Simulink required - uses pre-computed CSV data
%
% Usage: run_all
%
% Authors: dos Santos et al. (UFSM)
% Date: 2025

clc; clear; close all;
fprintf('========================================\n');
fprintf(' TPTW Short-Circuit Analysis - Run All\n');
fprintf('========================================\n\n');

%% Create output directory
if ~exist('img', 'dir')
    mkdir('img');
end

%% Step 1: Sensitivity Analysis
fprintf('[1/4] Running sensitivity analysis...\n');
run('AnaliseSensibilidade.m');
close all;
fprintf('      Done.\n\n');

%% Step 2: IEEE 13-Bus Comparison
fprintf('[2/4] Running IEEE 13-bus comparison...\n');
run('IEEE13_T2F_Substituicao.m');
close all;
fprintf('      Done.\n\n');

%% Step 3: Generate validation figures from CSV (Python)
fprintf('[3/4] Generating validation figures (Python)...\n');
if ispc
    [status, result] = system('python gerar_figuras_validacao.py');
else
    [status, result] = system('python3 gerar_figuras_validacao.py');
end
if status == 0
    fprintf('      %s\n', result);
else
    fprintf('      WARNING: Python script failed. Run manually:\n');
    fprintf('        python gerar_figuras_validacao.py\n');
    fprintf('      Error: %s\n', result);
end
fprintf('\n');

%% Step 4: OpenDSS Validation (optional - requires OpenDSS)
fprintf('[4/4] OpenDSS validation...\n');
try
    DSSObj = actxserver('OpenDSSEngine.DSS');
    DSSObj.delete;
    fprintf('      OpenDSS detected. Running validation...\n');
    cd('OpenDSS');
    run('ValidacaoOpenDSS.m');
    cd('..');
    close all;
    fprintf('      Done.\n\n');
catch
    fprintf('      OpenDSS not installed - skipping.\n');
    fprintf('      Pre-computed results available in OpenDSS/*.csv\n\n');
end

%% Summary
fprintf('========================================\n');
fprintf(' All analyses complete!\n');
fprintf('========================================\n');
fprintf('\n Output files:\n');
fprintf('   img/Imagem_Sensibilidade.png  - Sensitivity analysis (3 subplots)\n');
fprintf('   img/Imagem10.png              - Simulink validation: end-of-line error\n');
fprintf('   img/Imagem11.png              - Simulink validation: ABC fault vs position\n');
fprintf('   img/Imagem18.png              - Sensitivity: conductor spacing\n');
fprintf('   img/Imagem19.png              - Sensitivity: grounding resistance\n');
fprintf('   img/Imagem20.png              - IEEE 13: ABC fault comparison\n');
fprintf('   img/Imagem21.png              - IEEE 13: AC fault comparison\n');
fprintf('   img/Imagem22.png              - IEEE 13: AB fault comparison\n');
fprintf('   img/Imagem23.png              - IEEE 13: TPTW all fault types\n');
fprintf('   img/Imagem24.png              - IEEE 13: Protection reach\n');
fprintf('\n CSV files:\n');
fprintf('   sensibilidade_*.csv           - Sensitivity results\n');
fprintf('   IEEE13_substituicao_resultados.csv - IEEE 13-bus results\n');
fprintf('   OpenDSS/validacao_*.csv       - OpenDSS validation results\n');
