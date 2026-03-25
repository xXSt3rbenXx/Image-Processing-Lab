
folder = 'C:\Users\hp\Desktop\Dataset\IDRiD\A. Segmentation\1. Original Images\a. Training Set';

files = dir(fullfile(folder, '*.jpg')); % cambia estensione se serve

for k = 1:length(files)
    filename = fullfile(folder, files(k).name);
    img = imread(filename);
    pause(0.5); % per vedere le immagini una dopo l'altra
end


igray=rgb2gray(img)
i_equalized=adapthisteq(igray) %applica CLAHE
imhowpair(igray, i_equalized, 'montage')
title('Originale vs CLAHE')