function result = PreprocessingHardExudates(folder,startImg, numImages)

files  = dir(fullfile(folder, '*.jpg'));
result = cell(numImages, 3);

for k = startImg:numImages
    filename    = fullfile(folder, files(k).name);
    startingImg = imread(filename);

    % 1. CANALE VERDE
    I = im2double(startingImg(:,:,2));

    % 2. MASCHERA FOV
    mask_FOV = imbinarize(I, 0.05);
    mask_FOV = imfill(mask_FOV, 'holes');
    mask_FOV = imerode(mask_FOV, strel('disk', 20));

    % 3. TOP-HAT
    se_th    = strel('disk', 15);
    I_tophat = imtophat(I, se_th);

    % 4. FILTRO MEDIANO — senza imadjust
    I_retina = I_tophat(mask_FOV);
    I_clean  = medfilt2(I_tophat, [3 3]);

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

    % --- METODO OTSU — graythresh su I_clean dentro FOV ---
    if ~isempty(I_retina)
        clean_retina = I_clean(mask_FOV);
        level_otsu   = graythresh(uint8(clean_retina * 255));
        fprintf('Soglia Otsu immagine %d: %.4f\n', k, double(level_otsu)/255);
        mask_otsu    = (I_clean > double(level_otsu)/255) & mask_FOV;
    else
        mask_otsu = false(size(I));
    end
    mask_otsu = bwareaopen(mask_otsu, 30);
    mask_otsu = bwareafilt(mask_otsu, [25 10000]);
    mask_otsu = imclose(mask_otsu, strel('disk', 2));

    % Salvataggio
    result{k, 1} = mask_percentile;
    result{k, 2} = mask_otsu;
    result{k, 3} = startingImg;
end
end