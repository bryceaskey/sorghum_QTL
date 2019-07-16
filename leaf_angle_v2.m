%leaf_angle_v2
%use skeleton method to determine average angle leaves make with stalk
%starting at endpoints identified in leaf_counting_v2, trace back on
%skeleton to find smoothest path to stalk
%fit line to skeleton points
function [average_angle] = leaf_angle_v2(all_plant, skeleton, stalk, stalk_line, stake, endpoints)

disp('Measuring average leaf angle')

[height, width] = size(all_plant);

% if stake_bin == 1
%     skeleton = bwskel(logical((all_plant + stake)));
% else
%     skeleton = bwskel(all_plant);
% end
% 
% skeleton = ~skeleton;
% blobs = bwconncomp(skeleton, 4);
% for ii = 1:1:blobs.NumObjects
%     blob = blobs.PixelIdxList{ii};
%     if length(blob) < 500
%         skeleton(blob) = 0;
%     end
% end
% skeleton = bwskel(~skeleton);
% 
% B = bwmorph(skeleton, 'branchpoints');
% E = bwmorph(skeleton, 'endpoints');
% [y,x] = find(E);
% B_loc = B;
% Dmask = false(size(skeleton));
% for k = 1:numel(x)
%     D = bwdistgeodesic(skeleton,x(k),y(k));
%     distanceToBranchPt = min(D(B_loc));
%     if distanceToBranchPt < 40
%         Dmask(D < distanceToBranchPt) = true;
%     end
% end
% skeleton = logical(skeleton - Dmask);

%create array of nodes - each plant pixel in skeleton
%first column stores pixel index - used to ID pixel
%second column stores x position(column index)
%third column stores y position(row index)
skeleton_nodes = sum(sum(skeleton(:, :) == 1));
pixel_count = 0;
nodes = zeros(skeleton_nodes, 3);
for row = 1:1:height
    for col = 1:1:width
        if skeleton(row, col) == 1
            pixel_count = pixel_count + 1;
            pixel_id = sub2ind([height, width], row, col);
            nodes(pixel_count, 1) = pixel_id;
            nodes(pixel_count, 2) = col;
            nodes(pixel_count, 3) = row;
        end
    end
end

%array of segments connecting each adjacent pixel
segments = [];
segment_id = 0;
for row = 1:1:skeleton_nodes
    pixel1_id = nodes(row, 1);
    pixel1 = [nodes(row, 3), nodes(row, 2)];
    [neighbors] = get_neighbors(skeleton, pixel1);
    for ii = 1:1:length(neighbors(:, 1))
        if skeleton(neighbors(ii, 1), neighbors(ii, 2)) == 1
            segment_id = segment_id + 1;
            pixel2_id = sub2ind([height, width], neighbors(ii, 1), neighbors(ii, 2));
            segments = [segments; segment_id, pixel1_id, pixel2_id];
        end
    end
end

%simplify endpoint, stalk, and stake arrays to lists of points
leaf_tips = [];
stalk_list = [];
stake_list = [];
for row = 1:1:height
    for col = 1:1:width
        if endpoints(row, col) == 1 %separate if statements because some pixels could be members of both groups
            leaf_tips = [leaf_tips; row, col];
        end
        if stake(row, col) == 1
            stake_list = [stake_list; row, col];
        end
        if stalk(row, col) == 1
            stalk_list = [stalk_list; row, col];
        end
    end
end

%to avoid errors with ismember()
if isempty(stake_list)
    stake_list = [NaN, NaN];
end

% left_paths = cell(left_leaf_count, 1);
% right_paths = cell(right_leaf_count, 1);
% lp_count = 0;
% rp_count = 0;
% 

leaf_paths = {};

for ii = 1:1:length(leaf_tips(:, 1))
    start_ID = sub2ind([height, width], leaf_tips(ii, 1), leaf_tips(ii, 2));
%     stalk_edge = [];
%     %if point is to left of stalk midline, only need to test points on left edge of stalk
% 
%     if leaf_tips(ii, 2) <= stalk_line(1)*leaf_tips(ii, 1)^2 + stalk_line(2)*leaf_tips(ii, 1) + stalk_line(3)
%         left = 1;
%         for row = panicle_base(1):1:stalk_bot(1)
%             col = 1;
%             while stalk(row, col) ~= 1 && stake(row, col) ~= 1
%                 col = col + 1;
%             end
%             %only need to test points that are also on skeleton
%             if skeleton(row, col) == 1
%                 stalk_edge = [stalk_edge; row, col];
%             end
%         end
%     else %if point is to right of stalk midline, only need to test points on right edge of stalk
%         left = 0;
%         for row = panicle_base(1):1:stalk_bot(1)
%             col = width;
%             while stalk(row, col) ~= 1 && stake(row, col) ~= 1
%                 col = col - 1;
%             end
%             
%             %only need to test points that are also on skeleton
%             if skeleton(row, col) == 1
%                 stalk_edge = [stalk_edge; row, col];
%             end
%         end
%     end
%     
%     %test each point on stalk_edge to find smoothest path
%     paths = cell(length(stalk_edge(:, 1)), 3);
%     %cell array to store paths, distance traveled by each path
%     %and RMSE of path when fit to 2nd order polynomial
%     
%     for jj = 1:1:length(stalk_edge(:, 1))
%         fin_ID = sub2ind([height, width], stalk_edge(jj, 1), stalk_edge(jj, 2));
%         [dist, path] = dijkstra(nodes, segments, start_ID, fin_ID);
%         
%         ind_path = zeros(length(path), 2);
%         for kk = 1:1:length(path)
%             [srow, scol] = ind2sub([height, width], path(kk));
%             ind_path(kk, :) = [srow, scol];
%         end
% 
%         smooth_path = ind_path;
%         frame = 2*floor(numel(path)/10) + 1; %round frame size to odd number
%         smooth_path(:, 1) = sgolayfilt(smooth_path(:, 1), 1, frame);
% 
%         total = 0;
%         for point_count = 1:1:length(smooth_path(:, 1))
%             smoothed = [smooth_path(point_count, 1), smooth_path(point_count, 2)];
%             actual = [ind_path(point_count, 1), ind_path(point_count, 2)];
%             total = total + sqrt((smoothed(1) - actual(1)).^2 + (smoothed(2) - actual(2)).^2);
%         end
%         RMSE = sqrt(total/point_count);
%         
%         if isnan(path) %path was not found
%             path(jj, :) = {NaN, NaN, NaN};
%         else
%             paths(jj, :) = {dist, path, RMSE};
%         end
%     end
    
    %at each branchpoint, consider both paths
    [srow, scol] = ind2sub([height, width], start_ID);
    paths = {[srow, scol]};
    completed_paths = {};
    while true
        %path cannot intersect with itself
        %iterate through each path, adding a point to each one
        for path_num = 1:1:length(paths(:, 1))
            path = paths{path_num, 1};
            neighbors = get_neighbors(skeleton, path(end, :));
            neighbors = neighbors(~ismember(neighbors(:, :), path(:, :), 'rows'), :);
            if isempty(neighbors) %path intersects with itself, or is unable to reach stalk/stake -> delete once finished looping
                paths{path_num, 1} = NaN;
            elseif length(neighbors(:, 1)) == 1 %single line, no branches
                path = [path; neighbors(1, 1), neighbors(1, 2)];
                paths{path_num, 1} = path;
            else %branchpoint, add first point in neighbors to current path, but make new path with any additional points
                base_path = [path; neighbors(1, 1), neighbors(1, 2)];
                paths{path_num, 1} = base_path;
                for x = 2:1:length(neighbors(:, 1))
                    path = [base_path(1:end - 1, :); neighbors(x, 1), neighbors(x, 2)];
                    paths{end + 1, 1} = path;
                end
            end
        end
        
        for path_num = length(paths(:, 1)):-1:1
            if isnan(paths{path_num, 1}) == 1
                paths(path_num, :) = [];
            end
        end
        
        %end loop when all paths meet stalk/stake
        for path_num = length(paths(:, 1)):-1:1
            path = paths{path_num, 1};
            if ismember(path(end, :), stalk_list(:, :), 'rows') || ismember(path(end, :), stake_list(:, :), 'rows')
                completed_paths{end + 1, 1} = path;
                paths{path_num, 1} = NaN;
            end
        end
        
        for path_num = length(paths(:, 1)):-1:1
            if isnan(paths{path_num, 1}) == 1
                paths(path_num, :) = [];
            end
        end
        
        unique_paths = {};
        
        if isempty(paths) %all paths have been completed
            %remove duplicate paths from completed_paths -> paths which share 95% of points in common
            %keeps shortest unique path
            for path1_num = length(completed_paths(:, 1)):-1:1
                path1 = completed_paths{path1_num, 1};
                unique = 1;
                if path1_num ~= 1
                    for path2_num = path1_num - 1:-1:1
                        path2 = completed_paths{path2_num, 1};
                        duplicates = 0;
                        for px_count = 1:1:length(path1(:, 1))
                            if ismember(path1(px_count, :), path2(:, :), 'rows')
                                duplicates = duplicates + 1;
                            end
                        end

                        if duplicates/length(path1(:, 1)) > 0.90
                            unique = 0;
                            break
                        end
                    end
                end
                if unique == 1
                    unique_paths{end + 1, 1} = path1;
                end
            end
            
            for path_num = 1:1:length(unique_paths(:, 1))
                path = unique_paths{path_num, 1};
                leaf_paths(ii, path_num) = {path};
            end
            
            break
        end
    end
end 

close all
%select path for each leaf which provides best approximation of shape
%to smooth, fit line to sliding window of previous set of points
%calculate RMSE @ each point

best_paths = cell(1 ,length(leaf_paths(:, 1)));
for ii = 1:1:length(leaf_paths(:, 1))
    row_paths = leaf_paths(ii, :);
    paths = row_paths(~cellfun('isempty', row_paths));
    
    %remove excessively long paths from consideration -> will skew RMSE values
    path_lengths = [];
    for jj = 1:1:length(paths)
        path_lengths = [path_lengths; length(paths{jj})];
    end
    
    cutoff = prctile(path_lengths(:, 1),  50);
    
    for jj = length(paths):-1:1
        if length([paths{1, jj}]) > cutoff
            paths(jj) = [];
        end
    end
            
    for jj = 1:1:length(paths)
        slopes = [];
        path = paths{1, jj};
        
        for pcount = round(length(path(:, 1))/10):1:length(path(:, 1))
            prev_points = path((pcount - round(length(path(:, 1))/10) + 1):pcount, :);
            line = polyfit(prev_points(:, 2), prev_points(:, 1), 1);
            %replace any vertical slope values ( > 10) with NaN, and
            %impute after
            if abs(line(1)) > 10
                line(1) = NaN;
            end
            slopes = [slopes; pcount - round(length(path(:, 1))/10) + 1, line(1)];
        end
        
        while sum(sum(isnan(slopes))) > 0
            slopes(:, 2) = fillmissing(slopes(:, 2), 'movmedian', 6);
        end
        
        smooth_slopes = slopes;
        frame = 2*floor(length(slopes(:, 1))/10) + 1; %round frame size to odd number
        smooth_slopes(:, 2) = sgolayfilt(smooth_slopes(:, 2), 1, frame);
        
        total = 0;
        for pcount = 1:1:length(slopes(:, 1))
            smoothed = smooth_slopes(pcount, 2);
            actual = slopes(pcount, 2);
            total = total + (smoothed - actual)^2;
        end
        RMSE = sqrt(total/pcount);
        paths(2, jj) = {RMSE};
    end
    
    best_RMSE = min([paths{2, :}]);
    ind = [paths{2, :}] == best_RMSE;
    best_path = paths{1, ind};
    best_paths(1, ii) = {best_path};

end

%calculate angles formed by each path with stalk line
angle_data = [];

for ii = 1:1:length(best_paths)
    path = best_paths{ii};
    
    %only consider final 20% of points in paths -> closest to stalk
    end_path = path(round(length(path(:, 1))*(4/5)):end, :);
    
    %fit line to leaf points
    leaf_line = polyfit(end_path(:, 1), end_path(:, 2), 1);

    %determine intersection location of leaf and stalk lines
    x = 1:1:height;
    stalk_y = stalk_line(1)*x.^2 + stalk_line(2)*x + stalk_line(3);
    leaf_y = leaf_line(1)*x + leaf_line(2);
    intersection = InterX([stalk_y; x], [leaf_y; x]);
    
    if ~isnan(intersection)
        %calculate slope of leaf and stalk lines at intersection point
        stalk_der = polyder(stalk_line);
        stalk_slope = stalk_der(1)*intersection(1) + stalk_der(2);

        leaf_slope = polyder(leaf_line);

        %determine if leaf is on left side or right side of plant before
        %calculating angle with stalk
        if path(1, 2) <= stalk_line(1)*path(1, 1)^2 + stalk_line(2)*path(1, 1) + stalk_line(3)
            angle = atand((leaf_slope - stalk_slope)/(1 + stalk_slope*leaf_slope));
        else
            angle = atand((stalk_slope - leaf_slope)/(1 + stalk_slope*leaf_slope));
        end
        
        if angle < 0
            angle = abs(angle) + 90;
        end
        
        angle_data = [angle_data; intersection(1), intersection(2), angle];
    end
end

average_angle = median(angle_data(:, 3));

end

%     %only consider paths in the lower 50th percentile of length
%     cutoff = prctile([paths{:, 1}], 100);
%     short_paths = paths([paths{:, 1}] < cutoff, :);
%     
%     
%     [~, path_ind] = min([short_paths{:, 3}]);
%     %remove points that are also part of stalk or stake
%     best_path = [short_paths{path_ind, 2}];
%     best_path_red = [];
%     for kk = 1:1:length(short_paths{path_ind, 2})
%         [srow, scol] = ind2sub([height, width], best_path(kk));
%         if stalk(srow, scol) == 0 && stake(srow, scol) == 0
%             best_path_red = [best_path_red; srow, scol];
%         end
%     end
%     
%     if left == 1
%         lp_count = lp_count + 1;
%         left_paths(lp_count, :) = {best_path_red};
%     else
%         rp_count = rp_count + 1;
%         right_paths(rp_count, :) = {best_path_red};
%     end
% end



% for path_count = 1:1:lp_count
%     path = left_paths{path_count};
%     plot(path(:, 2), path(:, 1), 'color', rand(1, 3), 'LineWidth', 5)
% end
%     
% for path_count = 1:1:rp_count
%     path = right_paths{path_count};
%     plot(path(:, 2), path(:, 1), 'color', rand(1, 3), 'LineWidth', 5)
% end

%end
    
%connect panicle_base to skeleton
% pixel = [panicle_base(1), panicle_base(2)];
% radius = 1;
% while skeleton(pixel(1), pixel(2)) ~= 1
% %test points outward from panicle_base until skeleton is found
% test_square = []; %collect points at perimeter of square centered at panicle_base
% for row = (panicle_base(1) - radius):1:(panicle_base(1) + radius)
%     for col = (panicle_base(2) - radius):1:(panicle_base(2) + radius)
%         test_square = [test_square; row, col];
%     end
% end
% ind = rangesearch(test_square, panicle_base, radius);
% ind = ind{1}; %returns indicies of points in test_square
% for pixel_count = 1:1:length(ind)
%     pixel = test_square(ind(pixel_count), :);
%     if skeleton(pixel(1), pixel(2)) == 1            
%         break
%     end
% end
% radius = radius + 1;
% end
% 
% dist = sqrt((pixel(1) - panicle_base(1)).^2 + (pixel(2) - panicle_base(2)).^2);
% num_points = dist/0.4;
% x_line = linspace(pixel(2), panicle_base(2), num_points);
% y_line = linspace(pixel(1), panicle_base(1), num_points);
% rows = round(y_line);
% cols = round(x_line);
% for k = 1:1:length(x_line)
%     skeleton(rows(k), cols(k)) = 1;
% end
% 
% %connect stalk_bot to skeleton
% pixel = [stalk_bot(1), stalk_bot(2)];
% radius = 1;
% while skeleton(pixel(1), pixel(2)) ~= 1
% %test points outward from panicle_base until skeleton is found
% test_square = []; %collect points at perimeter of square centered at panicle_base
% for row = (stalk_bot(1) - radius):1:(stalk_bot(1) + radius)
%     for col = (stalk_bot(2) - radius):1:(stalk_bot(2) + radius)
%         test_square = [test_square; row, col];
%     end
% end
% ind = rangesearch(test_square, stalk_bot, radius);
% ind = ind{1}; %returns indicies of points in test_square
% for pixel_count = 1:1:length(ind)
%     pixel = test_square(ind(pixel_count), :);
%     if skeleton(pixel(1), pixel(2)) == 1            
%         break
%     end
% end
% radius = radius + 1;
% end
%             
% dist = sqrt((pixel(1) - stalk_bot(1)).^2 + (pixel(2) - stalk_bot(2)).^2);
% num_points = dist/0.4;
% x_line = linspace(pixel(2), stalk_bot(2), num_points);
% y_line = linspace(pixel(1), stalk_bot(1), num_points);
% rows = round(y_line);
% cols = round(x_line);
% for k = 1:1:length(x_line)
%     skeleton(rows(k), cols(k)) = 1;
% end
% 
% %create array of nodes - each plant pixel in skeleton
% %first column stores pixel index - used to ID pixel
% %second column stores x position(column index)
% %third column stores y position(row index)
% skeleton_nodes = sum(sum(skeleton(:, :) == 1));
% pixel_count = 0;
% nodes = zeros(skeleton_nodes, 3);
% for row = 1:1:height
%     for col = 1:1:width
%         if skeleton(row, col) == 1
%             pixel_count = pixel_count + 1;
%             pixel_id = sub2ind([height, width], row, col);
%             nodes(pixel_count, 1) = pixel_id;
%             nodes(pixel_count, 2) = col;
%             nodes(pixel_count, 3) = row;
%         end
%     end
% end
% 
% segments = [];
% segment_id = 0;
% for row = 1:1:skeleton_nodes
%     pixel1_id = nodes(row, 1);
%     pixel1 = [nodes(row, 3), nodes(row, 2)];
%     [neighbors] = get_neighbors(skeleton, pixel1);
%     for ii = 1:1:length(neighbors(:, 1))
%         if skeleton(neighbors(ii, 1), neighbors(ii, 2)) == 1
%             segment_id = segment_id + 1;
%             pixel2_id = sub2ind([height, width], neighbors(ii, 1), neighbors(ii, 2));
%             segments = [segments; segment_id, pixel1_id, pixel2_id];
%         end
%     end
% end
% 
% start_ID = sub2ind([height, width], stalk_bot(1), stalk_bot(2));
% fin_ID = sub2ind([height, width], panicle_base(1), panicle_base(2));
% [dist, path] = dijkstra(nodes, segments, start_ID, fin_ID);
% 
% stalk_skeleton = zeros(length(path), 2);
% for pixel_count = 1:1:length(path)
%     [pixel_row, pixel_col] = ind2sub([height, width], path(pixel_count));
%     stalk_skeleton(pixel_count, 1) = pixel_row;
%     stalk_skeleton(pixel_count, 2) = pixel_col;
% end
% 
% skeleton = bwskel(skeleton);
% nodes = bwmorph(skeleton, 'branchpoints');