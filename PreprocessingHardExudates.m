function result= PreprocessingHardExudates(folder,numImages)

files = dir(fullfile(folder, '*.jpg'));
result = cell(numImages,3);

 for k = 1:numImages
        filename = fullfile(folder, files(k).name); %costruisce il percorso assoluto del file
        startingImg = imread(filename);
        redChannel = im2double(startingImg(:,:,1));

        red_adj = adapthisteq(redChannel, 'ClipLimit', 0.02, 'NumTiles', [8 8]);
        background = imgaussfilt(red_adj, 20);

        ex_enhanced = red_adj - background;

       

        % Pulizia tramite Filtro Mediano
        % Rimuoviamo il rumore "sale e pepe" che potrebbe creare falsi positivi
        ex_clean = medfilt2(ex_enhanced, [3 3]);

        % Essendo le parti più brillanti, usiamo una soglia superiore alla media
        level = graythresh(ex_clean) * 1.5; 
        maskEX = ex_clean > level;
    
    
        % Rimuoviamo oggetti troppo piccoli (rumore) che non possono essere essudati
        maskEX = bwareaopen(maskEX, 20); 
        
        % Chiusura per unire essudati vicini che si sono frammentati
        se = strel('disk', 2);
        maskEX = imclose(maskEX, se);

   


 end