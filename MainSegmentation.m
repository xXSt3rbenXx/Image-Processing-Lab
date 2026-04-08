close all; clc;

% ===================== PATH =====================
folderImg = '.\IDRiD\A. Segmentation\1. Original Images\a. Training Set';

folderMicroaneurysms = fullfile('.\IDRiD\A. Segmentation\2. All Segmentation Groundtruths\a. Training Set\1. Microaneurysms');
folderHaemorrhages   = fullfile('.\IDRiD\A. Segmentation\2. All Segmentation Groundtruths\a. Training Set\2. Haemorrhages');
folderHardExudates   = fullfile('.\IDRiD\A. Segmentation\2. All Segmentation Groundtruths\a. Training Set\3. Hard Exudates');
folderSoftExudates   = fullfile('.\IDRiD\A. Segmentation\2. All Segmentation Groundtruths\a. Training Set\4. Soft Exudates');
folderOpticDisc      = fullfile('.\IDRiD\A. Segmentation\2. All Segmentation Groundtruths\a. Training Set\5. Optic Disc');

% ===================== FILES =====================
files               = dir(fullfile(folderImg, '*.jpg'));
filesMicroaneurysms = dir(fullfile(folderMicroaneurysms, '*.tif'));
filesHaemorrhages   = dir(fullfile(folderHaemorrhages,   '*.tif'));
filesHardExudates   = dir(fullfile(folderHardExudates,   '*.tif'));
filesOpticDisc      = dir(fullfile(folderOpticDisc,      '*.tif'));

% SOFT EXUDATES — concatena tif e tiff poi ORDINA PER NOME
filesSoftExudates   = [dir(fullfile(folderSoftExudates, '*.tif')); ...
                       dir(fullfile(folderSoftExudates, '*.tiff'))];
[~, sortIdx]        = sort({filesSoftExudates.name});
filesSoftExudates   = filesSoftExudates(sortIdx);

if isempty(files)
    error('Cartella immagini vuota');
end

% ===================== NUMERO IMMAGINI =====================
startImg    = 1;
numImmagini = 5;

% ===================== PREPROCESSING =====================
results   = PreprocessingSegmentation(folderImg,   startImg, numImmagini);
resultsOD = PreprocessingOpticDisc(folderImg,      startImg, numImmagini);
resultsMA = PreprocessingMicroaneurysms(folderImg, startImg, numImmagini);
resultsSE = PreprocessingSoftExudates(folderImg,   startImg, numImmagini);
resultsEX = PreprocessingHardExudates(folderImg,   startImg, numImmagini);
resultsHE = PreprocessingHaemorragies(folderImg,   startImg, numImmagini);

% ===================== LOOP =====================
for k = startImg:numImmagini

    nomeBase = files(k).name(1:8);
    idx      = k - startImg + 1;

    % Trova indici GT
    idxMA = find(contains({filesMicroaneurysms.name}, nomeBase));
    idxHE = find(contains({filesHaemorrhages.name},   nomeBase));
    idxEX = find(contains({filesHardExudates.name},   nomeBase));
    idxSE = find(contains({filesSoftExudates.name},   nomeBase));
    idxOD = find(contains({filesOpticDisc.name},      nomeBase));

    if isempty(idxMA) || isempty(idxHE) || isempty(idxEX) || isempty(idxOD)
        fprintf('Errore: GT mancante per %s\n', nomeBase);
        continue;
    end

    % ===================== CARICAMENTO GT =====================
    gt_MA = imread(fullfile(filesMicroaneurysms(idxMA).folder, filesMicroaneurysms(idxMA).name));
    if size(gt_MA,3)==3; gt_MA = rgb2gray(gt_MA); end
    gt_MA = gt_MA > 0;

    gt_HE = imread(fullfile(filesHaemorrhages(idxHE).folder, filesHaemorrhages(idxHE).name));
    if size(gt_HE,3)==3; gt_HE = rgb2gray(gt_HE); end
    gt_HE = gt_HE > 0;

    gt_EX = imread(fullfile(filesHardExudates(idxEX).folder, filesHardExudates(idxEX).name));
    if size(gt_EX,3)==3; gt_EX = rgb2gray(gt_EX); end
    gt_EX = gt_EX > 0;

    % SOFT EXUDATES OPZIONALI — non tutte le immagini le hanno
    if ~isempty(idxSE)
        gt_SE = imread(fullfile(filesSoftExudates(idxSE).folder, filesSoftExudates(idxSE).name));
        if size(gt_SE,3)==3; gt_SE = rgb2gray(gt_SE); end
        gt_SE = gt_SE > 0;
    else
        gt_SE = false(size(gt_EX)); % maschera nera vuota
    end

    gt_OD = imread(fullfile(filesOpticDisc(idxOD).folder, filesOpticDisc(idxOD).name));
    if size(gt_OD,3)==3; gt_OD = rgb2gray(gt_OD); end
    gt_OD = gt_OD > 0;

    % ===================== RISULTATI =====================
    startingImg   = results{idx, 3};
    segmentedIter = logical(results{idx, 1});
    segmentedOtsu = logical(results{idx, 2});


    % ===================== METRICHE =====================
    m_MA = EvaluationSegmentation(resultsMA{idx,1}, resultsMA{idx,2}, gt_MA);
    m_HE = EvaluationSegmentation(resultsHE{idx,1}, resultsHE{idx,2}, gt_HE);
    m_EX = EvaluationSegmentation(resultsEX{idx,1}, resultsEX{idx,2}, gt_EX);
    m_SE = EvaluationSegmentation(resultsSE{idx,1}, resultsSE{idx,2}, gt_SE);
    m_OD = EvaluationSegmentation(resultsOD{idx,1}, resultsOD{idx,2}, gt_OD);

    % ===================== STAMPA =====================
    fprintf('\n=== %s ===\n', nomeBase);
    fprintf('%-20s %-8s %-8s %-8s %-8s | %-8s %-8s %-8s %-8s\n', ...
        'Lesione','AccAdpt','DiceAdpt','SensAdpt','SpecAdpt','AccOt','DiceOt','SensOt','SpecOt');
    printRow('Microaneurismi', m_MA);
    printRow('Emorragie',      m_HE);
    printRow('Essudati Duri',  m_EX);
    printRow('Essudati Deboli',m_SE);
    printRow('Disco Ottico',   m_OD);

    % ===================== FIGURA =====================
    figure(idx)
    clf;
    set(gcf, 'Name', ['Test: ', nomeBase], 'NumberTitle', 'off');

    subplot(2,4,1)
    imshow(startingImg)   
    title('Originale')
    subplot(2,4,2)
    imshow(segmentedIter)
    title('Iterativa')
    xlabel(makeLabel(m_MA, m_HE, m_EX, m_SE, m_OD, 'iter'), 'FontSize', 8)
    subplot(2,4,3)
    imshow(segmentedOtsu)
    title('Otsu')
    xlabel(makeLabel(m_MA, m_HE, m_EX, m_SE, m_OD, 'otsu'), 'FontSize', 8)
    subplot(2,4,4)
    imshow(gt_MA)
    title('Microaneurismi')
    subplot(2,4,5)
    imshow(gt_HE)
    title('Emorragie')
    subplot(2,4,6)
    imshow(gt_EX)
    title('Hard Exudates')
    subplot(2,4,7)
    imshow(gt_SE)
    title('Soft Exudates')
    subplot(2,4,8)
    imshow(gt_OD)
    title('Optic Disc')
    drawnow;

end

% ===================== FUNZIONI DI SUPPORTO =====================
function printRow(name, m)
    fprintf('%-20s %6.2f %6.2f %5.2f %5.2f | %6.2f %6.2f %5.2f %5.2f\n', ...
        name, ...
        m.iter.accuracy*100, m.iter.dice*100, m.iter.sensitivity*100, m.iter.specificity*100, ...
        m.otsu.accuracy*100, m.otsu.dice*100, m.otsu.sensitivity*100, m.otsu.specificity*100);
end

function label = makeLabel(m_MA, m_HE, m_EX, m_SE, m_OD, type)
    if strcmp(type,'iter')
        label = {
            sprintf('MA A=%.1f D=%.1f', m_MA.iter.accuracy*100, m_MA.iter.dice*100)
            sprintf('HE A=%.1f D=%.1f', m_HE.iter.accuracy*100, m_HE.iter.dice*100)
            sprintf('EX A=%.1f D=%.1f', m_EX.iter.accuracy*100, m_EX.iter.dice*100)
            sprintf('SE A=%.1f D=%.1f', m_SE.iter.accuracy*100, m_SE.iter.dice*100)
            sprintf('OD A=%.1f D=%.1f', m_OD.iter.accuracy*100, m_OD.iter.dice*100)
        };
    else
        label = {
            sprintf('MA A=%.1f D=%.1f', m_MA.otsu.accuracy*100, m_MA.otsu.dice*100)
            sprintf('HE A=%.1f D=%.1f', m_HE.otsu.accuracy*100, m_HE.otsu.dice*100)
            sprintf('EX A=%.1f D=%.1f', m_EX.otsu.accuracy*100, m_EX.otsu.dice*100)
            sprintf('SE A=%.1f D=%.1f', m_SE.otsu.accuracy*100, m_SE.otsu.dice*100)
            sprintf('OD A=%.1f D=%.1f', m_OD.otsu.accuracy*100, m_OD.otsu.dice*100)
        };
    end
end