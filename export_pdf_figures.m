%% export_pdf_figures.m
% Re-exports all MATLAB-generated figures as PDF (vector) for IEEE submission
% Run from: Short-Circuit-TPTW/ directory
% Works in -batch mode (no display)
%
% Problem: sub-scripts use "clear" which wipes our variables.
% Solution: save outdir to a MAT file, run sub-scripts, reload.

clc; close all;

OUTDIR = fullfile(pwd, '..', 'Artigo', 'img');
if ~exist(OUTDIR, 'dir'), mkdir(OUTDIR); end
IMGDIR = fullfile(pwd, 'img');
if ~exist(IMGDIR, 'dir'), mkdir(IMGDIR); end
save('_export_tmp.mat', 'OUTDIR', 'IMGDIR');

set(0, 'DefaultFigureVisible', 'off');

%% ===== 1. Sensitivity Analysis =====
fprintf('=== 1. Sensitivity Analysis ===\n');
run('AnaliseSensibilidade.m');
load('_export_tmp.mat', 'OUTDIR', 'IMGDIR');
figs = findobj(0, 'Type', 'figure');
if ~isempty(figs)
    [~, idx] = sort([figs.Number]);
    figs = figs(idx);
    sens_map = {'Imagem_Sensibilidade', 'Imagem18', 'Imagem19'};
    for k = 1:min(length(figs), length(sens_map))
        try
            print(figs(k), fullfile(OUTDIR, sens_map{k}), '-dpdf', '-bestfit');
            fprintf('  Exported: %s.pdf\n', sens_map{k});
        catch ME2
            fprintf('  SKIP %s: %s\n', sens_map{k}, ME2.message);
        end
    end
end
close all;

%% ===== 2. IEEE 13 Node =====
fprintf('=== 2. IEEE 13 Node Comparison ===\n');
run('IEEE13_T2F_Substituicao.m');
load('_export_tmp.mat', 'OUTDIR', 'IMGDIR');
figs = findobj(0, 'Type', 'figure');
if ~isempty(figs)
    [~, idx] = sort([figs.Number]);
    figs = figs(idx);
    fig_map = {'Imagem20', 'Imagem21', 'Imagem22', 'Imagem23', 'Imagem24'};
    for k = 1:min(length(figs), length(fig_map))
        try
            print(figs(k), fullfile(OUTDIR, fig_map{k}), '-dpdf', '-bestfit');
            fprintf('  Exported: %s.pdf\n', fig_map{k});
        catch ME2
            fprintf('  SKIP %s: %s\n', fig_map{k}, ME2.message);
        end
    end
else
    fprintf('  No figures found (script may have closed them)\n');
end
close all;

%% ===== 3. IEEE 13 Unifilar Diagram =====
fprintf('=== 3. IEEE 13 Unifilar Diagram ===\n');
run(fullfile('..', 'Artigo', 'gerar_fig_ieee13.m'));
load('_export_tmp.mat', 'OUTDIR', 'IMGDIR');
figs = findobj(0, 'Type', 'figure');
if ~isempty(figs)
    [~, idx] = sort([figs.Number]);
    figs = figs(idx);
    for k = 1:length(figs)
        try
            print(figs(k), fullfile(OUTDIR, 'Imagem_IEEE13_T2F'), '-dpdf', '-bestfit');
            fprintf('  Exported: Imagem_IEEE13_T2F.pdf\n');
        catch ME2
            fprintf('  SKIP: %s\n', ME2.message);
        end
    end
end
close all;

%% ===== 4. OpenDSS Validation =====
fprintf('=== 4. OpenDSS Validation ===\n');
CURDIR = pwd;
save('_export_tmp.mat', 'OUTDIR', 'IMGDIR', 'CURDIR');
cd('OpenDSS');
try
    run('ValidacaoOpenDSS.m');
    load(fullfile('..', '_export_tmp.mat'), 'OUTDIR', 'CURDIR');
    figs = findobj(0, 'Type', 'figure');
    if ~isempty(figs)
        [~, idx] = sort([figs.Number]);
        figs = figs(idx);
        val_map = {'Imagem25', 'Imagem26', 'Imagem27', 'Imagem28'};
        for k = 1:min(length(figs), length(val_map))
            try
                print(figs(k), fullfile(OUTDIR, val_map{k}), '-dpdf', '-bestfit');
                fprintf('  Exported: %s.pdf\n', val_map{k});
            catch ME2
                fprintf('  SKIP %s: %s\n', val_map{k}, ME2.message);
            end
        end
    end
catch ME
    fprintf('  WARNING: OpenDSS not available - %s\n', ME.message);
    fprintf('  Pre-computed results in OpenDSS/*.csv\n');
    load(fullfile('..', '_export_tmp.mat'), 'CURDIR');
end
cd(CURDIR);
close all;

%% ===== 5. Validation Figures (Python) =====
fprintf('=== 5. Simulink Validation Figures (Python) ===\n');
if ispc
    [status, result] = system('python gerar_figuras_validacao.py');
else
    [status, result] = system('python3 gerar_figuras_validacao.py');
end
if status == 0
    fprintf('  %s\n', strtrim(result));
else
    fprintf('  WARNING: Python script failed. Run manually:\n');
    fprintf('    python gerar_figuras_validacao.py\n');
end

%% ===== Cleanup =====
set(0, 'DefaultFigureVisible', 'on');
if exist('_export_tmp.mat', 'file'), delete('_export_tmp.mat'); end

fprintf('\n=== Export Complete ===\n');
fprintf('PDF files in: %s\n', OUTDIR);
fprintf('\nFigures exported as PDF (vector):\n');
fprintf('  Imagem_Sensibilidade.pdf  - Sensitivity (3 subplots: rho, d, Rf)\n');
fprintf('  Imagem18.pdf              - Sensitivity: conductor spacing\n');
fprintf('  Imagem19.pdf              - Sensitivity: grounding resistance\n');
fprintf('  Imagem20.pdf              - IEEE 13: ABC fault comparison\n');
fprintf('  Imagem21.pdf              - IEEE 13: AC fault comparison\n');
fprintf('  Imagem22.pdf              - IEEE 13: AB fault comparison\n');
fprintf('  Imagem23.pdf              - IEEE 13: TPTW all fault types\n');
fprintf('  Imagem24.pdf              - IEEE 13: Protection reach\n');
fprintf('  Imagem25.pdf              - OpenDSS: validation by length\n');
fprintf('  Imagem26.pdf              - OpenDSS: relative error bar chart\n');
fprintf('  Imagem27.pdf              - OpenDSS: validation by position\n');
fprintf('  Imagem28.pdf              - OpenDSS: resistivity validation\n');
fprintf('  Imagem_IEEE13_T2F.pdf     - IEEE 13 unifilar diagram\n');
fprintf('\nFigures as PNG (from Python/Simulink data):\n');
fprintf('  Imagem10.png              - Simulink validation: end-of-line error\n');
fprintf('  Imagem11.png              - Simulink validation: ABC fault vs position\n');
fprintf('\nCircuit diagrams (PNG, 300 dpi): Imagem1-5\n');
