%calculate plant height from segmented image

%input is a 3d matrix
%first two dimensions describe location
%third dimension is organ classification:
%background = 0
%leaves = 1
%stalk = 2
%panicle = 3

%randomized array for testing purposes
image = randi(4, 400, 600);
image(:, :) = image(:, :) - 1;

%function [overall_height, stem_height, panicle_height] = plant_height(filename)
%image = readmatrix(filename);
[height, width] = size(image);

%initialize arrays to hold pixel information
stalk_pixels = zeros(sum(image(:) == 2), 2); %row, column
panicle_pixels = zeros(sum(image(:) == 3), 2); %row, column

stalk_pixel_count = 0;
panicle_pixel_count = 0;
for row = 1:1:height
    for col = 1:1:width
        if image(row, col) == 2
            stalk_pixel_count = stalk_pixel_count + 1;
            stalk_pixels(stalk_pixel_count, 1) = row;
            stalk_pixels(stalk_pixel_count, 2) = col;
        elseif image(row, col) == 3
            panicle_pixel_count = panicle_pixel_count + 1;
            panicle_pixels(panicle_pixel_count, 1) = row;
            panicle_pixels(panicle_pixel_count, 2) = col;
        end
    end
end
            
stalk_bot = max(stalk_pixels(:, 1));
stalk_top = min(stalk_pixels(:, 1));
panicle_bot = max(panicle_pixels(:, 1));
panicle_top = min(panicle_pixels(:, 1));

stalk_height = 1 + (stalk_bot - stalk_top);
panicle_height = 1 + (panicle_bot - panicle_top);

%end