%% Repeatability, Accuracy and Backlash 
% The purpose of this code is to calculate displacement, repeatability, and
% backlash with a set of images. The images are taken throughout an
% experiment done on the CETCS assembly.

close all
clear all
clc

%% Load Images 
filename = dir('*.JPG');
numOfFiles = length(filename);

for i = 1:numOfFiles
      img(:,:,:,i) = imread(filename(i).name);
      disp(['file processed: ', filename(i).name]);
end

% Identify the image with the farthest deployed needle
farim = img(:,:,:,2);

%% Scale Images
% Scale FRONT Images
figure;
imshow(farim)
disp('Define Image Scales - FRONT')
h1 = imdistline(gca);
wait(h1);
api = iptgetapi(h1);
scalefront = api.getDistance()/2.99; %pixels/mm
close


% Scale BOTTOM Images
figure;
imshow(farim)
disp('Define Image Scales - BOTTOM')
h1 = imdistline(gca);
wait(h1);
api = iptgetapi(h1);
scalebot = api.getDistance()/2.99;
close


% Scale SIDE Images
figure;
imshow(farim)
disp('Define Image Scales - SIDE')
h1 = imdistline(gca); 
wait(h1);
api = iptgetapi(h1);
scaleside = api.getDistance()/2.99;
close

figure; imagesc(img(:,:,:,1));


%% Select multiple points in the FRONT image
figure;
Nf = 6; % number of points 
f_coords = zeros(Nf,2,13);
f_pts = cell(Nf,1);
disp('Select the front view image origin first. Then select Needles 1 to 6, respectively.')
    for n =  1:numOfFiles  %starts from 2, because the mapping image is image 1
        imagesc(img(:,:,:,n))    
        for ii = 1:Nf
            f_pts{ii} = drawpoint;
        end
        pause;
        for ii = 1:Nf 
            f_coords(ii,:,n) = f_pts{ii}.Position;
        end 
    end
close;

%% Select multiple points in the BOTTOM image   
figure;
Nb = 6; % number of points 
b_coords = zeros(Nb,2,13);
b_pts = cell(Nb,1);
disp('Select the bottom view origin first. Then select Needles 1 to 6, respectively.')
    for n =  1:numOfFiles %starts from 2, because the mapping image is image 1
        imagesc(img(:,:,:,n))    
        for ii = 1:Nb
            b_pts{ii} = drawpoint;
        end
        pause;
        for ii = 1:Nb 
            b_coords(ii,:,n) = b_pts{ii}.Position;
        end 
    end

    close;

%% Select multiple points in the SIDE image 
figure;
Ns = 6; % number of points 
s_coords = zeros(Ns,2,13);
s_pts = cell(Ns,1);
disp('Select the side view origin first. Then select Needles 1 to 6, respectively.')
    for n =  1:numOfFiles %starts from 2, because the mapping image is image 1
        imagesc(img(:,:,:,n))    
        for ii = 1:Ns
            s_pts{ii} = drawpoint;
        end
        pause;
        for ii = 1:Ns 
            s_coords(ii,:,n) = s_pts{ii}.Position;
        end 
    end
close;

%% Distance Analysis
stp = numOfFiles-1;
delta = zeros(6,13);

for d = 1:stp
deltaxz=(abs((f_coords(:,:,d+1)-f_coords(:,:,d))))/scalefront;
deltayz=(abs((s_coords(:,:,d+1)-s_coords(:,:,d))))/scaleside;
deltaxy=(abs((b_coords(:,:,d+1)-b_coords(:,:,d))))/scalebot;

deltax=(deltaxz(:,1)+deltaxy(:,1))/2;
deltay=(deltayz(:,1)+deltaxy(:,2))/2;
deltaz=(deltaxz(:,2)+deltayz(:,2))/2;
deltax(1,1)=deltaxz(1,1);
deltay(1,1)=deltayz(1,1);

delta(:,d) =sqrt(deltax.^2+deltay.^2+deltaz.^2);

end

%% Repeatability 

% Assign parts of the data to respective matrices 
deploy = delta(:, [2, 6, 10]);
retract = delta(:, [4, 8, 12]);
r2d = delta(:, [1, 5, 9]);
d2r = delta(:, [3, 7, 11]);

% Deploy 
dm  = mean(deploy,2);
dl = abs(deploy- dm);
avg_dl = mean(dl,2);
dl2 = (dl-avg_dl).^2;
dsv = sqrt(sum(dl2, 2)/(size(deploy,2)-1));
rep_d = 3*dsv + avg_dl;

% Retract 
rm  = mean(retract,2);
rl = abs(retract- rm);
avg_rl = mean(rl,2);
rl2 = (rl-avg_rl).^2;
rsv = sqrt(sum(rl2, 2)/(size(retract,2)-1));
rep_r = 3*rsv + avg_rl;

%% Backlash

% Retract to Deploy 
bk_r2d = 5 - r2d; 
r2d_bk = mean(bk_r2d,2);

% Deploy to Retract 
bk_d2r = 5 - d2r;  
d2r_bk = mean(bk_d2r,2);




