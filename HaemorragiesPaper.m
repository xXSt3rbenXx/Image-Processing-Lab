function result = HaemorragiesPaper(folder, startImg, numImages)
    files = dir(fullfile(folder, '*.jpg'));
    result = cell((numImages-startImg+1), 2);
    
    for k = startImg:numImages
        filename = fullfile(folder, files(k).name); 
        img = imread(filename);
        G = im2double(img(:,:,2));
        
        % 1. Maschera FOV (Erosione decisa per pulire i bordi)
        mask_FOV = imbinarize(G, 0.05);
        mask_FOV = imfill(mask_FOV, 'holes');
        mask_FOV = imerode(mask_FOV, strel('disk', 30));
        
        % 2. FILTRO MULTISCALA (Bottom-Hat a due dimensioni)
        % Estraiamo sia le lesioni piccole che quelle grandi
        I_small = imbothat(G, strel('disk', 8));  % Per micro-emorragie
        I_large = imbothat(G, strel('disk', 25)); % Per emorragie estese
        I_combined = max(I_small, I_large);       % Uniamo il segnale migliore
        
        % 3. Pre-processing e Normalizzazione
        I_en = adapthisteq(I_combined, 'ClipLimit', 0.025);
        I_en(~mask_FOV) = 0;
        
        % 4. BINARIZZAZIONE ADATTIVA (Soglia dinamica)
        % Portiamo la sensibilità a 0.5 per bilanciare Sens/Spec
        T = adaptthresh(I_en, 0.2, 'ForegroundPolarity', 'bright', 'Statistic', 'mean');
        BW = imbinarize(I_en, T);
        BW = BW & mask_FOV;
        
        % 5. Pulizia e Rimozione Vasi Sanguigni
        % Rimuoviamo gli oggetti troppo sottili che sono sicuramente vasi
        BW = bwareaopen(BW, 50); 
        BW = imclose(BW, strel('disk', 2));
        
        % 6. FILTRAGGIO GEOMETRICO AVANZATO
        CC = bwconncomp(BW);
        stats = regionprops(CC, 'Area', 'Eccentricity', 'Solidity', 'Extent');
        
        % Inizializziamo la maschera
        BW_final = false(size(G));
        L = labelmatrix(CC);
        
        for i = 1:CC.NumObjects
            % Parametri chiave per il Dice:
            % Solidity > 0.45: Le emorragie sono più piene del rumore
            % Extent > 0.25: Rapporto tra area dell'oggetto e del suo bounding box
            % Eccentricity < 0.95: Scarta i vasi molto lunghi
            if stats(i).Area > 80 && stats(i).Area < 30000
                if stats(i).Eccentricity < 0.94 && stats(i).Solidity > 0.45 && stats(i).Extent > 0.25
                    BW_final(L == i) = true;
                end
            end
        end
        
        % 7. Pulizia Finale Bordi
        BW_final = imclearborder(BW_final);
        
        % 8. Output
        result{k-startImg+1, 1} = BW_final;
        result{k-startImg+1, 2} = img;
    end
end