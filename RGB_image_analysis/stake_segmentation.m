%stake_segmentation
%identifies and separates stake pixels if a plant is staked

function [image, all_plant, stake, stake_bin] = stake_segmentation(filename)
image = imread(filename);
image = imcrop(image, [850, 500, 899, 1249]);
image = rgb2lab(image);

[height, width, ~] = size(image);
all_plant = ones(height, width);

%background removal
for row = 1:1:height
    for col = 1:1:width
        if image(row, col, 3) <= 8
            all_plant(row, col) = 0;
        end
    end
end
all_plant = bwareaopen(all_plant, 300);
all_plant = bwareafilt(all_plant, 1);

%problem - panicle and some stalk pixels are being classified as stake
stake = zeros(height, width);
for row = 1:1:height
    for col = 1:1:width
        if all_plant(row, col) == 1 && image(row, col, 1) >= 30 && image(row, col, 2) >= 5 %stake color
            stake(row, col) = 1;
        end
    end
end
stake = imcrop(stake, [0, 0, 900, 1165]); %pot cutoff
stake = bwareaopen(stake, 100);

%fit line to median stake values
[height, width] = size(stake);
line_stake_pixels = [];
for row = 1:1:height
    stake_pixel_count = sum(stake(row, :) == 1) > 0; %test if row contains stake
    y_coordinates = zeros(1, stake_pixel_count);
    if stake_pixel_count > 0
        pixel_count = 0;
        for col = 1:1:width
            if stake(row, col) == 1
                pixel_count = pixel_count + 1;
                y_coordinates(1, pixel_count) = col;
            end
        end
        line_stake_pixels = [line_stake_pixels; row, median(y_coordinates)];
    end
end

%outlier removal
line_stake_pixels = rmoutliers(line_stake_pixels);

%fit line to median stake coordinates
stake_line = polyfit(line_stake_pixels(:, 1), line_stake_pixels(:, 2), 2);


%remove pixels in stake greater than 5 away from centerline, but don't fill in vertical gaps
%gaps are spots where leaves or stem overlap with stake
stake_width = 10;
stake_top = min(line_stake_pixels(:, 1));
stake_bot = max(line_stake_pixels(:, 1));
for row = stake_top:1:stake_bot
    stake_center = stake_line(1)*row.^2 + stake_line(2)*row + stake_line(3);
    stake_range = [round(stake_center - stake_width/2), round(stake_center + stake_width/2)];
    for col = 1:1:width
        if stake(row, col) == 1
            if col < stake_range(1) || col > stake_range(2) %outside of range
                stake(row, col) = 0;
            end
        end
    end
end

pixels = sum(sum(stake(:, :) == 1));
if pixels >= 1000 %minimum number of stake pixels need for detection
    stake_bin = 1;
else
    stake_bin = 0;
end

if stake_bin == 1 %only fill in gaps if stake is detected
    for row = stake_top:1:stake_bot
    stake_center = stake_line(1)*row.^2 + stake_line(2)*row + stake_line(3);
    stake_range = [round(stake_center - stake_width/2), round(stake_center + stake_width/2)];
        for col = 1:1:width
            if stake(row, col) == 0
                if col >= stake_range(1) && col <= stake_range(2)
                    stake(row, col) = 1;
                end
            end
        end
    end
end

%correct stake for cropped pixels so that coordinates match all_plant
%add 85 rows
current_height = height;
[height, ~] = size(all_plant);
for row = current_height + 1:1:height
    stake(row, :) = 0;
end

%remove stake pixels from all_plant
% if stake_bin == 1
%     for row = 1:1:height
%         for col = 1:1:width
%             if stake(row, col) == 1
%                 all_plant(row, col) = 0;
%             end
%         end
%     end
% end

all_plant = bwareaopen(all_plant, 150);
end