%panicle_identification
%identifies panicle center
function [panicle_row, panicle_col] = panicle_identification(all_plant, image, stake, stake_bin)

[height, width] = size(all_plant);
panicle = zeros(height, width);

for row = 1:1:height
    for col = 1:1:width
        if stake_bin == 1
            if stake(row, col) == 0
                if all_plant(row, col) == 1 && image(row, col, 1) >= 45 && image(row, col, 2) > 5 && image(row, col, 3) > 25
                    panicle(row, col) = 1;
                end
            end
        else
            if all_plant(row, col) == 1 && image(row, col, 1) >= 45 && image(row, col, 2) > 5 && image(row, col, 3) > 25
                panicle(row, col) = 1;
            end
        end
    end
end

panicle = imfill(panicle);

m = 25; %window height
n = 25; %window width

windows = zeros((height - m)*(width - n), 3);
%1st 2 columns are row and col coordinates for each window
%3rd column is number of panicle pixels in window
window_count = 0;
for row = 1:1:height - m
    for col = 1:1:width - n
        window_count = window_count + 1;
        pixel_count = sum(sum(panicle(row:row + m, col:col + n)));
        avg_row = row + m/2;
        avg_col = col + n/2;
        windows(window_count, 1) = avg_row;
        windows(window_count, 2) = avg_col;
        windows(window_count, 3) = pixel_count;
    end
end
[~, ind] = max(windows(:, 3));
panicle_row = round(windows(ind, 1));
panicle_col = round(windows(ind, 2));

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