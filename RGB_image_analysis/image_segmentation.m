%image_segmentation - using stalk line from stalk_identification and panicle circle from and panicle_identification
%separates image into stalk, panicle, and leaves
function [segmented_image, stalk, panicle, leaves, width_coeffs] = image_segmentation(all_plant, panicle_base, panicle_row, panicle_col, stalk_line, stalk_bot, stake)

[height, width] = size(all_plant);
panicle = zeros(height, width);

%separate panicle pixels - any pixels within panicle circle identified in
%panicle_identification
radius = sqrt((panicle_base(1) - panicle_row).^2 + (panicle_base(2) - panicle_col).^2);
for row = 1:1:height
    for col = 1:1:width
        dist = sqrt((row - panicle_row).^2 + (col - panicle_col).^2);
        if dist <= radius && all_plant(row, col) == 1
            panicle(row, col) = 1;
        end
    end
end

%separate stalk pixels - get stalk width up length of stem
%ignore rows where line doesn't intersect with all_plant pixels
%also ignore rows where stalk width exceeds ~20? - caused by leaf overlap
stalk_width = zeros(stalk_bot(1) - panicle_base(1), 2); %first col stores row #, second col stores stalk width
for row = panicle_base(1):1:stalk_bot(1)
    stalk_width(row - panicle_base(1) + 1, 1) = row;
    stalk_col = round(stalk_line(1)*row.^2 + stalk_line(2)*row + stalk_line(3));
    if all_plant(row, stalk_col) == 1 %stalk line intersects with all_plant
        width_counter = 1; %counter to keep track of stalk width
        
        dist = 1; %distance from stalk_col to test
        left = 1; %switch to count stalk pixels to left of line
        while left == 1
            test_col = stalk_col - dist;
            if all_plant(row, test_col) == 1
                width_counter = width_counter + 1;
                dist = dist + 1;
            else
                left = 0; %end of stalk
            end
        end
        
        dist = 1;
        right = 1; %switch to count stalk pixels to right of line
        while right == 1
            test_col = stalk_col + dist;
            if all_plant(row, test_col) == 1
                width_counter = width_counter + 1;
                dist = dist + 1;
            else
                right = 0; %end of stalk
            end
        end
        
        if width_counter < 20 %protects against leaf overlap with stalk
            stalk_width(row - panicle_base(1) + 1, 2) = width_counter;
        else
            stalk_width(row - panicle_base(1) + 1, 2) = NaN;
        end
    else
        stalk_width(row - panicle_base(1) + 1, 2) = NaN;
    end
end

stalk_width(any(isnan(stalk_width), 2), :) = [];


if ~isempty(stalk_width)
    if length(stalk_width(:, 1)) > (stalk_bot(1) - panicle_base(1))/5
        window = 10;
        median_width = movmedian(stalk_width, window);
        median_width(any(isnan(median_width), 2), :) = [];
        stalk_range = panicle_base(1):1:stalk_bot(1);

        %linear
        line1 = polyfit(stalk_width(:, 1), stalk_width(:, 2), 1);
        y1 = line1(1)*stalk_range + line1(2); %for plotting
        sum1 = 0;
        for point_count = 1:1:length(stalk_width)
            row = stalk_width(point_count, 1);
            predicted = line1(1)*row + line1(2);
            actual = stalk_width(point_count, 2);
            sum1 = sum1 + (predicted - actual).^2;
        end
        RMSE1 = sqrt(sum1/point_count);

        %2nd degree polynomial
        line2 = polyfit(stalk_width(:, 1), stalk_width(:, 2), 2);
        y2 = line2(1)*stalk_range.^2 + line2(2)*stalk_range + line2(3);
        sum2 = 0;
        for point_count = 1:1:length(stalk_width)
            row = stalk_width(point_count, 1);
            predicted = line2(1)*row.^2 + line2(2)*row + line2(3);
            actual = stalk_width(point_count, 2);
            sum2 = sum2 + (predicted - actual).^2;
        end
        RMSE2 = sqrt(sum2/point_count);

        %3rd degree polynomial
        line3 = polyfit(stalk_width(:, 1), stalk_width(:, 2), 3);
        y3 = line3(1)*stalk_range.^3 + line3(2)*stalk_range.^2 + line3(3)*stalk_range + line3(4);
        sum3 = 0;
        for point_count = 1:1:length(stalk_width)
            row = stalk_width(point_count, 1);
            predicted = line3(1)*row.^3 + line3(2)*row.^2 + line3(3)*row + line3(4);
            actual = stalk_width(point_count, 2);
            sum3 = sum3 + (predicted - actual).^2;
        end
        RMSE3 = sqrt(sum3/point_count);

        %using equations for stalk shape and width, fill in missing pixels and
        %delete stalk pixels > 2x stalk width approximation away from middle of
        %stalk
        stalk = all_plant;
        stalk(1:panicle_base, :) = 0;
        stalk(stalk_bot(1):height, :) = 0;
        stalk = bwareaopen(stalk, 50);

        for row = panicle_base(1):1:stalk_bot(1)
            center = stalk_line(1)*row.^2 + stalk_line(2)*row + stalk_line(3);
            %use best stalk width approximation
            if RMSE1 < RMSE2 && RMSE1 < RMSE3 
                stem_width = line1(1)*row + line1(2);
                width_coeffs = line1;
            elseif RMSE2 < RMSE1 && RMSE2 < RMSE3
                stem_width = line2(1)*row.^2 + line2(2)*row + line2(3);
                width_coeffs = line2;
            else
                stem_width = line3(1)*row.^3 + line3(2)*row.^2 + line3(3)*row + line3(4);
                width_coeffs = line3;
            end

            %minimum and maximum stalk width to prevent distortion
            if stem_width > 12
                stem_width = 12;
            elseif stem_width < 2
                stem_width = 2;
            end

            inner_left = ceil(center - (stem_width/3));
            inner_right = floor(center + (stem_width/3));
            outer_left = floor(center - (stem_width/2));
            outer_right = ceil(center + (stem_width/2));
            for col = inner_left:1:inner_right
                if stalk(row, col) ~= 1
                    stalk(row, col) = 1;
                end
            end
            for col = 1:1:outer_left
                if stalk(row, col) == 1
                    stalk(row, col) = 0;
                end
            end
            for col = outer_right:1:width
                if stalk(row, col) == 1
                    stalk(row, col) = 0;
                end
            end
        end

        %smooth leaf outlines
        leaves = (all_plant - stalk) - panicle;
        leaves = bwareaopen(leaves, 200);
        leaves = ~bwareaopen(~leaves, 100);

        panicle = logical(panicle);

        %combine stalk, panicle, and leaves into single, color-coded image
        segmented_image = uint8(zeros(height, width));
        for row = 1:1:height
            for col = 1:1:width
                if stalk(row, col) == 1
                    segmented_image(row, col, 1) = 251;
                    segmented_image(row, col, 2) = 129;
                    segmented_image(row, col, 3) = 14;
        %         elseif stake(row, col) == 1
        %             segmented_image(row, col, 1) = 0;
        %             segmented_image(row, col, 2) = 0;
        %             segmented_image(row, col, 3) = 0;
                elseif panicle(row, col) == 1
                    segmented_image(row, col, 1) = 126;
                    segmented_image(row, col, 2) = 94;
                    segmented_image(row, col, 3) = 169;
                elseif leaves(row, col) == 1
                    segmented_image(row, col, 2) = 147;
                else
                    segmented_image(row, col, 1) = 255;
                    segmented_image(row, col, 2) = 255;
                    segmented_image(row, col, 3) = 255;
                end
            end
        end
    else
        segmented_image = NaN;
        stalk = NaN;
        panicle = NaN;
        leaves = NaN;
        width_coeffs = NaN;
    end
else
    segmented_image = NaN;
    stalk = NaN;
    panicle = NaN;
    leaves = NaN;
    width_coeffs = NaN;
end

end