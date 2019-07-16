%cleans up stem pixels
%fits line to middle of stalk, and to variation of stalk width
%filename should point to an already segmented image
%set show_plots = 1 to show plots

function [segmented_image, shape_coefficients, stalk_range, width_coefficients, cutoff] = stalk_cleanup(filename)

segmented_image = imread(filename);
[height, width, ~] = size(segmented_image);

%binary image
stalk = zeros(height, width);

for row = 1:1:height
    for col = 1:1:width
        if segmented_image(row, col, 1) == 251 %stalk
            stalk(row, col) = 1;
        end
    end
end

%delete all areas less than 30 pixels in size
stalk = bwareaopen(stalk, 30);

%create array containing all stalk pixels
stalk_pixels = [];
for row = 1:1:height
    for col = 1:1:width
        if stalk(row, col) == 1
            stalk_pixels = [stalk_pixels; row, col];
        end
    end
end

%remove outlier pixels
outlier_col = isoutlier(stalk_pixels, 1);
for point_count = 1:1:length(stalk_pixels)
    if outlier_col(point_count, 2) == 1
        point = stalk_pixels(point_count, :);
        stalk(point(1), point(2)) = 0;
    end
end

%fill internal holes
stalk = imfill(stalk, 'holes');

%smooth edges
for row = 2:1:height - 1
    for col = 2:1:width - 1
        if stalk(row, col) == 0
            if ((stalk(row + 1, col) == 1) + (stalk(row - 1, col) == 1) + (stalk(row, col + 1) == 1) + (stalk(row, col - 1) == 1)) >= 3
                stalk(row, col) = 1;
            end
        else
            if ((stalk(row + 1, col) == 1) + (stalk(row - 1, col) == 1) + (stalk(row, col + 1) == 1) + (stalk(row, col - 1) == 1)) <= 1
                stalk(row, col) = 0;
            end
        end
    end
end

%cut off pot pixels
%starting from top, count pixels left to right, but break if a gap is detected
for row = 1:1:height
    stalk_width = 0;
    for col = 1:1:width
        if stalk(row, col) == 1
            stalk_width = stalk_width + 1; %doesn't account for missing pixels in pot
        elseif stalk_width >= 1 && stalk(row, col) == 0
            break
        end
    end
    if stalk_width >= 15
        cutoff = row;
        break
    end
end
for row = cutoff:1:height
    stalk(row, :) = 0;
end

%get median column pixel for each stalk-containing row
line_stalk_pixels = [];
for row = 1:1:height
    stalk_pixel_count = sum(stalk(row, :) == 1) > 0; %test if row contains stalk
    y_coordinates = zeros(1, stalk_pixel_count);
    if stalk_pixel_count > 0
        pixel_count = 0;
        for col = 1:1:width
            if stalk(row, col) == 1
                pixel_count = pixel_count + 1;
                y_coordinates(1, pixel_count) = col;
            end
        end
        line_stalk_pixels = [line_stalk_pixels; row, median(y_coordinates)];
    end
end

%define range of line - top of stalk to bottom of stalk
stalk_pixels = [];
for row = 1:1:height
    for col = 1:1:width
        if stalk(row, col) == 1
            stalk_pixels = [stalk_pixels; row, col];
        end
    end
end
stalk_bot = max(stalk_pixels(:, 1));
stalk_top = min(stalk_pixels(:, 1));

%fit line to middle of stalk, and evaluate accuracy
stalk_range = stalk_top:1:stalk_bot;

%1st degree
line1 = polyfit(line_stalk_pixels(:, 1), line_stalk_pixels(:, 2), 1);
y1 = line1(1)*stalk_range + line1(2);
sum1 = 0;
for point_count = 1:1:length(stalk_pixels)
    row = stalk_pixels(point_count, 1);
    predicted = line1(1)*row + line1(2);
    actual = stalk_pixels(point_count, 2);
    sum1 = sum1 + (predicted - actual).^2;
end
RMSE1 = sqrt(sum1/point_count);

%2nd degree
line2 = polyfit(line_stalk_pixels(:, 1), line_stalk_pixels(:, 2), 2);
y2 = line2(1)*stalk_range.^2 + line2(2)*stalk_range + line2(3);
sum2 = 0;
for point_count = 1:1:length(stalk_pixels)
    row = stalk_pixels(point_count, 1);
    predicted = line2(1)*row.^2 + line2(2)*row + line2(3);
    actual = stalk_pixels(point_count, 2);
    sum2 = sum2 + (predicted - actual).^2;
end
RMSE2 = sqrt(sum2/point_count);

% if show_plots == 1
%     figure(1)
%     if RMSE1 < RMSE2
%         imshow(stalk)
%         hold on
%         plot(y1, stalk_range, 'r', 'LineWidth', 1)
%     else
%         imshow(stalk)
%         hold on
%         plot(y2, stalk_range, 'b', 'LineWidth', 1)
%     end
%     hold
% end

%calculate average stalk width over height of plant, and use to fill in
%gaps and remove extra pixels
stalk_pixel_count = zeros(stalk_bot - stalk_top, 2);
for row = stalk_top:1:stalk_bot
    stalk_pixel_count(row - stalk_top + 1, 1) = row;
    stalk_pixel_count(row - stalk_top + 1, 2) = sum(stalk(row, :) == 1);
end

%remove portions of missing stalk and outliers
missing_stalk = stalk_pixel_count(:, 2) == 0;
stalk_pixel_count(missing_stalk, :) = [];

%rows with stalk that don't intersect with fitted line are unreliable
for row = stalk_top:1:stalk_bot
    if RMSE1 < RMSE2
        point = [row, round(line1(1)*row + line1(2))];
    else
        point = [row, round(line2(1)*row.^2 + line2(2)*row + line2(3))];
    end
    if stalk(point(1), point(2)) == 0 && ismember(row, stalk_pixel_count(:, 1)) == 1 %all of stalk pixels are being deleted
        stalk_pixel_count(stalk_pixel_count(:, 1) == point(1), :) = [];
    end
end

outliers = isoutlier(stalk_pixel_count(:, 2));
stalk_pixel_count(outliers, :) = [];

%fit line to width distribution, and evaluate accuracy
stalk_range = stalk_top:1:stalk_bot;

%linear
line3 = polyfit(stalk_pixel_count(:, 1), stalk_pixel_count(:, 2), 1);
y3 = line3(1)*stalk_range + line3(2);
sum3 = 0;
for point_count = 1:1:length(stalk_pixel_count)
    row = stalk_pixel_count(point_count, 1);
    predicted = line3(1)*row + line3(2);
    actual = stalk_pixel_count(point_count, 2);
    sum3 = sum3 + (predicted - actual).^2;
end
RMSE3 = sqrt(sum3/point_count);

%2nd degree polynomial
line4 = polyfit(stalk_pixel_count(:, 1), stalk_pixel_count(:, 2), 2);
y4 = line4(1)*stalk_range.^2 + line4(2)*stalk_range + line4(3);
sum4 = 0;
for point_count = 1:1:length(stalk_pixel_count)
    row = stalk_pixel_count(point_count, 1);
    predicted = line4(1)*row.^2 + line4(2)*row + line4(3);
    actual = stalk_pixel_count(point_count, 2);
    sum4 = sum4 + (predicted - actual).^2;
end
RMSE4 = sqrt(sum4/point_count);

%3rd degree polynomial
line5 = polyfit(stalk_pixel_count(:, 1), stalk_pixel_count(:, 2), 3);
y5 = line5(1)*stalk_range.^3 + line5(2)*stalk_range.^2 + line5(3)*stalk_range + line5(4);
sum5 = 0;
for point_count = 1:1:length(stalk_pixel_count)
    row = stalk_pixel_count(point_count, 1);
    predicted = line5(1)*row.^3 + line5(2)*row.^2 + line5(3)*row + line5(4);
    actual = stalk_pixel_count(point_count, 2);
    sum5 = sum5 + (predicted - actual).^2;
end
RMSE5 = sqrt(sum5/point_count);

% if show_plots == 1
%     figure(2)
%     if RMSE3 < RMSE4 && RMSE3 < RMSE5
%         scatter(stalk_pixel_count(:, 1), stalk_pixel_count(:, 2));
%         hold on
%         plot(stalk_range, y3, 'r', 'LineWidth', 1)
%         hold
%     elseif RMSE4 < RMSE3 && RMSE4 < RMSE5
%         scatter(stalk_pixel_count(:, 1), stalk_pixel_count(:, 2));
%         hold on
%         plot(stalk_range, y4, 'b', 'LineWidth', 1)
%         hold
%     elseif RMSE5 < RMSE3 && RMSE5 < RMSE4
%         scatter(stalk_pixel_count(:, 1), stalk_pixel_count(:, 2));
%         hold on
%         plot(stalk_range, y5, 'g', 'LineWidth', 1)
%         hold
%     else
%         disp('The width of the stalk can be equally approximated by a linear equation, a 2nd degree polynomial, and a 3rd degree polynomial')
%     end
% end

%using equations for stalk shape and width, fill in missing pixels and
%delete stalk pixels > 2x stalk width approximation away from middle of
%stalk
for row = stalk_top:1:stalk_bot
    %use best stalk shape approximation
    if RMSE1 < RMSE2 
        center = line1(1)*row + line1(2);
        shape_coefficients = line1;
    else
        center = line2(1)*row.^2 + line2(2)*row + line2(3);
        shape_coefficients = line2;
    end
    %use best stalk width approximation
    if RMSE3 < RMSE4 && RMSE3 < RMSE5 
        stem_width = line3(1)*row + line3(2);
        width_coefficients = line3;
    elseif RMSE4 < RMSE5 && RMSE4 < RMSE5
        stem_width = line4(1)*row.^2 + line4(2)*row + line4(3);
        width_coefficients = line4;
    else
        stem_width = line5(1)*row.^3 + line5(2)*row.^2 + line5(3)*row + line5(4);
        width_coefficients = line5;
    end
    inner_left = ceil(center - (stem_width/2));
    inner_right = floor(center + (stem_width/2));
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

% if show_plots == 1
%     figure(3)
%     imshow(stalk)
% end

%reintegrate corrected stalk into total segmented image
%continue looping until no new pixels are reclassified

changes_made = 1; %counter to keep track of changes made
while changes_made ~= 0
    changes_made = 0;
    for row = 1:1:height
        for col = 1:1:width
            if segmented_image(row, col, 1) == 251 && stalk(row, col) ~= 1
                if row ~= 1 && row ~= height && col ~= 1 && col ~= width
                    %change to background, but if surrounded by leaf, change to leaf
                    %get neighbor pixels from 2 away in segmented_image
                    top = segmented_image(row - 1, col, 1) == 0;
                    bot = segmented_image(row + 1, col, 1) == 0;
                    inner_left = segmented_image(row, col - 1, 1) == 0;
                    inner_right = segmented_image(row, col + 1, 1) == 0;
                    top_left = segmented_image(row - 1, col - 1, 1) == 0;
                    top_right = segmented_image(row - 1, col + 1, 1) == 0;
                    bot_left = segmented_image(row + 1, col - 1, 1) == 0;
                    bot_right = segmented_image(row + 1, col + 1, 1) == 0;
                    total = top + bot + inner_left + inner_right + top_left + top_right + bot_left + bot_right;
                    if total >= 4 %surrounded by leaf - change to leaf
                        segmented_image(row, col, 1) = 0;
                        segmented_image(row, col, 2) = 147;
                        segmented_image(row, col, 3) = 0;
                        changes_made = 1;
                    else %not surrounded by leaf - change to background
                        segmented_image(row, col, :) = 255;
                    end
                else
                    segmented_image(row, col, :) = 255;
                end
            elseif segmented_image(row, col, 1) ~= 251 && stalk(row, col) == 1
                segmented_image(row, col, 1) = 251; %change to stalk
                segmented_image(row, col, 2) = 129;
                segmented_image(row, col, 3) = 14;       
            end
        end
    end
end

end