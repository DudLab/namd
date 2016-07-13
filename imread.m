% RGB NEURON TIFF DENOISER, PARSER, AND BLOB TRACKING FOR MRNA
% ==============================================================
% ==============RGB SPLIT AND FILENAME READER===================
% ==============================================================
filename = '/Users/hwab/Dropbox (HHMI)/Phillipstuff/test.tif';
dot = regexp(filename,'\.')
switch(filename(dot+1:end))
    case {'jpg','jpeg'}
        disp('jpg file')
        imtype = 1;
    case {'tif','tiff'}
        disp('tif file');
        imtype = 2;
otherwise
disp('error')
end
img = imread(filename);
r = img(:,:,1); % Red channel
g = img(:,:,2); % Green channel
b = img(:,:,3); % Blue channel
a = zeros(size(img, 1), size(img, 2)); % Alpha layer
% ==============================================================
% ==========MAKE EACH CHANNEL uint8 INTO RBG uint8 3D===========
% ==============================================================
red = cat(3, r, a, a);
green = cat(3, a, g, a);
blue = cat(3, a, a, b);
original = cat(3, r, g, b);
figure, imshow(img), title('Original image')
figure, imshow(red), title('Red channel')
figure, imshow(green), title('Green channel')
figure, imshow(blue), title('Blue channel')
figure, imshow(original), title('Back to original image')
seq = {red,green,blue};
for l = 1:3
    if imtype == 1
        imwrite(new,...
            ['/Users/hwab/Dropbox (HHMI)/Phillipstuff/slices/img' num2str(l) '.jpg']);
    end
    if imtype == 2
        imwrite(seq{l},...
            ['/Users/hwab/Dropbox (HHMI)/Phillipstuff/slices/img' num2str(l) '.tif'],...
           'tif','WriteMode','overwrite','Compression','none', ...
           'ColorSpace', 'rgb');
    end
end

% ==============================================================
% ============NOISE REDUCTION OF EACH CHANNEL===================
% ==============================================================
d1 = '/Users/hwab/Dropbox (HHMI)/Phillipstuff/slices/r1.jpg';
d2 = '/Users/hwab/Dropbox (HHMI)/Phillipstuff/slices/g1.jpg';
d3 = '/Users/hwab/Dropbox (HHMI)/Phillipstuff/slices/b1.jpg';
% dc = {d1,d2,d3};
dc = seq;
c = numel(dc);
mmm = zeros(2,c,2);
chn = zeros(2,2,3);%3 rows per channel, then min; 2 columns (min, max);
for k = 1:c
%     RGB = imread(dc{k});
    RGB = dc{k};
    % Convert RGB image to ycbr
    I = rgb2ycbcr(RGB);
    %mmm: max, min, median, stdev
    for i = 1:c
        mmm(1,i,k) = max(max(I(:,:,i)));
        mmm(2,i,k) = min(min(I(:,:,i)));
        mmm(3,i,k) = median(median(I(:,:,i)));
        mmm(4,i,k) = mean2(I(:,:,i));
        mmm(5,i,k) = std2(I(:,:,i));
    end
    [val(k,:), idx(k,:)] = sort(mmm(5,:,k),'descend');%sort standard dev
    %channel with highest stdev gets thresh reduction
    for j = 1: c
       if j == idx(k,1)
           chn(j,1,k) = mmm(3,j,k) + (mmm(3,j,k)- mmm(2,j,k));
           chn(j,2,k) = mmm(1,j,k);       
       else
           chn(j,1,k) = mmm(2,j,k);
           chn(j,2,k) = mmm(1,j,k);         
       end    
    end
    %Channel thesh min and max respectively
    c1Min(k) = chn(1,1,k);
    c1Max(k) = chn(1,2,k);
    c2Min(k) = chn(2,1,k);
    c2Max(k) = chn(2,2,k);
    c3Min(k) = chn(3,1,k);
    c3Max(k) = chn(3,2,k);
    % Create mask based on threshold values
    BW = (I(:,:,1) >= chn(1,1,k) ) & (I(:,:,1) <= chn(1,2,k)) & ...
        (I(:,:,2) >= chn(2,1,k) ) & (I(:,:,2) <= chn(2,2,k)) & ...
        (I(:,:,3) >= chn(3,1,k) ) & (I(:,:,3) <= chn(3,2,k));
    % filter & subtract background
    mask = RGB;
    mask(repmat(BW,[1 1 3])) = 0;
    new = imsubtract(RGB,mask);
    figure(k);
    image(new);
    if imtype == 1
        imwrite(new,...
            ['/Users/hwab/Dropbox (HHMI)/Phillipstuff/slices/filt' num2str(k) '.jpg']);
    end
    if imtype == 2
        imwrite(new,...
            ['/Users/hwab/Dropbox (HHMI)/Phillipstuff/slices/filt' num2str(k) '.tif'],...
            'tif','WriteMode','overwrite','Compression','none', ...
            'ColorSpace', 'rgb');
    end
end