%visualize output predictions

predicted = output; %readmatrix('Documents/MATLAB/predicted.mat');
[height, width] = size(predicted);

false_color = uint8(zeros(height, width, 3));

for row = 1:1:height
    for col = 1:1:width
        if predicted(row, col) == 0 %background
            false_color(row, col, :) = [229, 229, 229]; %gray
        elseif predicted(row, col) == 1 %leaves
            false_color(row, col, :) = [11, 114, 0]; %green
        elseif predicted(row, col) == 2 %stalk
            false_color(row, col, :) = [255, 211, 53]; %orange
        else %panicle
            false_color(row, col, :) = [223, 119, 255]; %purple
        end
    end
end
imshow(false_color)