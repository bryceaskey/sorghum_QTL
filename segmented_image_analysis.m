%calls all image analysis functions to analzye an already segmented image
clc; clear;
close all

[segmented_image, shape_coeffs, stalk_range, width_coeffs, cutoff] = stalk_cleanup('Documents/MATLAB/CM048_2017-08-30.png');

[segmented_image, overlap] = leaf_overlap(segmented_image, shape_coeffs, width_coeffs, cutoff);

if overlap == 1
    fprintf('Warning: Leaf overlap detected. Leaf counting and angle results might be unreliable.\n')
end

[segmented_image, left_leaf_count, right_leaf_count] = leaf_counting(segmented_image, 20, shape_coeffs, width_coeffs, cutoff);

[left_angle_data] = left_leaf_angle(segmented_image, left_leaf_count, 30, shape_coeffs, width_coeffs);

[right_angle_data] = right_leaf_angle(segmented_image, right_leaf_count, 30, shape_coeffs, width_coeffs);

all_angles = [left_angle_data(:, 3); right_angle_data(:, 3)];
average_leaf_angle = mean(all_angles);
leaf_angle_std = std(all_angles);
txt1 = ['Left Leaf Count: ', num2str(left_leaf_count)];
txt2 = ['Right Leaf Count: ', num2str(right_leaf_count)];
txt3 = ['Average Leaf Angle: ', num2str(average_leaf_angle), ' deg'];
txt4 = ['Leaf Angle Standard Deviation: ', num2str(leaf_angle_std)];
text(4, 10, txt1, 'Color', 'white')
text(4, 30, txt2, 'Color', 'white')
text(4, 50, txt3, 'Color', 'white')
text(4, 70, txt4, 'Color', 'white')
