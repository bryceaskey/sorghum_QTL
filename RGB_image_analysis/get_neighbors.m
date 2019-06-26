%function to get neighbor pixels
%input is a binary image, and pixel coordinates
%returns all pixels (connectivity = 8) == 1 around specified pixel
function [connections] = get_neighbors(bin_image, start_pixel)

connections = []; %array to store all connected pixels
for row = (start_pixel(1) - 1):1:(start_pixel(1) + 1)
    for col = (start_pixel(2) - 1):1:(start_pixel(2) + 1)
        if isequal([row, col], start_pixel) == 0 && bin_image(row, col) == 1
            connections = [connections; row, col];
        end
    end
end

end