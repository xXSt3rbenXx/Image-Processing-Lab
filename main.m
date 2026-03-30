
folder = '.\IDRiD\A. Segmentation\1. Original Images\a. Training Set';

files = dir(fullfile(folder, '*.jpg')); % cambia estensione se serve

%PROVA CON 1 IMMAGINE PER CAPIRE CHE SUCCEDE
for k = 1:2
    filename = fullfile(folder, files(k).name);
    startingImg = imread(filename);
    imshow(startingImg)
    figure(1)
    title('Immagine di Partenza')

    greenChannelImg=startingImg(:, :, 2);
    figure(2)
    imshow(greenChannelImg)
    title('Immagine Channel Verde')
    
    %PROVA CON SIGMA=50
    background=imgaussfilt(greenChannelImg, 50);
    figure(3)
    plot(background)
    title('Grafico filtro Gaussiano Largo con sigma=50')

    figure(4)
    greenChannelImg=greenChannelImg-background;
    imshow(greenChannelImg)
    title('Immagine Channel Verde senza background')

    figure(5)
    greenChannelEqualized=adapthisteq(greenChannelImg, 'ClipLimit', 0.02, 'NumTiles', [8 8]);
    imshow(greenChannelEqualized)
    title('Immagine con CLAHE')

    
end

%ESPERIMENTO, UTILIZZO DI THRESHOLDING INVECE DI THRESHOLDING ADATTIVO
imgThreshSimple=im2double(greenChannelEqualized);
T1=0.5*mean(imgThreshSimple(:));
done=false;
while ~ done
    g=imgThreshSimple>=T1;
    TNext=0.5*(mean(imgThreshSimple(g))+mean(imgThreshSimple(~g)));
    done= abs(T1-TNext)<0.5;
    T1=TNext;
end 
imgThreshSimple=imbinarize(imgThreshSimple,TNext);
figure(6)
imshow(imgThreshSimple)
title('Immagine Segmentata con Tresholding')