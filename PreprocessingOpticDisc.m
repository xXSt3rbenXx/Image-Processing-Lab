function result= PreprocessingOpticDisc(folder,startImg,numImages)
    
    files = dir(fullfile(folder, '*.jpg'));
    result = cell((numImages-startImg+1),3);
    for k = startImg:numImages
       filename = fullfile(folder, files(k).name); %costruisce il percorso assoluto del file
       startingImg = imread(filename);
       greenChannelImg = im2double(startingImg(:,:,2));

               % CLAHE
       greenChannelEqualized = adapthisteq(greenChannelImg, ...
           'ClipLimit', 0.02, 'NumTiles', [8 8]);


       % level = graythresh(greenChannelEqualized) * 2.0; %PROVIAMO CON UNA SOGLIA ANCORAPIù ALTA
       level_adaptive = prctile(greenChannelEqualized(:), 98);%uso il percentile per i più brillanti 
       mask_adaptive = greenChannelEqualized > level_adaptive;
       mask_adaptive = bwareafilt(mask_adaptive, 1); 
       se = strel('disk', 15);
       mask_adaptive = imclose(mask_adaptive, se);
       mask_adaptive = imfill(mask_adaptive, 'holes');

        %CALCOLO SOGLIA OTTIMALE CON OTSU
        level_otsu=graythresh(greenChannelEqualized);
        mask_otsu=greenChannelEqualized>level_otsu;
        mask_otsu = bwareafilt(mask_otsu, 1); 
        mask_otsu = imclose(mask_otsu, se);
        mask_otsu = imfill(mask_otsu, 'holes');


        %Salvataggio
        result{(k-startImg+1), 1}=mask_adaptive;
        result{(k-startImg+1), 2}=mask_otsu;
        result{(k-startImg+1), 3}=startingImg;
    end
end