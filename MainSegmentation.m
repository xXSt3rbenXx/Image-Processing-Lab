close all; clc; % Pulizia iniziale per non duplicare finestre

% 1. Scegli quale sottocartella analizzare (Cambia il nome qui sotto)
% Esempi: '1. Microaneurysms', '2. Haemorrhages', '3. Hard Exudates', ecc.
tipoLesione = '2. Haemorrhages'; 
folderImg = '.\IDRiD\A. Segmentation\1. Original Images\a. Training Set';

% FOLDER RELATIVO AL TIPO DI LESIONE (VOLENDO POTREMMO ANCHE FARE 5 FILE
% DIVERSI OPPURE FAR ESPOLDERE QUESTO STAMPANDO OGNI VOLTA TUTTE I CASI
% POSSIBILI)
folderGT = fullfile('.\IDRiD\A. Segmentation\2. All Segmentation Groundtruths\a. Training Set', tipoLesione);

% Caricamento liste
files = dir(fullfile(folderImg, '*.jpg'));
gtFiles = dir(fullfile(folderGT, '*.tif')); % QUI LAVORIAMO DENTRO LA SOTTOCARTELLA 

if isempty(gtFiles)
    error('Cartella GT non trovata o vuota: %s', folderGT);
end

%APPLICO IL PREPROCESSING ALLE PRIME 5 IMMAGINI
%C'È UN INFAMONE results = cell(1,5); DEVONO ESSERE UGUALI!!
numImmagini = 5; 
results = PreprocessingSegmentation(folderImg); 

for k = 1:numImmagini
    % Per sicurezza, cerchiamo il file GT che ha lo stesso nome del file originale
    % Esempio: IDRiD_01.jpg -> cerchiamo IDRiD_01_MA.tif (o simile)
    nomeBase = files(k).name(1:8); % Prende "IDRiD_01"
    
    % Cerchiamo nella lista gtFiles il file che contiene "IDRiD_01"
    indiceGT = find(contains({gtFiles.name}, nomeBase));
    
    if ~isempty(indiceGT)
        gtPath = fullfile(gtFiles(indiceGT).folder, gtFiles(indiceGT).name);
        groundTruth = imread(gtPath);
        
        % Recupero le due segmentazioni dalla cella 5x2
        segmentedIter = results{k, 1};
        segmentedOtsu = results{k, 2};
        
        figure('Name', ['Test: ', nomeBase], 'NumberTitle', 'off');
        
        %STAMPIAMO IMMAGINE SEGMENTATA ITERATIVA
        subplot(1,3,1);
        imshow(segmentedIter); 
        title(['ITERATIVA: ', files(k).name], 'FontSize', 8);
        
        %STAMPIAMO IMMAGINE SEGMENTATA OTSU
        subplot(1,3,2);
        imshow(segmentedOtsu); 
        title(['OTSU: ', files(k).name], 'FontSize', 8);
        
        %STAMPIAMO TIPO LESIONE SEGMENTATA
        subplot(1,3,3);
        imshow(groundTruth, []); 
        title(['GT: ', gtFiles(indiceGT).name], 'FontSize', 8);
        
        drawnow; 
    else
        fprintf('GT non trovata per %s\n', nomeBase);
    end
end