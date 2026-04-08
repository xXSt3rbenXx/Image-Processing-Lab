function results = PreprocessingMicroaneurysms(folder, startImg, numImages)
    files = dir(fullfile(folder, '*.jpg'));
    results = cell((numImages-startImg+1), 3);
    
    for k = startImg:numImages
        filename = fullfile(folder, files(k).name);
        startingImg = imread(filename);
        
        % Canale verde
        green_double = im2double(startingImg(:,:,2));
        
        % ===== DUAL-SCALE APPROACH =====
        subtracted_small = green_double - imgaussfilt(green_double, 5);
        subtracted_small = subtracted_small - min(subtracted_small(:));
        subtracted_small = subtracted_small / max(subtracted_small(:));
        green_clahe_small = adapthisteq(subtracted_small, 'ClipLimit', 0.03, 'NumTiles', [16 16]);
        blackTopHat_small = imbothat(green_clahe_small, strel('disk', 3));
        
        subtracted_large = green_double - imgaussfilt(green_double, 10);
        subtracted_large = subtracted_large - min(subtracted_large(:));
        subtracted_large = subtracted_large / max(subtracted_large(:));
        green_clahe_large = adapthisteq(subtracted_large, 'ClipLimit', 0.03, 'NumTiles', [16 16]);
        blackTopHat_large = imbothat(green_clahe_large, strel('disk', 6));
        
        blackTopHat_combined = max(blackTopHat_small, blackTopHat_large);
        
        % ===== MASCHERA FOV =====
        mask_FOV = imbinarize(green_double, 0.05);
        mask_FOV = imfill(mask_FOV, 'holes');
        mask_FOV = imerode(mask_FOV, strel('disk', 20));
        
        pixels_in_FOV = blackTopHat_combined(mask_FOV);
        
        % ===== DOPPIO PERCENTILE (HYSTERESIS) =====
        % Soglia alta: candidati CERTI (top 3%)
        threshold_high = prctile(pixels_in_FOV, 97);
        ma_certain = (blackTopHat_combined > threshold_high) & mask_FOV;
        
        % Soglia bassa: candidati POSSIBILI (top 8%)
        threshold_low = prctile(pixels_in_FOV, 92);
        ma_candidates = (blackTopHat_combined > threshold_low) & mask_FOV;
        
        % Accetta candidati solo se connessi a quelli certi (region growing)
        ma_adaptive = imreconstruct(ma_certain, ma_candidates);
        ma_adaptive = filterMA(ma_adaptive);
        
        % ===== OTSU =====
        threshold_otsu = graythresh(pixels_in_FOV);
        ma_otsu = (blackTopHat_combined > threshold_otsu) & mask_FOV;
        ma_otsu = filterMA(ma_otsu);
        
        results{(k-startImg+1), 1} = ma_adaptive;
        results{(k-startImg+1), 2} = ma_otsu;
        results{(k-startImg+1), 3} = startingImg;
    end
end

function ma_binary = filterMA(ma_binary)
    ma_binary = bwareaopen(ma_binary, 2);
    
    props = regionprops(ma_binary, 'Eccentricity', 'Area', 'Solidity');
    
    if ~isempty(props)
        eccentricities = [props.Eccentricity];
        areas = [props.Area];
        solidities = [props.Solidity];
        
        % ===== FILTRI PIÙ PERMISSIVI =====
        labelsToRemove = find(eccentricities > 0.93 | ...
                              areas < 2 | areas > 400 | ...
                              solidities < 0.35);
        
        labels = bwlabel(ma_binary);
        ma_binary = ~ismember(labels, labelsToRemove) & ma_binary;
    end
end