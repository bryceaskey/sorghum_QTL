%leaf_angle_v2
%use skeleton method to determine average angle leaves make with stalk
%starting at endpoints identified in leaf_counting_v2, trace back on
%skeleton to find smoothest path to stalk, then fit line to skeleton points
function [average_angle, flag_leaf_node] = leaf_angle_v2(all_plant, skeleton, stalk, stalk_line, stake, endpoints)

if sum(sum(endpoints)) > 0
    [height, width] = size(all_plant);
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

    leaf_paths = {};

    for ii = 1:1:length(leaf_tips(:, 1))
        start_ID = sub2ind([height, width], leaf_tips(ii, 1), leaf_tips(ii, 2));
        %at each branchpoint, consider both paths
        [srow, scol] = ind2sub([height, width], start_ID);
        paths = {[srow, scol]};
        completed_paths = {};
        path_found = 0;
        length_cutoff = NaN;
        while true
            if path_found == 1
                if length(paths{1, 1}) > length_cutoff
                    break
                end
            end
            
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

            %add paths that meet stalk/stake to completed paths
            for path_num = length(paths(:, 1)):-1:1
                path = paths{path_num, 1};
                if ismember(path(end, :), stalk_list(:, :), 'rows') || ismember(path(end, :), stake_list(:, :), 'rows')
                    completed_paths{end + 1, 1} = path;
                    paths{path_num, 1} = NaN;
                end
            end
            
            %length cutoff for paths is 1.5 x that of the first path that
            %meets stalk/stake
            if ~isempty(completed_paths)
                path_found = 1;
                length_cutoff = length(completed_paths{1, 1})*1.5;
            end

            for path_num = length(paths(:, 1)):-1:1
                if isnan(paths{path_num, 1}) == 1
                    paths(path_num, :) = [];
                end
            end

            unique_paths = {};
            if ~isempty(completed_paths)
                if isempty(paths) || length(paths{1, 1}) > length_cutoff %all paths have been completed
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
            elseif isempty(completed_paths) && isempty(paths)
                leaf_paths{ii, end + 1} = [];
                break
            end
        end
    end 
    
    %select path for each leaf which provides best approximation of shape
    %to smooth, fit line to sliding window of previous set of points
    %calculate RMSE @ each point
    best_paths = cell(1 ,length(leaf_paths(:, 1)));
    for ii = 1:1:length(leaf_paths(:, 1))
        row_paths = leaf_paths(ii, :);
        paths = row_paths(~cellfun('isempty', row_paths));
        if ~isempty(paths)
            %remove excessively long paths from consideration -> will skew RMSE values
            path_lengths = [];
            for jj = 1:1:length(paths)
                path_lengths = [path_lengths; length(paths{jj})];
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
        else
            best_paths(1, ii) = {NaN};
        end
    end

    %calculate angles formed by each path with stalk line
    angle_data = [];

    for ii = 1:1:length(best_paths)
        path = best_paths{ii};
        if ~isnan(path)

            %only consider final 33% of points in paths -> closest to stalk
            end_path = path(round(length(path(:, 1))*(2/3)):end, :);

            %fit line to leaf points
            leaf_line = polyfit(end_path(:, 1), end_path(:, 2), 1);

            %determine intersection location of leaf and stalk lines
            x = 1:1:height;
            stalk_y = stalk_line(1)*x.^2 + stalk_line(2)*x + stalk_line(3);
            leaf_y = leaf_line(1)*x + leaf_line(2);
            intersection = [];
            intersection = InterX([stalk_y; x], [leaf_y; x]);

            if ~isempty(intersection)
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

                angle_data = [angle_data; intersection(2), intersection(1), angle];
            else
                angle_data = [angle_data; NaN, NaN, NaN];
            end
        else
            angle_data = [angle_data; NaN, NaN, NaN];
        end
    end
    
    average_angle = nanmedian(angle_data(:, 3));
else
    average_angle = NaN;
end

%determine flag leaf intersection with stalk -> flag leaf node
if ~isnan(min(angle_data(:, 1)))
    flag_leaf_ind = find(angle_data(:, 1) == min(angle_data(:, 1)));
    flag_leaf_node = [round(angle_data(flag_leaf_ind, 1)), round(angle_data(flag_leaf_ind, 2))];
else
    flag_leaf_node = NaN;
end

end