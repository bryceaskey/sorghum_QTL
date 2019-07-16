%calls all functions used for RGB image processing, and loops over images from 5 camera angles
clc; clear; close all

%create table to hold all measured traits for a single plant
CameraAngle = {};
SegmentedImages = {};
StalkHeight = [];
LeafCount = [];
LeafAngle = [];
PanicleExsertion = [];
PanicleOpenness = [];
PanicleSize = [];

%thresholds for image background segmentation
b_threshold = 7;
L_threshold = 90;

folder_name = 'Desktop/SorghumSeedImages/SorghumImages/1-26-18_Sorghum_seed_915-011-PI 658768_2018-01-26_12-42-38_6696300';
image_paths = [];
all_subfolders = dir(folder_name);
for ii = 1:1:length(all_subfolders)
    subfolder_name = all_subfolders(ii).name;
    if contains(subfolder_name, 'Vis_SV')
        fprintf('Now analyzing %s\n', subfolder_name)
        filename = strcat(all_subfolders(ii).folder, '/', subfolder_name, '/0_0_0.png');
        [image, all_plant, stake, stake_bin] = stake_segmentation(filename, b_threshold, L_threshold);

        [panicle_row, panicle_col, circle_rows, circle_cols] = panicle_identification(all_plant, image, stake, stake_bin);

        [all_plant, stalk_line, stalk_bot, panicle_base] = stalk_identification(all_plant, image, panicle_row, panicle_col, circle_rows, circle_cols);
        
        %function for stake cleanup - any stake above panicle base should
        %be deleted, and possibly reclassified as panicle
        
        [segmented_image, stalk, panicle, leaves, width_coeffs] = image_segmentation(all_plant, panicle_base, panicle_row, panicle_col, stalk_line, stalk_bot, stake);

        %function for pot pixel removal -> delete everything below cutoff,
        %except for pixels matching stalk and stake lines
        
        [all_plant, segmented_image] = remove_pot(all_plant, segmented_image, stalk, stake);
        
        [overlap] = leaf_overlap(segmented_image, stalk_line, width_coeffs, stalk_bot(1));

        if overlap == 1
            fprintf('Warning: Leaf overlap detected. Leaf counting and angle results might be unreliable.\n')
        end

        [skeleton, endpoints, left_leaf_count, right_leaf_count] = leaf_counting_v2(all_plant, stake, stalk, panicle, stalk_line);
        
        [average_angle] = leaf_angle_v2(all_plant, skeleton, stalk, stalk_line, stake, endpoints);
        
        CameraAngle{1, end + 1} = subfolder_name;
        SegmentedImages{1, end + 1} = segmented_image;
        LeafCount = [LeafCount; left_leaf_count + right_leaf_count];
        LeafAngle = [LeafAngle; average_angle];
    end
end

all_seg = uint8(zeros(1250, 4000, 3));
all_seg(1:1250, 1:800, :) = SegmentedImages{1};
all_seg(1:1250, 801:1600, :) = SegmentedImages{2};
all_seg(1:1250, 1601:2400, :) = SegmentedImages{3};
all_seg(1:1250, 2401:3200, :) = SegmentedImages{4};
all_seg(1:1250, 3201:4000, :) = SegmentedImages{5};
imshow(all_seg)



%[left_angle_data] = left_leaf_angle(segmented_image, left_leaf_count, 80, stalk_line, width_coeffs);

%[right_angle_data] = right_leaf_angle(segmented_image, right_leaf_count, 80, stalk_line, width_coeffs);

%all_angles = [left_angle_data(:, 3); right_angle_data(:, 3)];
%average_leaf_angle = mean(all_angles);
%leaf_angle_std = std(all_angles);
%txt1 = ['Left Leaf Count: ', num2str(left_leaf_count)];
%txt2 = ['Right Leaf Count: ', num2str(right_leaf_count)];
%txt3 = ['Average Leaf Angle: ', num2str(average_leaf_angle), ' deg'];
%txt4 = ['Leaf Angle Standard Deviation: ', num2str(leaf_angle_std)];
%txt5 = ['Stalk Height: ', num2str(stalk_bot(1) - panicle_base(1))]
%text(4, 10, txt1, 'Color', 'white')
%text(4, 30, txt2, 'Color', 'white')
%text(4, 50, txt3, 'Color', 'white')
%text(4, 70, txt4, 'Color', 'white')

%end




