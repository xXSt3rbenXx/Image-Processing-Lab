function results = PreprocessingSegmentation(folder,startImg,numImages)
files = dir(fullfile(folder, '*.jpg'));

results = cell((numImages-startImg+1),3); %CREO UN VETTORE IN QUESTO HA 5 CELLE PERCHÈ STIAMO CARICANDO 5 IMMAGINI
    for k = startImg:numImages
        filename = fullfile(folder, files(k).name); %costruisce il percorso assoluto del file
        startingImg = imread(filename);
    
        % Canale verde
        greenChannelImg = startingImg(:,:,2);
    
        % Background subtraction
        green_double = im2double(greenChannelImg);
        background = imgaussfilt(green_double, 2);
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
        maxIter = 100; iter = 0;
    
        while ~done && iter < maxIter
            g = imgOpen >= T1;
            TNext = 0.5 * (mean(imgOpen(g)) + mean(imgOpen(~g)));
            done = abs(T1 - TNext) < 1e-3;
            T1 = TNext;
            iter=iter+1;
        end
    
        imgThresh = imbinarize(imgOpen, TNext);


        
        
        %thresholding con otsu
        tOtsu=graythresh(imgOpen);
        imgOtsu=imbinarize(imgOpen, tOtsu);
        
        %ESPERIMENTO Rimuovi oggetti troppo grandi (non sono lesioni) con
        %un filtro per dimensioni
        % Per iterativo — lesioni più grandi
        imgThresh = bwareafilt(imgThresh, [5 2000]);
        
        % Per Otsu — il problema è diverso, ha troppi FP grandi
        imgOtsu = bwareafilt(imgOtsu, [5 1000]);



        % Il risultato viene salvato su due celle differenti
        
        results{(k-startImg+1), 1} = imgThresh; % Colonna 1: Iterativo
        results{(k-startImg+1), 2} = imgOtsu;   % Colonna 2: Otsu
        results{(k-startImg+1), 3} = startingImg; %Ho inserito una nuova cella per ospitare l'immagine di partenza, proveniente da questa funzione
    end
end