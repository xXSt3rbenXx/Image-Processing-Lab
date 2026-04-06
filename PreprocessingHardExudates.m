function result = PreprocessingHardExudates(folder, startImg, numImages)

files  = dir(fullfile(folder, '*.jpg'));
result = cell(numImages - startImg + 1, 3);

for k = startImg:numImages
    filename = fullfile(folder, files(k).name);
    img      = imread(filename);

    % 1. CANALE VERDE
    I = im2double(img(:,:,2));

    % 2. MASCHERA FOV
    mask_FOV = imbinarize(I, 0.05);
    mask_FOV = imfill(mask_FOV, 'holes');
    mask_FOV = imerode(mask_FOV, strel('disk', 20));

    % 3. TOP-HAT
    se_th    = strel('disk', 15);
    I_tophat = imtophat(I, se_th);

    % 4. ENHANCEMENT con imadjust SOLO dentro FOV
    I_enhanced = zeros(size(I));
    I_retina   = I_tophat(mask_FOV);
    if ~isempty(I_retina)
        I_enhanced(mask_FOV) = imadjust(I_tophat(mask_FOV));
    end
    I_clean = medfilt2(I_enhanced, [3 3]);

    % --- METODO ADATTIVO — percentile 98.8 su I_clean ---
    if ~isempty(I_retina)
        thresh_per      = prctile(I_clean(mask_FOV), 98.8);
        mask_percentile = (I_clean > thresh_per) & mask_FOV;
    else
        mask_percentile = false(size(I));
    end
    se_close  = strel('disk', 6);
    se_dilate = strel('disk', 2);
    mask_percentile = imclose(mask_percentile, se_close);
    mask_percentile = imdilate(mask_percentile, se_dilate);
    mask_percentile = imfill(mask_percentile, 'holes');
    mask_percentile = bwareafilt(mask_percentile, [25 10000]);

    % --- METODO OTSU — percentile 95 ---
    if ~isempty(I_retina)
        thresh_otsu = prctile(I_clean(mask_FOV), 95);
        mask_otsu   = (I_clean > thresh_otsu) & mask_FOV;
    else
        mask_otsu = false(size(I));
    end
    mask_otsu = imclose(mask_otsu, strel('disk', 4));
    mask_otsu = imdilate(mask_otsu, strel('disk', 2));
    mask_otsu = imfill(mask_otsu, 'holes');
    mask_otsu = bwareafilt(mask_otsu, [25 10000]);

    % Salvataggio
    idx = k - startImg + 1;
    result{idx, 1} = mask_percentile;
    result{idx, 2} = mask_otsu;
    result{idx, 3} = img;
end
end