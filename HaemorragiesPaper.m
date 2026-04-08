function result = HaemorragiesPaper(folder, startImg, numImages)
    files = dir(fullfile(folder, '*.jpg'));
    result = cell((numImages-startImg+1), 2);
    
    for k = startImg:numImages
        filename = fullfile(folder, files(k).name);
        img = imread(filename);
        G = im2double(img(:,:,2));
        
        % 1. Maschera FOV
        mask_FOV = imbinarize(G, 0.05);
        mask_FOV = imfill(mask_FOV, 'holes');
        mask_FOV = imerode(mask_FOV, strel('disk', 30));
        
        % 2. FILTRO MULTISCALA (Bottom-Hat)
        I_small = imbothat(G, strel('disk', 8));
        I_large = imbothat(G, strel('disk', 25));
        I_combined = max(I_small, I_large);
        
        % 3. Pre-processing e Normalizzazione
        I_en = adapthisteq(I_combined, 'ClipLimit', 0.025);
        I_en(~mask_FOV) = 0;
        
        % ===== DOPPIO PERCENTILE (come microaneurismi) =====
        pixels_in_FOV = I_en(mask_FOV);
        
        % Soglia alta: emorragie CERTE (top 5%)
        threshold_high = prctile(pixels_in_FOV, 95);
        BW_certain = (I_en > threshold_high) & mask_FOV;
        
        % Soglia bassa: emorragie POSSIBILI (top 15%)
        threshold_low = prctile(pixels_in_FOV, 85);
        BW_candidates = (I_en > threshold_low) & mask_FOV;
        
        % Region growing
        BW = imreconstruct(BW_certain, BW_candidates);
        
        % 5. Pulizia
        BW = bwareaopen(BW, 30);
        BW = imclose(BW, strel('disk', 3));
        
        % 6. FILTRAGGIO GEOMETRICO PIÙ PERMISSIVO
        CC = bwconncomp(BW);
        stats = regionprops(CC, 'Area', 'Eccentricity', 'Solidity', 'Extent');
        
        BW_final = false(size(G));
        L = labelmatrix(CC);
        
        for i = 1:CC.NumObjects
            % Filtri più rilassati
            if stats(i).Area > 30 && stats(i).Area < 40000
                if stats(i).Eccentricity < 0.95 && ...
                   stats(i).Solidity > 0.35 && ...
                   stats(i).Extent > 0.20
                    BW_final(L == i) = true;
                end
            end
        end
        
        % 7. NON usare imclearborder
        % BW_final = imclearborder(BW_final);
        
        result{k-startImg+1, 1} = BW_final;
        result{k-startImg+1, 2} = img;
    end
end