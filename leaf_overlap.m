%leaf overlap
%determine degree of leaf overlap in segmented image
%if serious overlap detected, no need for further processing
%takes output segmented image of stalk_cleanup.m
function [overlap] =  leaf_overlap(segmented_image, shape_coeffs, width_coeffs, cutoff)

[height, width, ~] = size(segmented_image);

test_line_count = 20;

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

%draw lines parallel to stalk / outer edge of stalk
%count # of leaves detected as in leaf_counting.m
%if number of leaf areas varies greatly with distance from stalk, assume
%high degree of overlap

%leaf overlap left side
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
left_overlap = std(switch_count);

%leaf overlap right side
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
right_overlap = std(switch_count);

if left_overlap >= 1.5 || right_overlap >= 1.5
    overlap = 1; %large amount of overlap
else
    overlap = 0; %small amount of overlap
end

end