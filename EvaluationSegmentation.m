function metrics = EvaluationSegmentation(segmentedIter, segmentedOtsu, gt)


%FORZIAMO TUTTO IN UN CANALE BINARIO
if size(segmentedIter, 3) == 3
    segmentedIter = rgb2gray(segmentedIter);
end
if size(segmentedOtsu, 3) == 3
    segmentedOtsu = rgb2gray(segmentedOtsu);
end
if size(gt, 3) == 3
    gt = rgb2gray(gt);
end


pred_iter=logical(segmentedIter);
pred_otsu=logical(segmentedOtsu);
gt=logical(gt);
%converte valori numerici in array logici (booleani), 
% dove i valori diversi da zero diventano true () e
%  gli zeri diventano false ()




%CALCOLO TN, TP, FP, FN
TP_iter = sum(pred_iter(:) & gt(:));
%LI TRASFORMO IN VETTORI COLONNA 
TN_iter = sum(~pred_iter(:) & ~gt(:));
FP_iter = sum(pred_iter(:) & ~gt(:));
FN_iter = sum(~pred_iter(:) & gt(:));

%TP, TN, FP, FN DI OTSU
TP_otsu = sum(pred_otsu(:) & gt(:));
%LI TRASFORMO IN VETTORI COLONNA 
TN_otsu = sum(~pred_otsu(:) & ~gt(:));
FP_otsu = sum(pred_otsu(:) & ~gt(:));
FN_otsu = sum(~pred_otsu(:) & gt(:));

metrics.iter.accuracy=(TP_iter+TN_iter)/(TP_iter+FN_iter+FP_iter+TN_iter);
metrics.otsu.accuracy=(TP_otsu+TN_otsu)/(TP_otsu+FN_otsu+FP_otsu+TN_otsu);


metrics.iter.dice=(2*TP_iter)/(2*TP_iter+FP_iter+FN_iter+eps);
metrics.otsu.dice=(2*TP_otsu)/(2*TP_otsu+FP_otsu+FN_otsu+eps);

% Sensibilità (quante lesioni reali trova)
metrics.iter.sensitivity = TP_iter / (TP_iter + FN_iter + eps);
metrics.otsu.sensitivity = TP_otsu / (TP_otsu + FN_otsu + eps);

% Specificità (quanti pixel sani classifica correttamente)
metrics.iter.specificity = TN_iter / (TN_iter + FP_iter + eps);
metrics.otsu.specificity = TN_otsu / (TN_otsu + FP_otsu + eps);
end
