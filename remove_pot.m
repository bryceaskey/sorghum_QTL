%function to remove pot pixels from bottom of plant

function [all_plant, segmented_image] = remove_pot(all_plant, segmented_image, stalk, stake)

[height, width] = size(all_plant);

for row = 1160:1:height
    for col = 1:1:width
        if stalk(row, col) == 0 && stake(row, col) == 0
            all_plant(row, col) = 0;
            segmented_image(row, col, :) = 255;
        end
    end
end