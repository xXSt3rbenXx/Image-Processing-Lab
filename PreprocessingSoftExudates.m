function results = PreprocessingSoftExudates(folder, startImg, numImages)
    files = dir(fullfile(folder, '*.jpg'));
    results = cell((numImages-startImg+1), 3);
    
    for k = startImg:numImages
        filename = fullfile(folder, files(k).name);
        img = imread(filename);
        
        % 1. MIX CANALI: Bilanciamo R e G per esaltare i SE rispetto allo sfondo
        I = 0.5 * im2double(img(:,:,1)) + 0.5 * im2double(img(:,:,2));
        
        % 2. MASCHERA FOV (Field of View) - Essenziale per non segmentare il bordo nero
        mask_FOV = imbinarize(im2double(img(:,:,2)), 0.05);
        mask_FOV = imfill(mask_FOV, 'holes');
        mask_FOV = imerode(mask_FOV, strel('disk', 30));
        
        % 3. RIMOZIONE BACKGROUND (Sigma alto per preservare macchie larghe)
        bg = imgaussfilt(I, 50); 
        subtracted = I - bg;
        subtracted = max(subtracted, 0); 
        subtracted = subtracted / max(subtracted(:));
        
        % 4. ENHANCEMENT E TOP-HAT
        combined_clahe = adapthisteq(subtracted, 'ClipLimit', 0.02);
        se_tophat_elem = strel('disk', 35); 
        whiteTopHat = imtophat(combined_clahe, se_tophat_elem);
        
        % 5. SEGMENTAZIONE ADATTIVA (Percentile dinamico)
        pixels_inside = whiteTopHat(mask_FOV);
        if ~isempty(pixels_inside)
            % Usiamo un percentile più alto (99.2) per ridurre i falsi positivi
            thresh_per = prctile(pixels_inside, 99.2);
            se_adaptive = (whiteTopHat > thresh_per) & mask_FOV;
        else
            se_adaptive = false(size(I));
        end
        
        % 6. FILTRAGGIO AVANZATO (Vedi funzione sotto)
        se_adaptive = filterSE_Final(se_adaptive, whiteTopHat);
        
        % 7. SEGMENTAZIONE OTSU (Come confronto)
        se_otsu = whiteTopHat > (graythresh(whiteTopHat) * 0.9);
        se_otsu = filterSE_Final(se_otsu & mask_FOV, whiteTopHat);
        
        results{(k-startImg+1), 1} = se_adaptive;
        results{(k-startImg+1), 2} = se_otsu;
        results{(k-startImg+1), 3} = img;
    end
end

function se_binary = filterSE_Final(se_binary, img_ref)
    % Rimuove il rumore puntiforme (Microaneurismi o artefatti)
    se_binary = bwareaopen(se_binary, 300); 
    
    % Analisi delle proprietà geometriche
    % I SE sono ovali/tondeggianti, i vasi sono lunghi (alta eccentricità)
    props = regionprops(se_binary, 'Area', 'Solidity', 'Eccentricity');
    
    if isempty(props)
        se_binary = false(size(se_binary));
        return;
    end
    
    % CRITERI DI FILTRAGGIO:
    % - Area: tra 400 e 40.000 pixel (per IDRiD_08)
    % - Eccentricità < 0.90: elimina i vasi sanguigni (che sono linee)
    % - Solidità > 0.40: elimina strutture troppo frastagliate
    keepIdx = ([props.Area] > 400 & [props.Area] < 40000 & ...
               [props.Eccentricity] < 0.90 & ...
               [props.Solidity] > 0.40);
    
    labels = bwlabel(se_binary);
    se_binary = ismember(labels, find(keepIdx));
    
    % Chiusura per compattare le "nuvole" di essudati
    se_binary = imclose(se_binary, strel('disk', 8));
    se_binary = imfill(se_binary, 'holes');
end