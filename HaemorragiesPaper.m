function result = HaemorragiesPaper(folder, startImg, numImages)

files = dir(fullfile(folder, '*.jpg'));
result = cell((numImages-startImg+1),2);

for k = startImg:numImages
    % --- 1. Leggi immagine e canale verde ---
    filename = fullfile(folder, files(k).name); 
    img = imread(filename);
    I = im2double(img(:,:,2));
     % --- Applico un semplice mean filter ---
    h = fspecial('average', [3 3]);
    I_mean = imfilter(I, h,'replicate');
     % --- Contrast Enhancement---
    J = imadjust(I_mean); %MATLAB applica automaticamente il "1% saturation"
    % --- the picture is binarized using a novel local adaptive thresholding---
    T = adaptthresh(J, 0.6, 'ForegroundPolarity', 'dark', 'Statistic', 'gaussian');
    BW = imbinarize(J, T);
    % --- Morphological operations---
    SE = strel('disk', 4); % Il raggio dipende dalla risoluzione, 3-5 è tipico
    BW_closed = imclose(BW, SE);
    P = 30; % Rimuove tutto ciò che è più piccolo di 30 pixel
    BW_final = bwareaopen(BW_closed, P);
    % --- Region of Interest using Connected Component Labelling---
    % 1. Trova tutti gli oggetti connessi
    CC = bwconncomp(BW_final); 
    
    % 2. Estrai le proprietà geometriche (Area, Eccentricità, etc.)
    stats = regionprops(CC, 'Area', 'Eccentricity', 'Centroid');
    
    % 3. Filtra gli oggetti basandoti sulle proprietà
    % Esempio: teniamo solo oggetti con area > 20 e non troppo lunghi
    idx = find([stats.Area] > 100 & [stats.Eccentricity] < 0.8);
    
    % 4. Crea la maschera finale pulita
    BW_emorragie_final = ismember(labelmatrix(CC), idx);

    % --- Salvataggio ---
    result{k-startImg+1, 1} = BW_emorragie_final;
    result{k-startImg+1, 2} = img;

end