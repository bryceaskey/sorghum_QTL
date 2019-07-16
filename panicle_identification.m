%panicle_identification
%identifies panicle center
function [panicle_row, panicle_col, circle_rows, circle_cols] = panicle_identification(all_plant, image, stake, stake_bin)

disp('Identifying panicle')

[height, width] = size(all_plant);
panicle = zeros(height, width);

for row = 1:1:height
    for col = 1:1:width
        if stake(row, col) == 0
            if all_plant(row, col) == 1 && image(row, col, 1) >= 50 && image(row, col, 1) < 70 && image(row, col, 2) > 3 && image(row, col, 3) > 10
                panicle(row, col) = 1;
            elseif all_plant(row, col) == 1 && image(row, col, 1) >= 70 && image(row, col, 2) < -3 && image(row, col, 3) > 10
                panicle(row, col) = 1;
            end
        end
    end
end

%need method to automatically adjust size of searching window to account
%for different size panicles
%start with small window - gradually increase size, recording max number of
%panicle pixels detected by each window size

min_size = 30; 
max_size = 150;
max_pixel_count = zeros((max_size - min_size)/5, 5);
%1st column is window area
%2nd and 3rd columns are coordinates for center of window
%4th column is number of panicle pixels detected in window
%5th column is ROC of pixels detecting relative to previous point

for window_size = min_size:5:max_size
    windows = zeros((height - window_size)*(width - window_size), 3);
    %1st 2 columns are row and col coordinates for each window
    %3rd column is number of panicle pixels in window
    window_count = 0;
    for row = 1:5:height - window_size
        for col = 1:5:width - window_size
            window_count = window_count + 1;
            pixel_count = sum(sum(panicle(row:row + window_size, col:col + window_size)));
            avg_row = row + window_size/2;
            avg_col = col + window_size/2;
            windows(window_count, 1) = avg_row;
            windows(window_count, 2) = avg_col;
            windows(window_count, 3) = pixel_count;
        end
    end
    max_points = max(windows(:, 3));
    ind = find(windows(:, 3) == max_points);
    panicle_row = round(mean(windows(ind, 1)));
    panicle_col = round(mean(windows(ind, 2)));

    
    max_pixel_count((window_size - min_size)/5 + 1, 1) = window_size.^2; %area
    max_pixel_count((window_size - min_size)/5 + 1, 2) = panicle_row;
    max_pixel_count((window_size - min_size)/5 + 1, 3) = panicle_col;
    max_pixel_count((window_size - min_size)/5 + 1, 4) = max_points;

end



%get line connecting each window size and point count point
%select point with minimum change in slope

for line_count = 2:1:length(max_pixel_count(:, 1))
    prev_point = [max_pixel_count(line_count - 1, 1), max_pixel_count(line_count - 1, 4)];
    current_point = [max_pixel_count(line_count, 1), max_pixel_count(line_count, 4)];
    line = polyfit([prev_point(1), current_point(1)], [prev_point(2), current_point(2)], 1);
    max_pixel_count(line_count, 5) = round(line(1), 5);
end
max_pixel_count(1, 5) = 1;

cutoff = find(max_pixel_count(:, 5) < 0.01);
if ~isempty(cutoff)
    ind = cutoff(1);
else
    min_slope = min(max_pixel_count(:, 5));
    ind = find(max_pixel_count(:, 5) == min_slope); %if multiple points with same slope, select first point
    ind = ind(1);
end

%fit line to window size and pixel count data in all_max
%2nd derivative negative?
window_size = round(sqrt(max_pixel_count(ind, 1)));

panicle_row = round(max_pixel_count(ind, 2));
panicle_col = round(max_pixel_count(ind, 3));

%get coordinates of circle used to represent panicle - make perimeter of
%circle 3 px thick - ensure intersection with stalk line
circle_cols = [];
circle_rows = [];
for radius = (((window_size/2) + (window_size/2))/2) - 1:1:(((window_size/2) + (window_size/2))/2) + 1
    theta = linspace(0, 2*pi, 1000);
    circle_cols = [circle_cols, radius*cos(theta) + panicle_col];
    circle_rows = [circle_rows, radius*sin(theta) + panicle_row];
end
%assume panicle center is represented by point
%delete any panicle pixels that aren't within 50 pixels of center
% for row = 1:1:height
%     for col = 1:1:width
%         if panicle(row, col) == 1
%             dist = sqrt((row - panicle_row).^2 + (col - panicle_col).^2);
%             if dist > 50
%                 panicle(row, col) = 0;
%             end
%         end
%     end
% end


%imshow(all_plant)
%hold on
%plot(panicle_col, panicle_row, 'r*', 'MarkerSize', 10)
%panicle_area = viscircles([panicle_col, panicle_row], 50, 'LineWidth', 1);

end