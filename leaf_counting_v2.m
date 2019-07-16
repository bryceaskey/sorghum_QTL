%leaf_counting_v2
%leaf counting with skeleton method -> count skeleton enpoints

function [skeleton, endpoints, left_leaf_count, right_leaf_count] = leaf_counting_v2(all_plant, stake, stalk, panicle, stalk_line)

disp('Counting leaves')

%transform all_plant into binary of segmented_image
[height, width] = size(all_plant);

%if multiple blobs detected, need to be connected
conn_plant = logical((all_plant + stake) - panicle);

blobs = bwconncomp(conn_plant);
if blobs.NumObjects > 1
    [conn_plant] = connect_blobs(conn_plant);
end

skeleton = bwskel(logical((conn_plant)));

%fill holes smaller than specified area
skeleton = ~skeleton;
blobs = bwconncomp(skeleton, 4);
for ii = 1:1:blobs.NumObjects
    blob = blobs.PixelIdxList{ii};
    if length(blob) < 500
        skeleton(blob) = 0;
    end
end
skeleton = bwskel(~skeleton);
skeleton = bwareafilt(skeleton, 1);

changes_made = 1;
while changes_made > 0
    changes_made = 0;
    B = bwmorph(skeleton, 'branchpoints');
    E = bwmorph(skeleton, 'endpoints');
    [y,x] = find(E);
    B_loc = B;
    Dmask = false(size(skeleton));
    for k = 1:numel(x)
        D = bwdistgeodesic(skeleton,x(k),y(k));
        distanceToBranchPt = min(D(B_loc));
        if distanceToBranchPt < 30
            Dmask(D < distanceToBranchPt) = true;
            changes_made = changes_made + 1;
        end
    end
    skeleton = logical(skeleton - Dmask);
end

% if dist from skeleton endpoint to stalk or stake is less than 30 px, assume node
% with stalk -> don't include in leaf count
endpoints = bwmorph(skeleton, 'endpoints');
for row = 1:1:height
    for col = 1:1:width
        if endpoints(row, col) == 1
            point = [row, col];
            pixel = [row, col];
            radius = 1;
            while stalk(pixel(1), pixel(2)) ~= 1 && stake(pixel(1), pixel(2)) ~= 1 && radius <= 20
                ind = [];
                %test points outward from endpoint until skeleton is found
                test_square = []; %collect points at perimeter of square centered at endpoint
                for test_row = (point(1) - radius):1:(point(1) + radius)
                    for test_col = (point(2) - radius):1:(point(2) + radius)
                        if test_row >= 1 && test_row <= height && test_col >= 1 && test_col <= width
                            test_square = [test_square; test_row, test_col];
                        end
                    end
                end
                ind = rangesearch(test_square, point, radius);
                ind = ind{1}; %returns indicies of points in test_square
                for pixel_count = 1:1:length(ind)
                    pixel = test_square(ind(pixel_count), :);
                    if stalk(pixel(1), pixel(2)) == 1 || stake(pixel(1), pixel(2)) == 1         
                        break
                    end
                end
                radius = radius + 1;
            end
            dist = sqrt((pixel(1) - point(1)).^2 + (pixel(2) - point(2)).^2);
            if dist < 20
                endpoints(row, col) = 0;
            end
        end
    end
end

%separate leaf counts into left and right by determining position relative
%to stalk line
left_leaf_count = 0;
right_leaf_count = 0;
for row = 1:1:height
    stalk_col = stalk_line(1)*row^2 + stalk_line(2)*row + stalk_line(3);
    for col = 1:1:width
        if endpoints(row, col) == 1 && col <= stalk_col
            left_leaf_count = left_leaf_count + 1;
        elseif endpoints(row, col) == 1 && col > stalk_col
            right_leaf_count = right_leaf_count + 1;
        end
    end
end

fprintf("Left leaf count: %d\n", left_leaf_count)
fprintf("Right leaf count: %d\n", right_leaf_count)

end


% leaf_count_tip = sum(sum(bwmorph(skeleton, 'endpoints'))) - 2; %account for top and bottom of stalk
% imshow(skeleton);
% hold on;
% plot(panicle_base(2), panicle_base(1), 'r*');
% plot(stalk_bot(2), stalk_bot(1), 'r*');



