function results = PreprocessingSoftExudates(folder, numImages)
files = dir(fullfile(folder, '*.jpg'));
results = cell(numImages, 3);

for k = 1:numImages
    filename = fullfile(folder, files(k).name);
    startingImg = imread(filename);

    % Canale verde
    red_double = im2double(startingImg(:,:,1));

    % Background subtraction con sigma intermedio
    
    subtracted = red_double - imgaussfilt(red_double, 30);
    subtracted = subtracted - min(subtracted(:));
    subtracted = subtracted / max(subtracted(:));

    % CLAHE standard
    green_clahe = adapthisteq(subtracted, ...
        'ClipLimit', 0.02, 'NumTiles', [8 8]);

    % White Top-Hat: estrae strutture BRILLANTI più piccole dell'elemento strutturante
    % I SE sono chiari sullo sfondo scuro — opposto dei MA
    se_tophat = strel('disk', 15);
    whiteTopHat = imtophat(green_clahe, se_tophat);

    % --- Segmentazione adattiva ---
    se_adaptive = imbinarize(whiteTopHat, 'adaptive', ...
        'Sensitivity', 0.3, 'ForegroundPolarity', 'bright');
    se_adaptive = filterSE(se_adaptive);

    % --- Segmentazione Otsu ---
    se_otsu = whiteTopHat > graythresh(whiteTopHat);
    se_otsu = filterSE(se_otsu);

    results{k, 1} = se_adaptive;
    results{k, 2} = se_otsu;
    results{k, 3} = startingImg;
end
end

function se_binary = filterSE(se_binary)
    % Rimuovi rumore piccolo e strutture troppo grandi
    se_binary = bwareaopen(se_binary, 50);
    se_binary = bwareafilt(se_binary, [50 5000]);

    % Filtra per circolarità — SE hanno forme irregolari
    % soglia più permissiva rispetto ai MA (0.85)
    props = regionprops(se_binary, 'Eccentricity');
    if ~isempty(props)
        eccentricities = [props.Eccentricity];
        labelsToRemove = find(eccentricities > 0.95);
        labels = bwlabel(se_binary);
        se_binary = ~ismember(labels, labelsToRemove) & se_binary;
    end
end