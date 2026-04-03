function results = PreprocessingMicroaneurysms(folder,startImg, numImages)
files = dir(fullfile(folder, '*.jpg'));
results = cell(numImages, 3);

for k = startImg:numImages
    filename = fullfile(folder, files(k).name);
    startingImg = imread(filename);

    % Canale verde
    green_double = im2double(startingImg(:,:,2));

    % Background subtraction con sigma piccolo per preservare i MA
    subtracted = green_double - imgaussfilt(green_double, 15);
    subtracted = subtracted - min(subtracted(:));
    subtracted = subtracted / max(subtracted(:));

    % CLAHE su regioni piccole per esaltare dettagli fini
    green_ma_clahe = adapthisteq(subtracted, ...
        'ClipLimit', 0.03, 'NumTiles', [16 16]);

    % Black Top-Hat: estrae strutture scure più piccole del disco
    se_tophat = strel('disk', 6);
    blackTopHat = imbothat(green_ma_clahe, se_tophat);

    % --- Segmentazione adattiva ---
    ma_adaptive = imbinarize(blackTopHat, 'adaptive', ...
        'Sensitivity', 0.3, 'ForegroundPolarity', 'bright');
    ma_adaptive = filterMA(ma_adaptive);

    % --- Segmentazione Otsu ---
    ma_otsu = blackTopHat > graythresh(blackTopHat);
    %ma_otsu = filterMA(ma_otsu);

    results{k, 1} = ma_adaptive;
    results{k, 2} = ma_otsu;
    results{k, 3} = startingImg;
end
end

% Funzione di supporto condivisa per entrambe le segmentazioni
function ma_binary = filterMA(ma_binary)

% Calcola le proprietà delle regioni connesse
    props = regionprops(ma_binary, 'Eccentricity');
   if ~isempty(props)
        eccentricities = [props.Eccentricity];
        % Trova le label degli oggetti troppo allungati in un colpo solo
        labelsToRemove = find(eccentricities > 0.85);
        % Rimuovili tutti insieme con ismember
        labels = bwlabel(ma_binary);
        ma_binary = ~ismember(labels, labelsToRemove) & ma_binary;
    end
end