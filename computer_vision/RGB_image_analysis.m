clc; clear; close all
warning('off', 'all')

total_folder_name = '\\client\d$\sorghumImages';
folder_paths = [];
all_subfolders = dir(total_folder_name);
AllData = cell(length(all_subfolders), 7); %fileName/cameraAngle/medianLeafCount/maxLeafCount/leafAngle/stalkHeight/panicleExsertion

for ii = 5:1:length(all_subfolders)
    folder_name = strcat(all_subfolders(ii).folder, '\', all_subfolders(ii).name);
    fprintf('Now analyzing %s\n', all_subfolders(ii).name)

    LeafAngleData = {}; %stores necessary data for leaf angle measurements -> only need to measure for image w/ greatest # of leaves
    LeafCount = [];

    %thresholds for image background segmentation
    b_threshold = 9;
    L_threshold = 90;

    all_image_subfolders = dir(folder_name);
    
    %calls all functions used for RGB image processing, and loops over images from 5 camera angles
    %create table to hold all measured traits for a single plant
    for jj = 1:1:length(all_image_subfolders)
        image_subfolder_name = all_image_subfolders(jj).name;
        %each RGB image is saved in folder with name containing Vis_SV
        %image angle is also included in folder name
        if contains(image_subfolder_name, 'Vis_SV')
            %all RGB images are named '0_0_0.png'
            camera_angle = all_image_subfolders(jj).name;
            filename = strcat(all_image_subfolders(jj).folder, '/', image_subfolder_name, '/0_0_0.png');
            all_plant = NaN;
            
            disp('Segmenting stake')
            [image, all_plant, stake] = stake_segmentation(filename, b_threshold, L_threshold);
            
            if ~isnan(all_plant)
                panicle_row = NaN;
                
                disp('Identifying panicle')
                [panicle_row, panicle_col, circle_rows, circle_cols] = panicle_identification(all_plant, image, stake);
                
                if ~isnan(panicle_row)
                    stalk_line = NaN;
                    
                    disp('Identifying stalk')
                    [all_plant, stalk_line, stalk_bot, panicle_base] = stalk_identification(all_plant, image, panicle_row, panicle_col, circle_rows, circle_cols);
                    
                    if ~isnan(stalk_line)
                        segmented_image = NaN;
                        
                        disp('Segmenting image')
                        [segmented_image, stalk, panicle, leaves, width_coeffs] = image_segmentation(all_plant, panicle_base, panicle_row, panicle_col, stalk_line, stalk_bot, stake);
                        
                        if ~isnan(segmented_image)
                            
                            disp('Removing pot')
                            [all_plant, segmented_image] = remove_pot(all_plant, segmented_image, stalk, stake);
                            
                            disp('Counting leaves')
                            [skeleton, endpoints, left_leaf_count, right_leaf_count] = leaf_counting_v2(all_plant, stake, stalk, panicle, stalk_line);
                            
                            LeafCount = [LeafCount; left_leaf_count + right_leaf_count];
                            LeafAngleData{end + 1, 1} = left_leaf_count + right_leaf_count;
                            LeafAngleData{end, 2} = all_plant;
                            LeafAngleData{end, 3} = skeleton;
                            LeafAngleData{end, 4} = stalk;
                            LeafAngleData{end, 5} = stalk_line;
                            LeafAngleData{end, 6} = stake;
                            LeafAngleData{end, 7} = endpoints;
                            LeafAngleData{end, 8} = stalk_bot;
                            LeafAngleData{end, 9} = panicle_base;
                            LeafAngleData{end, 10} = camera_angle;
                        else
                            LeafCount = [LeafCount; NaN];
                        end
                    else
                        LeafCount = [LeafCount; NaN];
                    end
                else
                    LeafCount = [LeafCount; NaN];
                end
            else
                LeafCount = [LeafCount; NaN];
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
    CameraAngle = NaN;
    
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
            CameraAngle = LeafAngleData{ind, 10};

            disp("Measuring leaf angle")
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
    AllData{ii, 2} = CameraAngle;
    AllData{ii, 3} = MedianLeaves;
    AllData{ii, 4} = MaxLeaves;
    AllData{ii, 5} = LeafAngle;
    AllData{ii, 6} = StalkHeight;
    AllData{ii, 7} = PanicleExsertion;

    
    %write AllData to .csv file in current working directory
    table = cell2table(AllData, 'VariableNames', {'fileName', 'cameraAngle', 'medianLeafCount', 'maxLeafCount', 'leafAngle', 'stalkHeight', 'panicleExsertion'});
    writetable(table, strcat(pwd, '/phenotypeData.csv'))
     
end
