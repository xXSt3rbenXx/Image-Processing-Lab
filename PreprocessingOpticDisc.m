function result= PreprocessingOpticDisc(folder,numImages)
    
    files = dir(fullfile(folder, '*.jpg'));
    result = cell(numImages,3);
    for k = 1:numImages
       filename = fullfile(folder, files(k).name); %costruisce il percorso assoluto del file
       startingImg = imread(filename);
       greenChannelImg = im2double(startingImg(:,:,2));

               % CLAHE
       greenChannelEqualized = adapthisteq(greenChannelImg, ...
           'ClipLimit', 0.02, 'NumTiles', [8 8]);


       % level = graythresh(greenChannelEqualized) * 2.0; %PROVIAMO CON UNA SOGLIA ANCORAPIù ALTA
       level_iter = prctile(greenChannelEqualized(:), 98);%uso il percentile per i più brillanti 
       mask_iter = greenChannelEqualized > level_iter;

                % Rimuoviamo oggetti troppo piccoli (rumore) che non possono essere essudati
        mask_iter = bwareafilt(mask_iter, 1); 
        
        % Chiusura per unire essudati vicini che si sono frammentati
        se = strel('disk', 15);
        mask_iter = imclose(mask_iter, se);
        mask_iter = imfill(mask_iter, 'holes');

        %CALCOLO SOGLIA OTTIMALE CON OTSU
        level_otsu=graythresh(greenChannelEqualized);
        mask_otsu=greenChannelEqualized>level_otsu;
        mask_otsu = bwareafilt(mask_otsu, 1); 
        mask_otsu = imclose(mask_otsu, se);
        mask_otsu = imfill(mask_otsu, 'holes');


        %Salvataggio
        result{k, 1}=mask_iter;
        result{k, 2}=mask_otsu;
        result{k, 3}=startingImg;
    end
end