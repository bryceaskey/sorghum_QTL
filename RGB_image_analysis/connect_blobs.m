function [conn_bin_image] = connect_blobs(bin_image)

[height, width] = size(bin_image);
conn_bin_image = bin_image;

blobs = bwconncomp(bin_image);

%largest blob is primary
[~, max_ind] = max(cellfun(@numel, blobs.PixelIdxList));
[brow, bcol] = ind2sub([height, width], blobs.PixelIdxList{max_ind});
blob1_coor = [brow, bcol];
blob1 = zeros(height, width);
for row = 1:1:length(blob1_coor(:, 1))
    blob1(blob1_coor(row, 1), blob1_coor(row, 2)) = 1;
end

%get blob outline, and make array of points
blob1 = bwboundaries(blob1, 'noholes');
blob1 = blob1{1};

for ii = 1:1:blobs.NumObjects
    if ii ~= max_ind
        blob2 = zeros(height, width);
        [brow, bcol] = ind2sub([height, width], blobs.PixelIdxList{ii});
        blob2_coor = [brow, bcol];
        blob2 = zeros(height, width);
        for row = 1:1:length(blob2_coor(:, 1))
            blob2(blob2_coor(row, 1), blob2_coor(row, 2)) = 1;
        end

        %get blob outline
        blob2 = bwboundaries(blob2, 'noholes');
        blob2 = blob2{1};

        %find point on blob outline closest to neighbor
        %first four columns store coordinates, fifth stores distance
        connections = zeros(length(blob1(:, 1))*length(blob2(:, 1)), 5);
        conn_count = 0;
        for b1_count = 1:1:length(blob1(:, 1))
            b1_point = blob1(b1_count, :);
            for b2_count = 1:1:length(blob2(:, 1))
                conn_count = conn_count + 1;
                b2_point = blob2(b2_count, :);
                dist = sqrt((b1_point(1) - b2_point(1))^2 + (b1_point(2) - b2_point(2))^2);
                connections(conn_count, :) = [b1_point(1), b1_point(2), b2_point(1), b2_point(2), dist];
            end
        end
    end
end

%find minimum distance in array
min_dist = min(connections(:, 5));
min_ind = find(connections(:, 5) == min_dist);
point1 = [connections(min_ind, 1), connections(min_ind, 2)];
point2 = [connections(min_ind, 3), connections(min_ind, 4)];

num_points = dist/0.4;
x_line = linspace(point1(2), point2(2), num_points);
y_line = linspace(point1(1), point2(1), num_points);
rows = round(y_line);
cols = round(x_line);
for k = 1:1:length(x_line)
    conn_bin_image(rows(k), cols(k)) = 1;
end

end