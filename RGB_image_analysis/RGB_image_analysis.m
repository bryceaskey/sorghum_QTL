%clc; clear; close all

total_folder_name = 'Desktop/SorghumSeedImages/SorghumImages';
folder_paths = [];
all_subfolders = dir(total_folder_name);

AllData = cell(length(all_subfolders), 6);

for ii = 1:1:length(all_subfolders)
    folder_name = strcat(all_subfolders(ii).folder, '/', all_subfolders(ii).name);
    fprintf('Now analyzing %s\n', all_subfolders(ii).name)

    %calls all functions used for RGB image processing, and loops over images from 5 camera angles
    %create table to hold all measured traits for a single plant
    CameraAngle = {};
    LeafAngleData = {}; %stores necessary data for leaf angle measurements -> only need to measure for image w/ greatest # of leaves
    SegmentedImages = {};
    StalkHeight = [];
    LeafCount = [];
    LeafAngle = [];
    PanicleExsertion = [];
    PanicleOpenness = [];
    PanicleSize = [];

    %thresholds for image background segmentation
    b_threshold = 9;
    L_threshold = 90;

    image_paths = [];
    all_image_subfolders = dir(folder_name);
    for jj = 1:1:length(all_image_subfolders)
        image_subfolder_name = all_image_subfolders(jj).name;
        if contains(image_subfolder_name, 'Vis_SV')
            filename = strcat(all_image_subfolders(jj).folder, '/', image_subfolder_name, '/0_0_0.png');
            
            all_plant = NaN;
            [image, all_plant, stake, stake_bin] = stake_segmentation(filename, b_threshold, L_threshold);
            RGB_image = lab2rgb(image);
            imshow(RGB_image);
            if ~isnan(all_plant)
                panicle_row = NaN;
                [panicle_row, panicle_col, circle_rows, circle_cols] = panicle_identification(all_plant, image, stake);
                if ~isnan(panicle_row)
                    stalk_line = NaN;
                    [all_plant, stalk_line, stalk_bot, panicle_base] = stalk_identification(all_plant, image, panicle_row, panicle_col, circle_rows, circle_cols);
                    if ~isnan(stalk_line)
                        %function for stake cleanup - any stake above panicle base should
                        %be deleted, and possibly reclassified as panicle
                        segmented_image = NaN;
                        [segmented_image, stalk, panicle, leaves, width_coeffs] = image_segmentation(all_plant, panicle_base, panicle_row, panicle_col, stalk_line, stalk_bot, stake);
                        
                        if ~isnan(segmented_image)
                            %function for pot pixel removal -> delete everything below cutoff,
                            %except for pixels matching stalk and stake lines
                            [all_plant, segmented_image] = remove_pot(all_plant, segmented_image, stalk, stake);

                            %[overlap] = leaf_overlap(segmented_image, stalk_line, width_coeffs, stalk_bot(1));

                            %if overlap == 1
                                %fprintf('Warning: Leaf overlap detected. Leaf counting and angle results might be unreliable.\n')
                            %end

                            [skeleton, endpoints, left_leaf_count, right_leaf_count] = leaf_counting_v2(all_plant, stake, stalk, panicle, stalk_line);

                            %[average_angle, flag_leaf_node] = leaf_angle_v2(all_plant, skeleton, stalk, stalk_line, stake, endpoints);

                            %CameraAngle{1, end + 1} = subfolder_name;
                            %SegmentedImages{1, end + 1} = segmented_image;
                            LeafCount = [LeafCount; left_leaf_count + right_leaf_count];
                            %LeafAngle = [LeafAngle; average_angle];
                            %StalkHeight = [StalkHeight; stalk_bot(1) - flag_leaf_node(1)];
                            
                            LeafAngleData{end + 1, 1} = left_leaf_count + right_leaf_count;
                            LeafAngleData{end, 2} = all_plant;
                            LeafAngleData{end, 3} = skeleton;
                            LeafAngleData{end, 4} = stalk;
                            LeafAngleData{end, 5} = stalk_line;
                            LeafAngleData{end, 6} = stake;
                            LeafAngleData{end, 7} = endpoints;
                            LeafAngleData{end, 8} = stalk_bot;
                            LeafAngleData{end, 9} = panicle_base;

                        else
                            %CameraAngle{1, end + 1} = subfolder_name;
                            %SegmentedImages{1, end + 1} = NaN;
                            LeafCount = [LeafCount; NaN];
                            %LeafAngle = [LeafAngle; NaN];
                            %StalkHeight = [StalkHeight; NaN];
                        end
                    else
                        %CameraAngle{1, end + 1} = subfolder_name;
                        %SegmentedImages{1, end + 1} = NaN;
                        LeafCount = [LeafCount; NaN];
                        %LeafAngle = [LeafAngle; NaN];
                        %StalkHeight = [StalkHeight; NaN];
                    end
                else
                    %CameraAngle{1, end + 1} = subfolder_name;
                    %SegmentedImages{1, end + 1} = NaN;
                    LeafCount = [LeafCount; NaN];
                    %LeafAngle = [LeafAngle; NaN];
                    %StalkHeight = [StalkHeight; NaN];
                end
            else
                %CameraAngle{1, end + 1} = subfolder_name;
                %SegmentedImages{1, end + 1} = NaN;
                LeafCount = [LeafCount; NaN];
                %LeafAngle = [LeafAngle; NaN];
                %StalkHeight = [StalkHeight; NaN];
            end
        end
    end
    
    MedianLeaves = NaN;
    MedianLeaves = round(nanmedian(LeafCount));
    MaxLeaves = NaN;
    MaxLeaves = nanmax(LeafCount);
    LeafAngle = NaN;
    StalkHeight = NaN;
    PanicleExsertion = NaN;
    
    if ~isnan(MaxLeaves)
        if MaxLeaves > 0 && MaxLeaves < 16
        
            ind = find([LeafAngleData{:, 1}] == MaxLeaves);
            ind = ind(1);

            all_plant = LeafAngleData{ind, 2};
            skeleton = LeafAngleData{ind, 3};
            stalk = LeafAngleData{ind, 4};
            stalk_line = LeafAngleData{ind, 5};
            stake = LeafAngleData{ind, 6};
            endpoints = LeafAngleData{ind, 7};
            stalk_bot = LeafAngleData{ind, 8};
            panicle_base = LeafAngleData{ind, 9};

            [average_angle, flag_leaf_node] = leaf_angle_v2(all_plant, skeleton, stalk, stalk_line, stake, endpoints);

            if ~isnan(average_angle)
                LeafAngle = average_angle;
            else
                LeafAngle = NaN;
            end

            if ~isnan(flag_leaf_node)
                StalkHeight = stalk_bot(1) - flag_leaf_node(1);
                PanicleExsertion = flag_leaf_node(1) - panicle_base(1);
                if PanicleExsertion < 0
                    PanicleExsertion = NaN;
                end
            end
        end
    end
        
    AllData{ii, 1} = all_subfolders(ii).name;
    AllData{ii, 2} = MedianLeaves;
    AllData{ii, 3} = MaxLeaves;
    AllData{ii, 4} = LeafAngle;
    AllData{ii, 5} = StalkHeight;
    AllData{ii, 6} = PanicleExsertion;
end

%all_seg = uint8(zeros(1250, 4000, 3));
%all_seg(1:1250, 1:800, :) = SegmentedImages{1};
%all_seg(1:1250, 801:1600, :) = SegmentedImages{2};
%all_seg(1:1250, 1601:2400, :) = SegmentedImages{3};
%all_seg(1:1250, 2401:3200, :) = SegmentedImages{4};
%all_seg(1:1250, 3201:4000, :) = SegmentedImages{5};
%imshow(all_seg)



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




