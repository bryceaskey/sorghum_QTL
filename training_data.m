%get training data
clc; clear;

%in labeled_image:
% 0 - background
% 1 - leaf
% 2 - panicle
% 3 - stalk
labeled_image = imread('Documents/MATLAB/RGB_test4_json/label.png');
original_image = rgb2lab(imread('Documents/MATLAB/RGB_test4_json/img.png'));
[height, width] = size(labeled_image);
total_points = sum(sum(labeled_image(:, :) ~= 0));
training_points = zeros(total_points, 4);

point_count = 0;
for row = 1:1:height
    for col = 1:1:width
        pixel_label = labeled_image(row, col);
        if pixel_label ~= 0
            if pixel_label == 3
                point_count = point_count + 1;
                training_points(point_count, 1) = 4;
                training_points(point_count, 2) = original_image(row, col, 1);
                training_points(point_count, 3) = original_image(row, col, 2);
                training_points(point_count, 4) = original_image(row, col, 3);
            elseif pixel_label == 4
                point_count = point_count + 1;
                training_points(point_count, 1) = 3;
                training_points(point_count, 2) = original_image(row, col, 1);
                training_points(point_count, 3) = original_image(row, col, 2);
                training_points(point_count, 4) = original_image(row, col, 3);
            else
                point_count = point_count + 1;
                training_points(point_count, 1) = pixel_label;
                training_points(point_count, 2) = original_image(row, col, 1);
                training_points(point_count, 3) = original_image(row, col, 2);
                training_points(point_count, 4) = original_image(row, col, 3);
            end                
        end
    end
end