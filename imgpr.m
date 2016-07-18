filename = '/Users/hwab/Dropbox (HHMI)/Phillipstuff/main.tif';
[RGB, cm] = imread(filename);
a = zeros(size(RGB,1),size(RGB,2));
x = reshape(1:256,256,1);
n = 3;
chn = zeros(3,2,3);
flt = zeros(256,3,n+1);
threshindex= (zeros(3));
dy = zeros(255,3,2);
dyf = zeros(255,3,2);
df = zeros(3,n);
imin = zeros(3,n);
imax = zeros(3,n);
ithr = zeros(3,n);
vmin = zeros(3,n);
vmax = zeros(3,n);
dot = regexp(filename,'\.')
a = zeros(size(RGB, 1), size(RGB, 2)); % Alpha layer
r = RGB(:,:,1); % Red channel
g = RGB(:,:,2); % Green channel
b = RGB(:,:,3); % Blue channel
red = cat(3, r, a, a);
green = cat(3, a, g, a);
blue = cat(3, a, a, b);
seq = {red,green,blue};
cflt = zeros(size(RGB,1),size(RGB,2),3);
filtseq = {cflt,cflt,cflt};
%=======================================================================
%=====================FILE INFO=========================================
%=======================================================================
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
%=======================================================================
%=====================THRESHOLDING======================================
%=======================================================================
for i = 1:3
    flt(:,i,1) = imhist(RGB(:,:,i));
    for r = 2:n+1
        dy(:,i,r-1) = diff(flt(:,i,r-1))./diff(x);
        df(i,r-1) = round(abs((numel(findpeaks(flt(:,i,r-1)))...
            + numel(findpeaks(1.01*max(flt(:,i,r-1))-flt(:,r-1))))...
            - (numel(findpeaks(dy(:,i,r-1)))...
            + numel(findpeaks(1.01*max(dy(:,i,r-1))-dy(:,i,r-1)))))/4);
        flt(:,i,r) = movAv(flt(:,i,r-1),df(i,r-1));
        dyf(:,i,r-1) = movAv(diff(flt(:,i,r))./diff(x),round(df(i,r-1)/2));%
       [vmin(i,r-1), imin(i,r-1)] = min(dyf(:,i,r-1));
       [vmax(i,r-1), imax(i,r-1)] = max(dyf(:,i,r-1));
       ithr(i,r-1) = abs(imax(i,r-1)-imin(i,r-1))+imin(i,r-1);
    end
end
%=======================================================================
%=====================FILTERING=========================================
%=======================================================================
for c = 1:3
    I = seq{c};
    for i = 1:3
        if i == c
%             min,max
            if imtype == 1%jpg
                chn(i,1,c) = ithr(i,n);
                chn(i,2,c) = 255;
            end
            if imtype == 2%tif conversion to tiff scale
                chn(i,1,c) = (ithr(i,n)/256)*65378.503;
                chn(i,2,c) = 65378.503;
            end
        else
            if imtype == 1%jpg
                chn(i,1,c) = 0;
                chn(i,2,c) = 255;                
            end
            if imtype == 2%tif conversion to tiff scale
                chn(i,1,c) = 0;
                chn(i,2,c) = 100;  
            end
        end
    end

    % Create mask
    BW = (I(:,:,1) >= chn(1,1,c) ) & (I(:,:,1) <= chn(1,2,c) ) & ...
        (I(:,:,2) >= chn(2,1,c) ) & (I(:,:,2) <= chn(2,2,c) ) & ...
        (I(:,:,3) >= chn(3,1,c) ) & (I(:,:,3) <= chn(3,2,c) );
    mask = seq{c};
    mask(repmat(~BW,[1 1 3])) = 0;
    cflt(:,:,c) = mask(:,:,c);
    filtseq{c} = imsubtract(seq{c},imsubtract(seq{c},mask));
end
%=======================================================================
%=====================SAVING=========================================
%=======================================================================
if imtype == 1
    imwrite(cflt,...
        ['/Users/hwab/Dropbox (HHMI)/Phillipstuff/imagepr/bin/compfilt.jpg']);
end
if imtype == 2
    imwrite(cflt,...
        ['/Users/hwab/Dropbox (HHMI)/Phillipstuff/imagepr/bin/compfilt.tif'],...
        'tif','WriteMode','overwrite','Compression','none', ...
        'ColorSpace', 'rgb');
end
for c  = 1:3
    if imtype == 1
        imwrite(seq{c},...
        ['/Users/hwab/Dropbox (HHMI)/Phillipstuff/imagepr/bin/split' num2str(c) '.jpg']);
        imwrite(filtseq{c},...
        ['/Users/hwab/Dropbox (HHMI)/Phillipstuff/imagepr/bin/filt' num2str(c) '.jpg']);
    end
    if imtype == 2
        imwrite(seq{c},...
        ['/Users/hwab/Dropbox (HHMI)/Phillipstuff/imagepr/bin/split' num2str(c) '.tif'],...
        'tif','WriteMode','overwrite','Compression','none', ...
        'ColorSpace', 'rgb');
            imwrite(filtseq{c},...
        ['/Users/hwab/Dropbox (HHMI)/Phillipstuff/imagepr/bin/filt' num2str(c) '.tif'],...
        'tif','WriteMode','overwrite','Compression','none', ...
        'ColorSpace', 'rgb');
    end
end

