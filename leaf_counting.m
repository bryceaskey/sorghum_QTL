%cleans up floating leaf pixels, and counts leaves on plant

function [segmented_image, left_leaf_count, right_leaf_count] = leaf_counting(segmented_image, test_line_count, shape_coeffs, width_coeffs, cutoff)
[height, width, ~] = size(segmented_image);

%binary image
leaves = zeros(height, width);

for row = 1:1:cutoff
    for col = 1:1:width
        if segmented_image(row, col, 1) == 0 %leaves
            leaves(row, col) = 1;
        end
    end
end

%remove floating pixels
leaves = bwareaopen(leaves, 40);

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
x = leaf_top:1:leaf_bot;
if length(shape_coeffs) == 2
    y1 = shape_coeffs(1)*x + shape_coeffs(2);
else
    y1 = shape_coeffs(1)*x.^2 + shape_coeffs(2)*x + shape_coeffs(3);
end

%line describing variation of stalk width along length of stalk
if length(width_coeffs) == 2
    y2 = width_coeffs(1)*x + width_coeffs(2);
elseif length(width_coeffs) == 3
    y2 = width_coeffs(1)*x.^2 + width_coeffs(2)*x + width_coeffs(3);
else
    y2 = width_coeffs(1)*x.^3 + width_coeffs(2)*x.^2 + width_coeffs(3)*x + width_coeffs(4);
end

left = y1 - (y2/2);
right = y1 + (y2/2);

%leaf counting - draw lines parallel to stem
%count number of times a leaf is intersected by line
% leaf_count = cell(2, 4);
% leaf_count(1, 1:4) = {'mean', 'median', 'mode', 'max'};

%leaf counting left side
switch_count = zeros(1, test_line_count);
for dist = 1:1:test_line_count %test line_count lines out from left edge of stem
    line = left - dist;
    count = 0;
    prev = 0;
    for row = leaf_top:1:leaf_bot %along entire length of line
        pixel = [row, round(line(row - leaf_top + 1))];
        if leaves(pixel(1), pixel(2)) ~= prev
            count = count + 1;
        end
        prev = leaves(pixel(1), pixel(2));
    end
    switch_count(1, dist) = count;
end
left_leaf_count = round(mean(switch_count/2));
% median_leaf_count = round(median(switch_count/2));
% mode_leaf_count = round(mode(switch_count/2));
% max_leaf_count = round(max(switch_count/2));

%leaf counting right side
switch_count = zeros(1, test_line_count);
for dist = 1:1:test_line_count %test line_count lines out from right edge of stem
    line = right + dist;
    count = 0;
    prev = 0;
    for row = leaf_top:1:leaf_bot %along entire length of line
        pixel = [row, round(line(row - leaf_top + 1))];
        if leaves(pixel(1), pixel(2)) ~= prev
            count = count + 1;
        end
        prev = leaves(pixel(1), pixel(2));
    end
    switch_count(1, dist) = count;
end
right_leaf_count = round(mean(switch_count/2));
% median_leaf_count = median_leaf_count + round(median(switch_count/2));
% mode_leaf_count = mode_leaf_count + round(mode(switch_count/2));
% max_leaf_count = max_leaf_count + round(max(switch_count/2));

% leaf_count(2, 1) = {mean_leaf_count};
% leaf_count(2, 2) = {median_leaf_count};
% leaf_count(2, 3) = {mode_leaf_count};
% leaf_count(2, 4) = {max_leaf_count};

% hold on
% plot(y1, x, 'r', 'LineWidth', 1)
% plot(left, x, 'b', 'LineWidth', 1)
% plot(right, x, 'b', 'LineWidth', 1)

%reintegrate corrected leaf areas into total segmented image
for row = 1:1:height
    for col = 1:1:width
        if segmented_image(row, col, 1) == 0 && leaves(row, col) ~= 1
            segmented_image(row, col, :) = 255; %change to background
        elseif segmented_image(row, col, 1) ~= 0 && leaves(row, col) == 1
            segmented_image(row, col, 1) = 0; %change to stalk
            segmented_image(row, col, 2) = 147;
            segmented_image(row, col, 3) = 0;       
        end
    end
end

end