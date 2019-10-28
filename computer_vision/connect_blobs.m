% Function to connect disconnected plant regions to each other.
% Joins regions based on proximity.
function [conn_plant] = connect_blobs(conn_plant)

[height, width] = size(conn_plant);  

blobInfo = bwconncomp(conn_plant);
blobs = blobInfo.PixelIdxList;

while length(blobs) > 1
    [rows, cols] = ind2sub([height, width], blobs{1});
    blob1 = [rows, cols];
    blob1BinImage = zeros(height, width);
    for ii = 1:1:length(blob1(:, 1))
        blob1BinImage(blob1(ii, 1), blob1(ii, 2)) = 1;
    end
    blob1Outline = bwboundaries(logical(blob1BinImage), 8, 'noholes');
    blob1Outline = blob1Outline{1};
    closestPoints = [];
    
    for ii = 2:1:length(blobs)
        blob2 = blobs(ii);
        [rows, cols] = ind2sub([height, width], blobs{ii});
        blob2 = [rows, cols];
        blob2BinImage = zeros(height, width);
        for jj = 1:1:length(blob2(:, 1))
            blob2BinImage(blob2(jj, 1), blob2(jj, 2)) = 1;
        end
        blob2Outline = bwboundaries(logical(blob2BinImage), 8, 'noholes');
        blob2Outline = blob2Outline{1};
        
        pixelDists = zeros(length(blob1Outline(:, 1))*length(blob2Outline(:, 2)), 5);
        pxCount = 0;
        
        for b1PxCount = 1:1:length(blob1Outline(:, 1))
            blob1Pixel = blob1Outline(b1PxCount, :);
            for b2PxCount = 1:1:length(blob2Outline(:, 1))
                pxCount = pxCount + 1;
                blob2Pixel = blob2Outline(b2PxCount, :);
                dist = sqrt((blob1Pixel(1) - blob2Pixel(1))^2 + (blob1Pixel(2) - blob2Pixel(2))^2);
                
                pixelDists(pxCount, 1) = blob1Pixel(1);
                pixelDists(pxCount, 2) = blob1Pixel(2);
                pixelDists(pxCount, 3) = blob2Pixel(1);
                pixelDists(pxCount, 4) = blob2Pixel(2);
                pixelDists(pxCount, 5) = dist;
            end
        end
        
        closestPoints = [closestPoints; pixelDists(find(pixelDists(:, 5) == min(pixelDists(:, 5)), 1, 'first'), :)];
    end
    % Find and save pixels with minimum distance separating them from
    % each other.
    blob1Pixel = closestPoints(find(closestPoints(:, 5) == min(closestPoints(:, 5)), 1, 'first'), 1:2);
    blob2Pixel = closestPoints(find(closestPoints(:, 5) == min(closestPoints(:, 5)), 1, 'first'), 3:4);
    numPoints = round(closestPoints(find(closestPoints(:, 5) == min(closestPoints(:, 5)), 1, 'first'), 5)*3);
    rowPoints = round(linspace(blob1Pixel(1), blob2Pixel(1), numPoints));
    colPoints = round(linspace(blob1Pixel(2), blob2Pixel(2), numPoints));
    
    for ii = 1:1:length(rowPoints)
        conn_plant(rowPoints(ii), colPoints(ii)) = 1;
    end
    
    blobInfo = bwconncomp(conn_plant);
    blobs = blobInfo.PixelIdxList;
end

end
