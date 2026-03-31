folder = '.\IDRiD\A. Segmentation\1. Original Images\a. Training Set';
files = dir(fullfile(folder, '*.jpg'));
%PROVA CON 5 IMMAGINI PER VALUTARE LE SEGMENTAZIONI
for k = 1:5
    filename = fullfile(folder, files(k).name);
    startingImg = imread(filename);

    figure(1); imshow(startingImg); title('Immagine di Partenza')

    % Canale verde
    greenChannelImg = startingImg(:,:,2);
    figure(2); imshow(greenChannelImg); title('Canale Verde')

    % Background subtraction in double 
    green_double = im2double(greenChannelImg);
    background = imgaussfilt(green_double, 50);
    subtracted = green_double - background;

    % Rinormalizza in [0,1]
    subtracted = subtracted - min(subtracted(:));
    subtracted = subtracted / max(subtracted(:));

    figure(3); imshow(subtracted); title('Dopo Background Subtraction')

    % CLAHE 
    greenChannelEqualized = adapthisteq(subtracted, ...
        'ClipLimit', 0.02, 'NumTiles', [8 8]);
    figure(4); imshow(greenChannelEqualized); title('Dopo CLAHE')

    % Bilaterale + Opening
    imgFilteredBilateral = imbilatfilt(greenChannelEqualized, ...
        'DegreeOfSmoothing', 10, 'SpatialSigma', 2);
    structure = strel('disk', 2);
    imgOpen = imopen(imgFilteredBilateral, structure);
    figure(5); imshow(imgOpen); title('Dopo Bilateral + Opening')

    % Thresholding iterativo
    T1 = 0.5 * mean(imgOpen(:));
    done = false;
    maxIter = 100;
    iter = 0;

    while ~done && iter < maxIter
        g = imgOpen >= T1;
        TNext = 0.5 * (mean(imgOpen(g)) + mean(imgOpen(~g)));
        done = abs(T1 - TNext) < 1e-3;
        T1 = TNext;
        iter = iter + 1;
    end
    
    %STAMPO L'INDICE PER CAPIRE A CHE ITERAZIONE SIAMO
    fprintf('Iterazione numero: %f\n', k)

    imgThreshSimple = imbinarize(imgOpen, TNext);
    figure(6); imshow(imgThreshSimple); title('Segmentazione con Thresholding Iterativo')
    fprintf('Valore soglia metodo iterativo: %f\n', TNext)

    %THRESHOLDING CON OTSU (METODO GENERALE)
    tOtsu=graythresh(imgOpen);
    imgOtsu=imbinarize(imgOpen, tOtsu);
    figure(7); imshow(imgOtsu); title('Segmentazione con Thresholding OTSU')
    fprintf('Valore soglia metodo OTSU: %f\n', tOtsu)
end