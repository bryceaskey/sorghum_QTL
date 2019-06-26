%stalk_segmentation

%start by identifying bottom of stalk
clc; clear; close all

[image, all_plant, stake, stake_bin] = stake_segmentation('Documents/MATLAB/RGB_test3.png');



[panicle_row, panicle_col] = panicle_identification(all_plant, image, stake, stake_bin);

[height, width] = size(all_plant);

pot = zeros(height, width);
for row = 1:1:height
    for col = 1:1:width
        if image(row, col, 1) < 10
            pot(row, col) = 1;
        end
    end
end

pot = imfill(pot);
pot = bwareaopen(pot, 300);

mean_pot = [];
for row = 1:1:height
    if sum(pot(row, :)) > 0
        pot_pixels = zeros(1, sum(pot(row, :)));
        pot_pixel_count = 0;
        for col = 1:1:width
            if pot(row, col) == 1
                pot_pixel_count = pot_pixel_count + 1;
                pot_pixels(pot_pixel_count) = col;
            end
        end
        mean_pot = [mean_pot; row, mean(pot_pixels)];
    end
end
pot_top = min(mean_pot(:, 1));
pot_mid = round(mean(mean_pot(:, 2)));

%starting at left side of pot, test points outward until plant is found
%test 100 left, and 100 right - width of pot
%calculate distance of each continuous region from pot_mid
plant_points = [];
cont = 0; %switch to keep track of continuity
region_count = 0;
point_count = 0;
for col = pot_mid - 100:1:pot_mid + 100
    if cont == 0 && all_plant(pot_top, col) == 1 %new region
        region_count = region_count + 1;
        point_count = point_count + 1;
        cont = 1;
        plant_points(region_count, point_count) = col;
    elseif cont == 1 && all_plant(pot_top, col) == 1 %current region
        point_count = point_count + 1;
        plant_points(region_count, point_count) = col;
    elseif cont == 1 && all_plant(pot_top, col) == 0 %region end
        cont = 0;
        point_count = 0;
    end
end

point_means = sum(plant_points, 2)./sum(plant_points ~= 0, 2);
stalk_start = [pot_top, round(min(point_means))];
panicle_end = [round(panicle_row), round(panicle_col)];

%smooth edges
changes_made = 1;
while changes_made ~= 0
    changes_made = 0;
    for row = 2:1:height - 1
        for col = 2:1:width - 1
            if all_plant(row, col) == 0
                if ((all_plant(row + 1, col) == 1) + (all_plant(row - 1, col) == 1) + (all_plant(row, col + 1) == 1) + (all_plant(row, col - 1) == 1)) >= 3
                    all_plant(row, col) = 1;
                    changes_made = changes_made + 1;
                end
            else
                if ((all_plant(row + 1, col) == 1) + (all_plant(row - 1, col) == 1) + (all_plant(row, col + 1) == 1) + (all_plant(row, col - 1) == 1)) <= 1
                    all_plant(row, col) = 0;
                    changes_made = changes_made + 1;
                end
            end
        end
    end
end

%delete floating pixels
all_plant = bwareaopen(all_plant, 300);
all_plant_skeleton = bwmorph(all_plant, 'skel', Inf);
%make sure selected panicle and starting stalk points are on skeleton
%if not, connect
if all_plant_skeleton(stalk_start(1), stalk_start(2)) == 0
    dist = 1; %test points outward from stalk_start until skeleton is found
    intersect = 0;
    while intersect == 0
        test_points = zeros(8, 2);
        test_points(1, :) = [stalk_start(1) - dist, stalk_start(2) - dist];
        test_points(2, :) = [stalk_start(1) - dist, stalk_start(2)];
        test_points(3, :) = [stalk_start(1) - dist, stalk_start(2) + dist];
        test_points(4, :) = [stalk_start(1), stalk_start(2) + dist];
        test_points(5, :) = [stalk_start(1) + dist, stalk_start(2) + dist];
        test_points(6, :) = [stalk_start(1) + dist, stalk_start(2)];
        test_points(7, :) = [stalk_start(1) + dist, stalk_start(2) - dist];
        test_points(8, :) = [stalk_start(1), stalk_start(2) - dist];
        for test_point_count = 1:1:8
            test_pixel = test_points(test_point_count, :);
            if all_plant_skeleton(test_pixel(1), test_pixel(2)) == 1
                intersect = 1;
                closest_stalk = [test_pixel(1), test_pixel(2)];
                break
            end
        end
        dist = dist + 1;
    end
    [all_plant_skeleton] = draw_line(all_plant_skeleton, stalk_start, closest_stalk, 1);
end

if all_plant_skeleton(panicle_end(1), panicle_end(2)) == 0
    dist = 1; %test points outward from stalk_start until skeleton is found
    intersect = 0;
    while intersect == 0
        test_points = zeros(8, 2);
        test_points(1, :) = [panicle_end(1) - dist, panicle_end(2) - dist];
        test_points(2, :) = [panicle_end(1) - dist, panicle_end(2)];
        test_points(3, :) = [panicle_end(1) - dist, panicle_end(2) + dist];
        test_points(4, :) = [panicle_end(1), panicle_end(2) + dist];
        test_points(5, :) = [panicle_end(1) + dist, panicle_end(2) + dist];
        test_points(6, :) = [panicle_end(1) + dist, panicle_end(2)];
        test_points(7, :) = [panicle_end(1) + dist, panicle_end(2) - dist];
        test_points(8, :) = [panicle_end(1), panicle_end(2) - dist];
        for test_point_count = 1:1:8
            test_pixel = test_points(test_point_count, :);
            if all_plant_skeleton(test_pixel(1), test_pixel(2)) == 1
                intersect = 1;
                closest_stalk = [test_pixel(1), test_pixel(2)];
                break
            end
        end
        dist = dist + 1;
    end
    [all_plant_skeleton] = draw_line(all_plant_skeleton, [panicle_end(1), panicle_end(2)], closest_stalk, 1);
end

%get info about all blobs in plant if plant sections aren't connected
blob_info = bwconncomp(all_plant);
while blob_info.NumObjects > 1 %plant regions are disconnected - loop until all regions are connected
    blobs = []; %indices for each blob are stored in a separate column
    disp('Plant is segmented')
    for blob_count = 1:1:blob_info.NumObjects
        for pixel_count = 1:1:length(blob_info.PixelIdxList{blob_count})
            blobs(pixel_count, blob_count) = blob_info.PixelIdxList{blob_count}(pixel_count);
        end
    end
    
    blobs(blobs == 0) = NaN;
    
    %sort blobs according to size - blob with largest # of pixels should be
    %in 1st column; blob with least should be in leftmost column
    blobs_sorted = zeros(size(blobs));
    for col = 1:1:blob_info.NumObjects
        [~, max_ind] = max(sum(~isnan(blobs(:, :)))); %max_ind = column containing largest blob
        blobs_sorted(:, col) = blobs(:, max_ind);
        blobs(:, max_ind) = [];
    end
    
    blob_outlines = []; %only need to test outline pixels - each page contains outline coordinates for 1 blob
    for blob_count = 1:1:blob_info.NumObjects
        [row_start, col_start] = ind2sub([height, width], blobs_sorted(1, blob_count));
        outline_coordinates = bwtraceboundary(all_plant, [row_start, col_start], 'W');
        [pixel_count, ~] = size(outline_coordinates);
        for pixel = 1:1:pixel_count
            blob_outlines(pixel, 1, blob_count) = outline_coordinates(pixel, 1);
            blob_outlines(pixel, 2, blob_count) = outline_coordinates(pixel, 2);
        end
    end
    blob_outlines(blob_outlines == 0) = NaN;
    
    [pixel_count_A, ~, ~] = size(blob_outlines(:, :, 1));
    blob_A = blob_outlines(:, :, 1);
    min_distances = zeros(blob_info.NumObjects - 1, 5); %1st column stores distance information
    %2nd and 3rd columns store row and col coordinates for blob A
    %4th and 5th columns store row and col coordinates for blob B
    for blob_count = 2:1:blob_info.NumObjects
        blob_B = blob_outlines(:, :, blob_count);
        [pixel_count_B, ~] = size(blob_B);
        single_blob_distances = zeros(pixel_count_A*pixel_count_B, 5);
        total_pixel_count = 0;
        for pixel_A = 1:1:pixel_count_A
            row_A = blob_A(pixel_A, 1);
            col_A = blob_A(pixel_A, 2);
            for pixel_B = 1:1:pixel_count_B
                row_B = blob_B(pixel_B, 1);
                col_B = blob_B(pixel_B, 2);
                dist = sqrt((row_A - row_B).^2 + (col_A - col_B).^2);
                total_pixel_count = total_pixel_count + 1;
                single_blob_distances(total_pixel_count, 1) = dist;
                single_blob_distances(total_pixel_count, 2) = row_A;
                single_blob_distances(total_pixel_count, 3) = col_A;
                single_blob_distances(total_pixel_count, 4) = row_B;
                single_blob_distances(total_pixel_count, 5) = col_B;
            end
        end
        minimum = min(single_blob_distances(:, 1));
        [min_row, ~] = find(single_blob_distances(:, 1) == minimum);
        while length(min_row) > 1 %if multiple minima are found, only select 1
            min_row(end, :) = [];
        end
        min_distances(blob_count - 1, 1:5) = single_blob_distances(min_row, 1:5);
    end
    
    %connect points with line
    point1 = [min_distances(1, 2), min_distances(1, 3)];
    point2 = [min_distances(1, 4), min_distances(1, 5)];  
    [all_plant] = draw_line(all_plant, point1, point2, 5);
    blob_info = bwconncomp(all_plant);
end

%reskeleton plant - line connecting stalk_mid/panicle to original skeleton
%is thicker than 1 px
all_plant_skeleton = bwmorph(all_plant_skeleton, 'skel', Inf);

%trace on skeleton to find shortest distance from bottom of stalk to
%panicle
pixel = stalk_start;

explored = [];
%array to store all coordinates explored
%1st two columns contain position coordinates
%3rd and 4th columns contains position coordinates for previous pixel - when panicle is found,
%backtrack through array to get shortest path
while isequal(pixel, panicle_end) == 0
    [connections] = get_neighbors(all_plant_skeleton, pixel);
    for row = 1:1:length(connections(:, 1))
        explored = [explored; connections(row, 1), connections(row, 2), pixel(1), pixel(2)]
    end
    break
end



imshow(all_plant_skeleton);
hold on
plot(stalk_start(2), stalk_start(1), 'r*', 'MarkerSize', 10)
plot(panicle_end(2), panicle_end(1), 'r*', 'MarkerSize', 10)