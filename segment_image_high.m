function [out, y2, x2] = segment_image_high(img, mode, var)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% nominal values:
%       sesnitivity = 0.59
%       erosion = 1;
%       no. of pixels = 400
% var = [sensitivity, erosion, no. of pixels


sz = size(img);
sample = mean( mean(img(sz(1)-6:sz(1)-2), round(sz(2)/2-2):(round(sz(2)/2+2))));
bck = mean(mean(img( 2:6, round(sz(2)/2-2):(round(sz(2)/2+2)))));

if sample < bck
   img = imcomplement(img); 
end


y = round(var{4}); x = round(var{5});
se = strel('disk', var{2});
se2 = strel('disk',4);

if (strcmp(mode, 'debug'))
    figure, imshow(img, [])
    I1 = imbinarize(imadjust(medfilt2(im2double(img))), 'adapt', 'Sensitivity', var{1});
    figure, imshow(I1), title('1. binarize')
    I2 = bwareaopen(I1, var{3});
    figure, imshow(I2), title('2. area open')
    I3 = imcomplement(I2);
    figure, imshow(I2), title('3. fill')
    
    sprintf('Please click the unwanted area\nPress Enter to continue...')
    pause()
    [x2, y2] = ginput();
    I4 = imcomplement(imfill(I3, round([y2 x2])));
    figure, imshow(I4), title('4. filled')
    
    I5 = bwareaopen(I4, 100);
    figure, imshow(I5), title('5. area open')
    
    I6 = imdilate(I5, se);
    figure, imshow(I6), title('6. dilate')
    I7 = imfill(I6, [y x]);
    figure, imshow(I7), title('7. fill');
    I8 = imdilate(I7, se2);
    I9 = imerode(I8, se2);
    I10 = imerode(I9, se);
    
    out = I10;
    figure, imshow(out), title('final')
    
else
    y2 = round(var{6}); x2 = round(var{7});
    
    I = imerode(imerode(imdilate(imfill(imdilate(bwareaopen(imcomplement(...
        imfill(imcomplement(bwareaopen(imbinarize(imadjust(medfilt2(...
        im2double(img))), 'adapt', 'Sensitivity', var{1}), var{3})),... 
        round([y2 x2]))), 100), se), [y x]), se2), se2), se);

    out = I;

end

end

