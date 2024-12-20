%% Needle Distance Evaluation in 2-D for Repeatability Experiments 
% Created by Julia Lee on 06/05/2024
% Last edit: 11/11/24
% The purpose of this code is to automate image processing and endpoint 
% detection to calculate the displacement, repeatability, and backlash 
% values of a set of microneedle images.

close all
clear
clc


%% Load Images 
filename = dir('*.JPG');
numOfFiles = length(filename);
img = imread(filename(1).name);
img = zeros(size(img), 'uint8');

for i = 1:numOfFiles 
      img(:,:,:,i) = imread(filename(i).name);
      disp(['File processed: ', filename(i).name]);
end

% Identify the image with the farthest deployed needle
far_img = img(:,:,:,3);



%% Scale Images
count = 1;
position = [4700, 3000];  % Position on img for text
scale = zeros(1, 3);

for n = 1:3
    if count == 1
        txt = 'Define Image Scales - FRONT';  % Front image
    elseif count == 2
        txt = 'Define Image Scales - BOTTOM'; % Bottom image
    else
        txt = 'Define Image Scales - SIDE';   % Side image
    end

    % Text in img
    RGB = insertText(far_img, position, txt, FontSize=100, AnchorPoint="RightTop");
    imshow(RGB)
    disp(txt)

    % Find scale
    h1 = drawline;
    wait(h1);
    pos = h1.Position;

    diffPos = diff(pos);
    length_roi = hypot(diffPos(1), diffPos(2));   % Distance in pixels
    scale(count) = length_roi/2.99;   % Known distance: 2.99 mm
    close

    count = count + 1;
end

 
%% Crop Images to Front, Side, and Bottom 
count = 1;
imcrp = zeros(3,4);

for n = 1:3
    if count == 1
        view = 'FRONT';  % Front image
    elseif count == 2
        view = 'BOTTOM'; % Bottom image
    else
        view = 'SIDE';   % Side image
    end

    % Text in img
    text_view = "Select Center view of the " + view + " ROI. Double-click rectangle to continue.";
    RGB = insertText(far_img, position, text_view, FontSize=100, AnchorPoint="RightTop");
    imshow(RGB)

    set(gcf,'name','Test','numbertitle','off') % set figure handles
    disp(text_view)

    % Crop using rectangle
    roi_rect = drawrectangle(Label=view, LabelAlpha=0); % creates draggable rectangle
    wait(roi_rect);
    imcrp(count,:) = roi_rect.Position; 

    count = count + 1;
end

f_roi = imcrp(1, :);
b_roi = imcrp(2, :);
s_roi = imcrp(3, :);

close


%% Apply crop to rest of the images.
for i = 1:size(img,4)
   crop_front(:,:,:,i) = imcrop(img(:,:,:,i), f_roi); % Applies FRONT ROI
   crop_bot(:,:,:,i) = imcrop(img(:,:,:,i), b_roi); % Applies SIDE ROI
   crop_side(:,:,:,i) = imcrop(img(:,:,:,i), s_roi); % Applies BOTTOM ROI
end


%% Convert images to grayscale and apply Gaussian Filter/Laplacian of Gaussian
for i = 1:size(img,4)
    imgr_front(:,:,:,i) = imgaussfilt(rgb2gray(imlocalbrighten(crop_front(:,:,:,i))), 0.6); % Applies FRONT ROI
    imgr_bot(:,:,:,i) = imgaussfilt(rgb2gray(imlocalbrighten(crop_bot(:,:,:,i))), 0.6); % Applies SIDE ROI
    imgr_side(:,:,:,i) = imgaussfilt(rgb2gray(imlocalbrighten(crop_side(:,:,:,i))), 0.6); % Applies BOTTOM ROI
end


%% Apply Canny Edge Detection
for i = 1:size(img,4)
    edge_front(:,:,i) = edge(imgr_front(:,:,:,i),'Canny', 0.3); % Applies FRONT ROI
    edge_bot(:,:,i) = edge(imgr_bot(:,:,:,i),'Canny', 0.3); % Applies BOTTOM ROI
    edge_side(:,:,i) = edge(imgr_side(:,:,:,i),'Canny', 0.2); % Applies SIDE ROI
end



%% Sharpen using imclose
se = strel("disk", 4); 
for i = 1:size(img, 4)
    a_front(:,:,i) = imclose(edge_front(:,:,i), se);
    a_bot(:,:,i) = imclose(edge_bot(:,:,i), se);
    a_side(:,:,i) = imclose(edge_side(:,:,i), se);
end 



%% Apply Hough Tranform 
for i = 1:size(img, 4)
  
    [H_front,theta_front,rho_front] = hough(a_front(:,:,i));
    P_front = houghpeaks(H_front,6, 'Threshold', 0.1*max(H_front(:)));
    lines_front = houghlines(a_front(:,:,i),theta_front,rho_front,P_front,'FillGap', 60, 'MinLength', 50);
   
    [H_bottom,theta_bottom,rho_bottom] = hough(a_bot(:,:,i));
    P_bottom = houghpeaks(H_bottom,5,'Threshold', 0.1*max(H_bottom(:)),'NHoodSize', [71 77]); 
    lines_bottom = houghlines(a_bot(:,:,i),theta_bottom,rho_bottom,P_bottom, 'FillGap', 60, 'MinLength', 60);

    
    [H_side,theta_side,rho_side] = hough(a_side(:,:,i));
    P_side = houghpeaks(H_side,6,'Threshold', 0.6*max(H_side(:)),'NHoodSize', [31 17]);   % Locates the N top peaks in the Hough transform matrix H
    lines_side = houghlines(a_side(:,:,i),theta_side,rho_side,P_side);


    % Organize needle coordinates
    thetaBot = [lines_bottom().theta];
    [~, b_ind] = sort(thetaBot, 'descend');


     for n = 1:length(lines_front)
        xy_front(:,:,n,i) = [lines_front(n).point1; lines_front(n).point2];
     end

      for b = 1:length(lines_bottom)
        v = b_ind(b);
        xy_bottom(:,:,b,i) = [lines_bottom(v).point1; lines_bottom(v).point2];
      end

      for n = 1:length(lines_side)
        xy_side(:,:,n,i) = [lines_side(n).point1; lines_side(n).point2];
      end
end



%% Endpoint determination
endPointBot = 0;

mid = regionprops(a_bot(:,:,i), "Centroid");
center = mid.Centroid;

for i = 1:size(img, 4)
    bottomPoints(:,:,1,i) = center;
    for n = 1:6
        if n > 1
            for m = 1:2
                bot = xy_bottom(m,:,n-1,i);
                bottomPointsDist = norm(bot-center);
                if bottomPointsDist > endPointBot
                    endPointBot = bottomPointsDist;
                    bottomPoints(:,:,n,i) = bot;
                end
            end
            endPointBot = 0;
        end
    end 
end



for i = 1:size(img, 4)
    front_Points = [xy_front(2,1,:,i)];
    side_Points = [xy_side(2,1,:,i)];

    [~, frontind] = sort(front_Points, 'ascend');
    [~, sideind] = sort(side_Points, 'ascend');

    for f = 1:length(frontind)
        ind = frontind(f);
        frontPoints(:,:,f,i) = xy_front(2,:,ind,i);
    end

    for s = 1:length(sideind)
        ind = sideind(s);
        sidePoints(:,:,s,i) = xy_side(2,:,ind,i);
    end
end


%% Sliding ROI for refining endpoint selection
% Width and height of rectangle
size_crp = [25 35];

for i = 1:size(img,4)
    frt_axes = [frontPoints(:,1,:,i)-(size_crp(1)/2) frontPoints(:,2,:,i)-(size_crp(2)/2)];
    bot_axes = [bottomPoints(:,1,:,i)-(size_crp(1)/2) bottomPoints(:,2,:,i)-(size_crp(2)/2)];
    side_axes = [sidePoints(:,1,:,i)-(size_crp(1)/2) sidePoints(:,2,:,i)-(size_crp(2)/2)];
    
    % ROI
    for n = 1:6
        froi(:,:,n,i) = [frt_axes(:,:,n)+5 size_crp];
        sroi(:,:,n,i) = [side_axes(:,:,n)+5 size_crp];

  
            broi(:,:,n,i) = [bot_axes(:,:,n)+5 size_crp];
        
    end
end



%% Apply rect

for i = 1:size(img,4)
    for n = 1:6
        frt_needle = imcrop(a_front(:,:,i), froi(:,:,n,i)); % Applies FRONT ROI
        side_needle = imcrop(a_side(:,:,i), sroi(:,:,n,i)); % Applies SIDE ROI

        extremafrt = bwmorph(frt_needle, "skel", Inf);
        pts_frt = bwmorph(extremafrt, "endpoints");
        [frt_col, frt_row] = find(pts_frt, 6, 'last');
        array_frt = [frt_row frt_col];

        extremaside = bwmorph(side_needle, "skel", Inf);     
        pts_side = bwmorph(extremaside, "endpoints");  
        [side_col, side_row] = find(pts_side, 6, 'last');
        array_side = [side_row side_col];

        mindist = 10000;
        ctr = flip(size(extremafrt)/2);
        for m = 1:length(array_frt)
            dist_frt = norm(array_frt(m,:)-ctr);
            if dist_frt < mindist
                frt_endpoints(:,:,n,i) = array_frt(m,:);
                mindist = dist_frt;
            end
        end

        mindist = 10000;
        ctr = flip(size(extremaside)/2);
        for m = 1:length(array_side)
            dist_side = norm(array_side(m,:)-ctr);
            if dist_side < mindist
                side_endpoints(:,:,n,i) = array_side(m,:);
                mindist = dist_side;
            end
        end
    end
    
 
    for n = 2:6
         bot_needle = imcrop(a_bot(:,:,i), broi(:,:,n,i)); % Applies BOTTOM ROI
         extremabot = bwmorph(bot_needle, "skel", Inf);
         pts_bot = bwmorph(extremabot, "endpoints");
         [bot_col, bot_row] = find(pts_bot, 5, 'last');
         array_bot = [bot_row bot_col];

        mindist = 10000;
        ctr = flip(size(extremabot)/2);
        for m = 1:length(array_bot)
            dist_bot = norm(array_bot(m,:)-ctr);
            if dist_bot < mindist
                bot_endpoints(:,:,n,i) = array_bot(m,:);
                mindist = dist_bot;
            end
        end
    end  
end



%% Adjust points
pos = [400, 400];
figure;
bot_img = crop_bot(:,:,:,3);
text_view = "Select needle 1 for bottom image. Click enter to continue.";
RGB = insertText(bot_img, pos, text_view, FontSize=12, AnchorPoint="RightTop");
imshow(RGB)
pt = drawpoint;
ctr_bt = pt.Position;

for i = 1:size(img, 4)
    frt_pts(:,:,:,i) = [frt_endpoints(:,1,:,i)+froi(:,1,:,i) frt_endpoints(:,2,:,i)+froi(:,2,:,i)];
    bot_pts(:,:,:,i) = [bot_endpoints(:,1,:,i)+broi(:,1,:,i) bot_endpoints(:,2,:,i)+broi(:,2,:,i)];
    bot_pts(:,:,1,i) = ctr_bt;
    bottomPoints(:,:,1,i) = ctr_bt;
    side_pts(:,:,:,i) = [side_endpoints(:,1,:,i)+sroi(:,1,:,i) side_endpoints(:,2,:,i)+sroi(:,2,:,i)];
end





%% Adjust to labeled needle orientation
close all
color = ["r","b","c","m","g","k"];

ft = figure;
figure(ft);
imshow(imgr_front(:,:,:,3))
title("Front")
hold on;
for n = 1:length(lines_front)
    x_h(:) = frontPoints(:,1,n,:);
    y_h(:) = frontPoints(:,2,n,:);
    x_end(:) = frt_pts(:,1,n,:);
    y_end(:) = frt_pts(:,2,n,:);
    plot(x_h, y_h,'o','MarkerSize', 5, 'Color', color(n));
    plot(x_end, y_end,'*','MarkerSize', 5, 'Color', color(n));
    figure(ft);
    pause(0.5);
    prmt = "Input needle number(front): ";
    needle = input(prmt);
    for i = 1:size(img, 4)
        fin_ft_pt(:,:,needle,i) = frt_pts(:,:,n,i);
        frtPoints(:,:,needle,i) = frontPoints(:,:,n,i);
    end
end


bt = figure;
figure(bt); 
imshow(imgr_bot(:,:,:,3))
title("Bottom")
hold on;
for m = 1:length(lines_bottom)+1
    x_h(:) = bottomPoints(:,1,m,:);
    y_h(:) = bottomPoints(:,2,m,:);
    x_end(:) = bot_pts(:,1,m,:);
    y_end(:) = bot_pts(:,2,m,:);
    plot(x_h, y_h,'o','MarkerSize', 5, 'Color', color(m));
    plot(x_end, y_end,'*','MarkerSize', 5, 'Color', color(m));
    figure(bt);
    pause(0.5);
    prmt = "Input needle number(bottom): ";
    needle = input(prmt);
    for i = 1:size(img, 4)
        fin_bot_pt(:,:,needle,i) = bot_pts(:,:,m,i);
        btPoints(:,:,needle,i) = bottomPoints(:,:,m,i);
    end
end


sd = figure;
figure(sd); 
imshow(imgr_side(:,:,:,3))
title("Side")
hold on;
for p = 1:length(lines_side)
    x_h(:) = sidePoints(:,1,p,:);
    y_h(:) = sidePoints(:,2,p,:);
    x_end(:) = side_pts(:,1,p,:);
    y_end(:) = side_pts(:,2,p,:);
    plot(x_h, y_h,'o','MarkerSize', 5, 'Color', color(p));
    plot(x_end, y_end,'*','MarkerSize', 5, 'Color', color(p));
    figure(sd);
    pause(0.5);
    prmt = "Input needle number(side): ";
    needle = input(prmt);
    for i = 1:size(img, 4)
        fin_side_pt(:,:,needle,i) = side_pts(:,:,p,i);
        sdPoints(:,:,needle,i) = sidePoints(:,:,p,i);
    end
end
close



%% Find displacement and scales
scaleFront = scale(1);
scaleBottom = scale(2);
scaleSide = scale(3);

for d = 1:size(img, 4)-1
    deltaxz=(abs(fin_ft_pt(:,:,:,d+1)-fin_ft_pt(:,:,:,d)))/scaleFront;
    deltayz=(abs(fin_side_pt(:,:,:,d+1)-fin_side_pt(:,:,:,d)))/scaleSide;
    deltaxy=(abs(fin_bot_pt(:,:,:,d+1)-fin_bot_pt(:,:,:,d)))/scaleBottom; 
  
    deltax=(deltaxz(:,1,:)+deltaxy(:,1,:))/2;
    deltay=(deltayz(:,1,:)+deltaxy(:,2,:))/2;
    deltaz=(deltaxz(:,2,:)+deltayz(:,2,:))/2;  % yz is problematic
    deltax(1,1)=deltaxz(1,1);
    deltay(1,1)=deltayz(1,1);
    
    delta(:,d) =sqrt(deltax.^2+deltay.^2+deltaz.^2);

end



%% Repeatability Evaluation
% Deploy: delta 2, 6, 10
deploy = delta(:, [2, 6, 10]);
dm  = mean(deploy,2);
dl = abs(deploy- dm);
avg_dl = mean(dl,2);
dl2 = (dl-avg_dl).^2;
dsv = sqrt(sum(dl2, 2)/(size(deploy,2)-1));
rep_d = 3*dsv + avg_dl;

% Retract: delta 4, 8, 12
retract = delta(:, [4, 8, 12]);
rm  = mean(retract,2);
rl = abs(retract- rm);
avg_rl = mean(rl,2);
rl2 = (rl-avg_rl).^2;
rsv = sqrt(sum(rl2, 2)/(size(retract,2)-1));
rep_r = 3*rsv + avg_rl;





%% Backlash Evaluation
% Retract to Deploy 
% R2D: delta 1, 5, 9
r2d = delta(:, [1, 5, 9]);
bk_r2d = 5 - r2d; 
r2d_bk = mean(bk_r2d,2);

% Deploy to Retract 
% D2R: delta 3, 7, 11
d2r = delta(:, [3, 7, 11]);
bk_d2r = 5 - d2r;  
d2r_bk = mean(bk_d2r,2);


%% Accuracy Evaluation Plot
close all
figure; 

subplot(1,3,1); 
imshow(imgr_front(:,:,:,3))
subplot(1,3,2); 
imshow(imgr_bot(:,:,:,3))
subplot(1,3,3); 
imshow(imgr_side(:,:,:,3))

color = ["r","b","c","m","g","k"];

for i = 1:size(img, 4)
    subplot(1,3,1); 
    hold on;
    for n = 1:length(lines_front)
       plot(frtPoints(:,1,n,i), frtPoints(:,2,n,i),'o','MarkerSize', 5, 'Color', color(n));
       plot(fin_ft_pt(:,1,n,i), fin_ft_pt(:,2,n,i),'*','MarkerSize', 5, 'Color', color(n));
       text(fin_ft_pt(:,1,n,i), fin_ft_pt(:,2,n,i),int2str(n))
    end

    subplot(1,3,2); 
    hold on;
    plot(center(1,1), center(1,2), '*','MarkerSize', 5); 
    for m = 1:length(lines_bottom)+1
       plot(btPoints(:,1,m,i), btPoints(:,2,m,i),'o','MarkerSize', 5, 'Color', color(m));
       plot(fin_bot_pt(:,1,m,i), fin_bot_pt(:,2,m,i),'*','MarkerSize', 5, 'Color', color(m));
       text(fin_bot_pt(:,1,m,i), fin_bot_pt(:,2,m,i),int2str(m))
    end


    subplot(1,3,3); 
    hold on;
    for p = 1:length(lines_side)
       plot(sdPoints(:,1,p,i), sdPoints(:,2,p,i),'o','MarkerSize', 5, 'Color', color(p));
       plot(fin_side_pt(:,1,p,i), fin_side_pt(:,2,p,i),'*','MarkerSize', 5, 'Color', color(p));
       text(fin_side_pt(:,1,p,i), fin_side_pt(:,2,p,i),int2str(p))
    end
end

 


