function [path] = FindPath(start,finish,binary) %Created by Bryce Asked and James DePadua
    explore = [start, 0];
    pixel = start;
    count = 1;
    [height, width] = size(binary);
    checked = zeros(height, width);
    checked(start) = 1;
    
    while pixel(1) ~= finish(1) || pixel(2) ~= finish(2)
        neighbors = zeros(4, 2);
        neighbors(1, :) = [pixel(1) - 1, pixel(2)];
        neighbors(2, :) = [pixel(1) + 1, pixel(2)];
        neighbors(3, :) = [pixel(1), pixel(2) - 1];
        neighbors(4, :) = [pixel(1), pixel(2) + 1];
        for row = 1:1:4
            if neighbors(row, 1) <= height && neighbors(row, 1) > 0 && neighbors(row, 2) <= width && neighbors(row, 2) > 0
                if binary(neighbors(row, 1), neighbors(row, 2)) == 1 && checked(neighbors(row, 1), neighbors(row, 2)) == 0%&& ismember(neighbors(row, :), explore(:, 1:2), 'rows') == 0
                    explore = [explore; neighbors(row, :), count];
                    checked(neighbors(row, 1), neighbors(row, 2)) = 1;
                end
            end
        end
        count = count + 1;
        pixel = explore(count, 1:2);
    end

    [num_values, ~] = size(explore);
    for x = 1:1:num_values
        if explore(x, 1) == finish(1) && explore(x, 2) == finish(2)
            path = explore(x, :);
        end
    end

    while path(end, 3) ~= 0
        prev_row = explore(path(end, 3), :);
        path = [path; prev_row];
    end
end