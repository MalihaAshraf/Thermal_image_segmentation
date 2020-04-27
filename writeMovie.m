function writeMovie(vid_frames, timelapse_cropped, outliers, vid_name)

if length(vid_frames) > 1
    skin = true;
    img_d = vid_frames{2};
end
I_seg = vid_frames{1};

v = VideoWriter(vid_name, 'MPEG-4');
v.Quality = 100;
% v.FileFormat = 'mp4';
open(v);

for k = 1:10:2800%length(I_seg)
   if k >= length(I_seg)
       break;
   end
    k1 = k;
    while (outliers(k1)) 
       k1 = k1+1;
       if k1 >= length(I_seg)
           break;
       end
    end
    
    if skin
        imgt = I_seg(:,:,k1);
        imgd = img_d{k1};
        imgc = imgt - imgd;
        imgk = cat(3, imgt, imgc, imgc);
    else
        imgk = I_seg(:,:,k1);
    end
   img = imresize(imfuse(timelapse_cropped(:,:, k1),...
       imgk,... 
       'montage'), 2);
   writeVideo(v, img);
    
end

close(v); 
end

