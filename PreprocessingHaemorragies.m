function result = PreprocessingHaemorragies(folder, startImg, numImages)

files = dir(fullfile(folder, '*.jpg'));
result = cell((numImages-startImg+1),3);

for k = startImg:numImages
    % --- 1. Leggi immagine e canale verde ---
    filename = fullfile(folder, files(k).name); 
    img = imread(filename);
    I = im2double(img(:,:,2));

    % --- 2. CLAHE leggero (invariato) ---
    I_eq = adapthisteq(I, 'ClipLimit', 0.02, 'NumTiles', [8 8]);

    % --- 3. Black Top-Hat con raggio aumentato (es. 4) ---
    %     Raggio 2 → raggio 4 per catturare emorragie più grandi
    I_bh = imbothat(I_eq, strel('disk', 4));
    I_bh = mat2gray(I_bh);

    % --- 4. Soglia percentile abbassata (es. 95) ---
    %     Valori tipici: 95, 93, 90 (provare in ordine decrescente)
    level_percentile = prctile(I_bh(:), 90);
    mask_percentile = I_bh > level_percentile;

    % --- 5. Pulizia minima con area ridotta (es. 5) ---
    mask_percentile = bwareaopen(mask_percentile, 5);   % prima 10
    se = strel('disk', 1);
    mask_percentile = imclose(mask_percentile, se); 
    mask_percentile = imfill(mask_percentile, 'holes');
    % Dilatazione leggermente più ampia (raggio 2) per fondere regioni
    mask_percentile = imdilate(mask_percentile, strel('disk', 2));

    % --- 6. Otsu (invariato, solo per confronto) ---
    level_otsu = graythresh(I_bh);
    mask_otsu = I_bh > level_otsu;
    mask_otsu = bwareaopen(mask_otsu, 5);
    mask_otsu = imclose(mask_otsu, se);
    mask_otsu = imfill(mask_otsu, 'holes');
    mask_otsu = imdilate(mask_otsu, strel('disk', 2));

    % --- 7. Salvataggio ---
    result{k-startImg+1, 1} = mask_percentile;
    result{k-startImg+1, 2} = mask_otsu;
    result{k-startImg+1, 3} = img;
end
end