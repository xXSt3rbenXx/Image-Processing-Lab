function results = PreprocessingSegmentation(folder)
files = dir(fullfile(folder, '*.jpg'));
results = cell(5,2); %CREO UN VETTORE IN QUESTO HA 5 CELLE PERCHÈ STIAMO CARICANDO 5 IMMAGINI
    for k = 1:5
        filename = fullfile(folder, files(k).name);
        startingImg = imread(filename);
    
        % Canale verde
        greenChannelImg = startingImg(:,:,2);
    
        % Background subtraction
        green_double = im2double(greenChannelImg);
        background = imgaussfilt(green_double, 50);
        subtracted = green_double - background;
    
        subtracted = subtracted - min(subtracted(:));
        subtracted = subtracted / max(subtracted(:));
    
        % CLAHE
        greenChannelEqualized = adapthisteq(subtracted, ...
            'ClipLimit', 0.02, 'NumTiles', [8 8]);
    
        % Bilaterale + Opening
        imgFilteredBilateral = imbilatfilt(greenChannelEqualized, ...
            'DegreeOfSmoothing', 10, 'SpatialSigma', 2);
    
        structure = strel('disk', 2);
        imgOpen = imopen(imgFilteredBilateral, structure);
    
        % Threshold iterativo
        T1 = 0.5 * mean(imgOpen(:));
        done = false;
    
        while ~done
            g = imgOpen >= T1;
            TNext = 0.5 * (mean(imgOpen(g)) + mean(imgOpen(~g)));
            done = abs(T1 - TNext) < 1e-3;
            T1 = TNext;
        end
    
        imgThresh = imbinarize(imgOpen, TNext);
        
        %thresholding con otsu
        tOtsu=graythresh(imgOpen);
        imgOtsu=imbinarize(imgOpen, tOtsu);
        
        % SALVA RISULTATO LO FACCIAMO SOLO PERCHÈ STIAMO LAVORANDO DUE FILE
        % DIVERSI
        results{k, 1} = imgThresh; % Colonna 1: Iterativo
        results{k, 2} = imgOtsu;   % Colonna 2: Otsu
    end
end