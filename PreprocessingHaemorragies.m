function result = PreprocessingHaemorragies(folder, startImg, numImages)
    files = dir(fullfile(folder, '*.jpg'));
    result = cell((numImages - startImg + 1), 3);

    for k = startImg:numImages
        filename = fullfile(folder, files(k).name);
        img = imread(filename);
        G = im2double(img(:,:,2));

        % ===== PIPELINE CONDIVISA =====

        % 1. Maschera FOV
        mask_FOV = imbinarize(G, 0.05);
        mask_FOV = imfill(mask_FOV, 'holes');
        mask_FOV = imerode(mask_FOV, strel('disk', 30));

        % 2. Filtro multiscala Bottom-Hat
        I_small    = imbothat(G, strel('disk', 8));
        I_large    = imbothat(G, strel('disk', 25));
        I_combined = max(I_small, I_large);

        % 3. CLAHE + maschera FOV
        I_en = adapthisteq(I_combined, 'ClipLimit', 0.025);
        I_en(~mask_FOV) = 0;

        % ===== BW_FINAL — doppio percentile + region growing =====

        pixels_in_FOV  = I_en(mask_FOV);
        threshold_high = prctile(pixels_in_FOV, 95);
        threshold_low  = prctile(pixels_in_FOV, 85);

        BW_certain    = (I_en > threshold_high) & mask_FOV;
        BW_candidates = (I_en > threshold_low)  & mask_FOV;
        BW = imreconstruct(BW_certain, BW_candidates);

        % Pulizia
        BW = bwareaopen(BW, 30);
        BW = imclose(BW, strel('disk', 3));

        % Filtraggio geometrico
        CC    = bwconncomp(BW);
        stats = regionprops(CC, 'Area', 'Eccentricity', 'Solidity', 'Extent');
        L     = labelmatrix(CC);
        BW_final = false(size(G));

        for i = 1:CC.NumObjects
            if stats(i).Area > 30 && stats(i).Area < 40000
                if stats(i).Eccentricity < 0.95 && ...
                   stats(i).Solidity > 0.35    && ...
                   stats(i).Extent   > 0.20
                    BW_final(L == i) = true;
                end
            end
        end

        % ===== MASK_OTSU =====

        I_bh = mat2gray(I_en);
        se   = strel('disk', 1);

        level_otsu = graythresh(I_bh);
        mask_otsu  = I_bh > level_otsu;
        mask_otsu  = bwareaopen(mask_otsu, 5);
        mask_otsu  = imclose(mask_otsu, se);
        mask_otsu  = imfill(mask_otsu, 'holes');
        mask_otsu  = imdilate(mask_otsu, strel('disk', 2));

        % ===== SALVATAGGIO =====
        result{k - startImg + 1, 1} = BW_final;
        result{k - startImg + 1, 2} = mask_otsu;
        result{k - startImg + 1, 3} = img;
    end
end