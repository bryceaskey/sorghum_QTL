%right leaf angle
%fits lines to leaves on left side of plant
%finds points of intersection between leaf lines and stalk line
%calculates angle between lines at intersection

function [right_angle_data, right_rearranged, right_coefficients] = right_leaf_angle(segmented_image, right_leaf_count, test_lines, shape_coeffs, width_coeffs)

[height, width, ~] = size(segmented_image);

%binary image
leaves = zeros(height, width);
for row = 1:1:height
    for col = 1:1:width
        if segmented_image(row, col, 1) == 0 %leaves
            leaves(row, col) = 1;
        end
    end
end

%determine upper and lower limits for line - bottommost and topmost leaf surfaces
leaf_rows = [];
for row = 1:1:height
    if sum(leaves(row, :) == 1) > 0
        leaf_rows = [leaf_rows, row];
    end
end
leaf_top = min(leaf_rows);
leaf_bot = max(leaf_rows);

%line through center of stem
ii = leaf_top:1:leaf_bot;
if length(shape_coeffs) == 2
    y1 = shape_coeffs(1)*ii + shape_coeffs(2);
else
    y1 = shape_coeffs(1)*ii.^2 + shape_coeffs(2)*ii + shape_coeffs(3);
end

%line describing variation of stalk width along length of stalk
if length(width_coeffs) == 2
    y2 = width_coeffs(1)*ii + width_coeffs(2);
elseif length(width_coeffs) == 3
    y2 = width_coeffs(1)*ii.^2 + width_coeffs(2)*ii + width_coeffs(3);
else
    y2 = width_coeffs(1)*ii.^3 + width_coeffs(2)*ii.^2 + width_coeffs(3)*ii + width_coeffs(4);
end

right = y1; % + (y2/2);

right_leaf_data = {}; %each row contains intersect data for 1 line
for dist = 1:1:test_lines %test test_lines out from left edge of stem
    line = right + dist;
    leaf_data = [];
    leaf_bin = 0;
    count = 0;
    for row = leaf_top:1:leaf_bot
        col = round(line(row - leaf_top + 1));
        pixel = [row, col];
        if leaves(pixel(1), pixel(2)) == 1 && leaf_bin == 0 %new leaf - start new array
            leaf_data = [pixel];
            leaf_bin = 1;
            count = count + 1;
        elseif leaves(pixel(1), pixel(2)) == 1 && leaf_bin == 1  %current leaf - add current array
            leaf_data = [leaf_data; pixel];
        elseif leaves(pixel(1), pixel(2)) == 0 && leaf_bin == 1 %end of current leaf - save array to cell
            right_leaf_data(dist, count) = {leaf_data};
            leaf_bin = 0;
        else
            leaf_bin = 0;
        end
    end
end

[line_count, leaf_count] = size(right_leaf_data);

%create matrix containing mean position values from right_leaf_data
mean_coordinates = zeros(line_count, leaf_count, 2); %3d - 1st layer contains row coordinates, 2nd layer contains col coordinates
for row = 1:1:line_count
    for col = 1:1:leaf_count
        if isempty(right_leaf_data{row, col}) == 0
            points = right_leaf_data{row, col};
            mean_coordinates(row, col, 1) = mean(points(:, 1));
            mean_coordinates(row, col, 2) = mean(points(:, 2));
        end
    end
end

%matrix to contain sorted coordinates
right_rearranged = zeros(line_count, leaf_count, 2);

%find largest set of coordinates, and insert into rearranged
for row = 1:1:line_count
    if sum(mean_coordinates(row, :, 1) == 0) == 0
        right_rearranged(row, :, :) = mean_coordinates(row, :, :);
        break
    end
end
start = row;

%work up and down from largest row in rearranged, matching coordinates
%based on smalled geometric distance between pixels

if start ~= 1 %starting row is not top row - need to iterate up matrix
    for row = start - 1:-1:1
        next_num_points = sum(mean_coordinates(row, :, 1) ~= 0);
        prev_num_points = leaf_count;
        geo_dist = zeros(next_num_points, prev_num_points); %matrix to store geometric distances
        %each column represents data for a point in the previous row
        %each row represents data for a point in the current row
        for ii = 1:1:next_num_points
            for jj = 1:1:prev_num_points
                row_count = 0;
                if isnan(right_rearranged(row + 1, jj, 1)) && isnan(right_rearranged(row + 1, jj, 2)) %cycle down rows in a col until a cell ~= NaN is found
                    while isnan(right_rearranged(row + 1 + row_count, jj, 1)) && isnan(right_rearranged(row + 1 + row_count, jj, 2))
                        row_count = row_count + 1;
                    end
                end
                x1 = right_rearranged(row + 1 + row_count, jj, 1);
                y1 = right_rearranged(row + 1 + row_count, jj, 2);
                x2 = mean_coordinates(row, ii, 1);
                y2 = mean_coordinates(row, ii, 2);
                geo_dist(ii, jj) = sqrt((x1 - x2).^2 + (y1 - y2).^2);
            end
        end
        for points = 1:1:next_num_points
            val = min(geo_dist, [], [1 2], 'omitnan');
            [previous_ind, current_ind] = find(val == geo_dist);
            right_rearranged(row, current_ind, 1) = mean_coordinates(row, previous_ind, 1);
            right_rearranged(row, current_ind, 2) = mean_coordinates(row, previous_ind, 2);
            geo_dist(previous_ind, :) = NaN;
            geo_dist(:, current_ind) = NaN;
        end
        for col = 1:1:leaf_count
            if right_rearranged(row, col, 1) == 0 && right_rearranged(row, col, 2) == 0 %missing point - fill with NaN
                right_rearranged(row, col ,1) = NaN;
                right_rearranged(row, col, 2) = NaN;
            end
        end
    end
end

if start ~= line_count %starting row is not bottom row - need to iterate down matrix
     for row = start + 1:1:line_count
        next_num_points = sum(mean_coordinates(row, :, 1) ~= 0);
        prev_num_points = leaf_count;
        geo_dist = zeros(next_num_points, prev_num_points); %matrix to store geometric distances
        %each column represents data for a point in the previous row
        %each row represents data for a point in the current row
        for ii = 1:1:next_num_points
            for jj = 1:1:prev_num_points
                row_count = 0;
                if isnan(right_rearranged(row - 1, jj, 1)) && isnan(right_rearranged(row - 1, jj, 2)) %cycle up rows in a col until a cell ~= NaN is found
                    while isnan(right_rearranged(row - 1 - row_count, jj, 1)) && isnan(right_rearranged(row - 1 - row_count, jj, 2))
                        row_count = row_count + 1;
                    end
                end
                x1 = right_rearranged(row - 1 - row_count, jj, 1);
                y1 = right_rearranged(row - 1 - row_count, jj, 2);
                x2 = mean_coordinates(row, ii, 1);
                y2 = mean_coordinates(row, ii, 2);
                geo_dist(ii, jj) = sqrt((x1 - x2).^2 + (y1 - y2).^2);
            end
        end
        for points = 1:1:next_num_points
            val = min(geo_dist, [], [1 2], 'omitnan');
            [previous_ind, current_ind] = find(val == geo_dist);
            right_rearranged(row, current_ind, 1) = mean_coordinates(row, previous_ind, 1);
            right_rearranged(row, current_ind, 2) = mean_coordinates(row, previous_ind, 2);
            geo_dist(previous_ind, :) = NaN;
            geo_dist(:, current_ind) = NaN;
            
        end
        for col = 1:1:leaf_count
            if right_rearranged(row, col, 1) == 0 && right_rearranged(row, col, 2) == 0 %missing point - fill with NaN
                right_rearranged(row, col ,1) = NaN;
                right_rearranged(row, col, 2) = NaN;
            end
        end
    end
end

%remove outliers from line data
for col = 1:1:leaf_count
    [~, row_outliers] = rmoutliers(right_rearranged(:, col, 1));
    [~, col_outliers] = rmoutliers(right_rearranged(:, col, 2));
    for row = 1:1:line_count
        if row_outliers(row) == 1 || col_outliers(col) == 1
            right_rearranged(row, col, :) = NaN;
        end
    end
end

height_range = 1:1:height;
if length(shape_coeffs) == 3
    stalk_y = shape_coeffs(1)*height_range.^2 + shape_coeffs(2)*height_range + shape_coeffs(3);
else
    stalk_y = shape_coeffs(1)*height_range + shape_coeffs(2);
end

plot(stalk_y, height_range, 'LineWidth', 1)

right_coefficients = zeros(leaf_count, 4); %each row contains data for a line
%first column contains number of points in line
%second column contains r^2 for line
%third and fourth column contain coefficients for line
for col = 1:1:leaf_count %need to create new array without NaN values
    point_count = sum(~isnan(right_rearranged(:, col, 1)));
    line_points = [];
    valid_point_count = 0;
    for row = 1:1:line_count %cycle through each row of rearranged, skipping NaN cells
        if ~isnan(right_rearranged(row, col, 1))
            valid_point_count = valid_point_count + 1;
            line_points(valid_point_count, 1) = right_rearranged(row, col, 1);
            line_points(valid_point_count, 2) = right_rearranged(row, col, 2);
        end
    end
    if ~isempty(line_points)
        r_squared = (corr(line_points(:, 1), line_points(:, 2))).^2;
        right_coefficients(col, 1) = valid_point_count;
        right_coefficients(col, 2) = r_squared;
        line = polyfit(line_points(:, 1), line_points(:, 2), 1);
        right_coefficients(col, 3) = line(1);
        right_coefficients(col, 4) = line(2);
    end
end

%ignore lines that don't contain >= 1/4 of total lines tested
valid_lines = [];
valid_line_count = 0;
for row = leaf_count:-1:1
    if right_coefficients(row, 1) >= test_lines/4
        valid_line_count = valid_line_count + 1;
        valid_lines(valid_line_count, :) = right_coefficients(row, :);
    end
end

%sort lines from largest to smalled r^2 value
valid_lines = sortrows(valid_lines, 2, 'descend');

right_angle_data = []; %contains intersection coordinates, and angle between leaf and stalk lines

for line_count = 1:1:right_leaf_count %select lines with greatest r^2 value until number of lines matches left_leaf_count
    x = 1:1:height;
    y = valid_lines(line_count, 3)*x + valid_lines(line_count, 4);
    hold on
    plot(y, x, 'LineWidth', 1)
    intersection = InterX([height_range; stalk_y], [x; y]);
    %calculate slope of both lines at intersection point
    stalk_der = polyder(shape_coeffs);
    if length(stalk_der) == 2 %originally quadratic
        stalk_slope = stalk_der(1)*intersection(1) + stalk_der(2);
    else %originally linear
        stalk_slope = stalk_der(1);
    end
    leaf_slope = polyder([valid_lines(line_count, 3), valid_lines(line_count, 4)]);
    angle = atand((stalk_slope - leaf_slope)/(1 + stalk_slope*leaf_slope));
    right_angle_data = [right_angle_data; intersection(1), intersection(2), angle];
end

end