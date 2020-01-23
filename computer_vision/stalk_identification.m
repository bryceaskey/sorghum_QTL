%stalk_segmentation_v2 - Dijkstra's shortest path algorithim
function [all_plant, stalk_line, stalk_bot, panicle_base] = stalk_identification(all_plant, image, panicle_row, panicle_col, circle_rows, circle_cols);
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
pot = bwareafilt(pot, 1);

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

%starting at center of pot, test points outward until plant is found
%test 100 left, and 100 right - width of pot
%calculate distance of each continuous region from pot_mid
plant_points = [];
cont = 0; %switch to keep track of continuity
region_count = 0;
pixel_count = 0;
dist = 0; %start searching up rows if no stalk is found at pot_top
while isempty(plant_points)
    for col = pot_mid - 100:1:pot_mid + 100
        if cont == 0 && all_plant(pot_top - dist, col) == 1 %new region
            region_count = region_count + 1;
            pixel_count = pixel_count + 1;
            cont = 1;
            plant_points(region_count, pixel_count) = col;
        elseif cont == 1 && all_plant(pot_top - dist, col) == 1 %current region
            pixel_count = pixel_count + 1;
            plant_points(region_count, pixel_count) = col;
        elseif cont == 1 && all_plant(pot_top - dist, col) == 0 %region end
            cont = 0;
            pixel_count = 0;
        end
    end
    dist = dist + 1;
end

point_means(:, 1) = sum(plant_points, 2)./sum(plant_points ~= 0, 2);
point_means(:, 2) = abs(pot_mid - point_means(:, 1));
min_ind = point_means(:, 2) == min(point_means(:, 2));
min_col = round(point_means(min_ind, 1));
stalk_bot = [pot_top, min_col(1)];
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

%delete all pixels in contact with border of image
all_plant(1, :) = 0;
all_plant(height, :) = 0;
all_plant(:, 1) = 0;
all_plant(:, width) = 0;

median_plant = zeros(height, width);
for row = 1:1:height
    median_row = [];
    if sum(all_plant(row, :) == 1) > 0 %row contains plant pixels
        cont = 0;
        region_count = 0;
        point_count = 0;
        for col = 1:1:width
            if all_plant(row, col) == 1 && cont == 0 %new region found
                cont = 1;
                region_count = region_count + 1;
                point_count = point_count + 1;
                median_row(region_count, point_count) = col; %start new row in array for each new region
            elseif all_plant(row, col) == 1 && cont == 1
                point_count = point_count + 1;
                median_row(region_count, point_count) = col; %current region - add to same row in array
            elseif all_plant(row, col) == 0 && cont == 1 %region ends
                cont = 0;
                point_count = 0;
            end
        end
        for region = 1:1:length(median_row(:, 1))
            coordinates = median_row(region, median_row(region, :) ~= 0);
            coordinates(coordinates == 0) = [];
            median_plant(row, round(median(coordinates))) = 1;           
        end
    end
end

radius = 1;
pixel = stalk_bot;
while median_plant(pixel(1), pixel(2)) ~= 1 && radius < 50
    %test points outward from endpoint until skeleton is found
    test_square = []; %collect points at perimeter of square centered at endpoint
    for test_row = (stalk_bot(1) - radius):1:(stalk_bot(1) + radius)
        for test_col = (stalk_bot(2) - radius):1:(stalk_bot(2) + radius)
            if test_row >= 1 && test_row <= height && test_col >= 1 && test_col <= width
                test_square = [test_square; test_row, test_col];
            end
        end
    end
    ind = rangesearch(test_square, [stalk_bot(1), stalk_bot(2)], radius);
    ind = ind{1}; %returns indicies of points in test_square
    for pixel_count = 1:1:length(ind)
        pixel = test_square(ind(pixel_count), :);
        if median_plant(pixel(1), pixel(2)) == 1            
            break
        end
    end
    radius = radius + 1;
end

if median_plant(pixel(1), pixel(2)) == 1
    dist = sqrt((stalk_bot(1) - pixel(1)).^2 + (stalk_bot(2) - pixel(2)).^2);
    num_points = dist/0.4;
    x_line = linspace(stalk_bot(2), pixel(2), num_points);
    y_line = linspace(stalk_bot(1), pixel(1), num_points);
    rows = round(y_line);
    cols = round(x_line);
    for k = 1:1:length(x_line)
        median_plant(rows(k), cols(k)) = 1;
    end
end

%test points outward from panicle_end until skeleton is found
radius = 1;
pixel = panicle_end;
while median_plant(pixel(1), pixel(2)) ~= 1 && radius < 50
    %test points outward from endpoint until skeleton is found
    test_square = []; %collect points at perimeter of square centered at endpoint
    for test_row = (panicle_end(1) - radius):1:(panicle_end(1) + radius)
        for test_col = (panicle_end(2) - radius):1:(panicle_end(2) + radius)
            if test_row >= 1 && test_row <= height && test_col >= 1 && test_col <= width
                test_square = [test_square; test_row, test_col];
            end
        end
    end
    ind = rangesearch(test_square, [panicle_end(1), panicle_end(2)], radius);
    ind = ind{1}; %returns indicies of points in test_square
    for pixel_count = 1:1:length(ind)
        pixel = test_square(ind(pixel_count), :);
        if median_plant(pixel(1), pixel(2)) == 1            
            break
        end
    end
    radius = radius + 1;
end

if median_plant(pixel(1), pixel(2)) == 1
    dist = sqrt((panicle_end(1) - pixel(1)).^2 + (panicle_end(2) - pixel(2)).^2);
    num_points = dist/0.4;
    x_line = linspace(panicle_end(2), pixel(2), num_points);
    y_line = linspace(panicle_end(1), pixel(1), num_points);
    rows = round(y_line);
    cols = round(x_line);
    for k = 1:1:length(x_line)
        median_plant(rows(k), cols(k)) = 1;
    end
end

if median_plant(stalk_bot(1), stalk_bot(2)) == 1 && median_plant(panicle_end(1), panicle_end(2)) == 1
    %create array of nodes - each plant pixel in all_plant
    %first column stores pixel index - used to ID pixel
    %second column stores x position(column index)
    %third column stores y position(row index)
    plant_points = sum(sum(median_plant));
    pixel_count = 0;
    nodes = zeros(plant_points, 3);
    for row = 1:1:height
        for col = 1:1:width
            if median_plant(row, col) == 1
                pixel_count = pixel_count + 1;
                pixel_id = sub2ind([height, width], row, col);
                nodes(pixel_count, 1) = pixel_id;
                nodes(pixel_count, 2) = col;
                nodes(pixel_count, 3) = row;
            end
        end
    end

    %create array of segments
    %each pixel has n # of segments connecting it to any directly adjacent pixels
    %if no pixels are directly adjacent, search all columns in row
    segments = [];
    segment_id = 0;
    for row = 1:1:plant_points
        pixel1_id = nodes(row, 1);
        pixel_row = nodes(row, 3);
        pixel_col = nodes(row, 2);
        [neighbors] = get_neighbors(median_plant, [pixel_row, pixel_col]);

        if ~isempty(neighbors)
            %only consider neighbors in row below current row
            neighbors(neighbors(:, 1) <= pixel_row, :) = [];

            if ~isempty(neighbors)
                for nb = 1:1:length(neighbors(:, 1))
                    segment_id = segment_id + 1;
                    pixel2_id = sub2ind([height, width], neighbors(nb, 1), neighbors(nb, 2));
                    segments = [segments; segment_id, pixel1_id, pixel2_id];
                end
            else
                %search all columns in row directly below
                %if pixel not found, then iterate down rows
                row_dist = 0;
                while pixel_row + row_dist < height
                    neighbors = [];
                    row_dist = row_dist + 1;
                    neighbors = find(median_plant(pixel_row + row_dist, :) == 1);
                    if ~isempty(neighbors)
                        for nb = 1:1:length(neighbors)
                            segment_id = segment_id + 1;
                            pixel2_id = sub2ind([height, width], pixel_row + row_dist, neighbors(nb));
                            segments = [segments; segment_id, pixel1_id, pixel2_id];
                        end
                        break
                    end
                end    
            end
        else
            %search all columns in row directly below
            %if pixel not found, then iterate down rows
            row_dist = 0;
            while pixel_row + row_dist < height
                neighbors = [];
                row_dist = row_dist + 1;
                neighbors = find(median_plant(pixel_row + row_dist, :) == 1);
                if ~isempty(neighbors)
                    for nb = 1:1:length(neighbors)
                        segment_id = segment_id + 1;
                        pixel2_id = sub2ind([height, width], pixel_row + row_dist, neighbors(nb));
                        segments = [segments; segment_id, pixel1_id, pixel2_id];
                    end
                    break
                end
            end
        end
    end

    % for row = 1:1:length(segments(:, 1))
    %     [sr, sc] = ind2sub([height, width], segments(row, 2));
    %     [fr, fc] = ind2sub([height, width], segments(row, 3));
    %     imshow(median_plant); hold on;
    %     plot(sc, sr, 'r*')
    %     plot(fc, fr, 'g*')
    %     hold off;
    % end

    start_ID = sub2ind([height, width], stalk_bot(1), stalk_bot(2));
    fin_ID = sub2ind([height, width], panicle_end(1), panicle_end(2));

    [~, path] = dijkstra(nodes, segments, start_ID, fin_ID);

    path_coordinates = zeros(length(path), 2);
    for pixel = 1:1:length(path)
        [row_sub, col_sub] = ind2sub([height, width], path(pixel));
        path_coordinates(pixel, 1:2) = [row_sub, col_sub];
    end

    stalk_line = polyfit(path_coordinates(:, 1), path_coordinates(:, 2), 2);

    %find where stalk line intersects with bottom of panicle circle
    x = panicle_end(1):1:stalk_bot(1); %row coordinates
    y = stalk_line(1)*x.^2 + stalk_line(2)*x + stalk_line(3); %col coordinates

    line_points = [round(x); round(y)];
    panicle_base = NaN;
    for line_point_count = length(line_points(1, :)):-1:1 %test points starting from bottom of stalk
        line_point = [round(line_points(1, line_point_count)), round(line_points(2, line_point_count))];
        for circle_point_count = 1:1:length(circle_rows)
            circle_point = [round(circle_rows(circle_point_count)), round(circle_cols(circle_point_count))];
            if isequal(line_point, circle_point) == 1
                panicle_base = line_point;
                break
            end
        end
    end
else
    panicle_base = NaN;
    stalk_bot = NaN;
end

%redefine range of x - stalk only reaches base of panicle and slightly
%below bottom pot cutoff - find points within certain distance of
%stalk_line
if ~isnan(panicle_base) & ~isnan(stalk_bot)
    stalk_start = [];
    for row = height:-1:stalk_bot(1)
        line_col = stalk_line(1)*row.^2 + stalk_line(2)*row + stalk_line(3);
        for col = 1:1:width
            if median_plant(row, col) == 1 && abs(col - line_col) < 25
                stalk_start = [row, col];
                break
            end
        end
        if ~isempty(stalk_start)
            break
        end
    end
    
    if ~isempty(stalk_start)
        x = panicle_base(1):1:stalk_start(1);
        path_coordinates = path_coordinates(path_coordinates(:, 1) >= panicle_base(1), :);
        stalk_line = polyfit(path_coordinates(:, 1), path_coordinates(:, 2), 2);
        y = stalk_line(1)*x.^2 + stalk_line(2)*x + stalk_line(3);
    else
        stalk_line = NaN;
        stalk_start = NaN;
        panicle_base = NaN;
    end
    
else
    stalk_line = NaN;
    stalk_start = NaN;
    panicle_base = NaN;
end

stalk_bot = stalk_start;
end