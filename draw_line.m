%given two points, draw line on input image connecting points
function [output_image] = draw_line(input_image, point1, point2, line_width)

if point1(1) <= point2(1) %determine which point is higher - starting point for line
    start_row = point1(1);
    end_row = point2(1);
    if point1(2) <= point2(2)
        start_col = point1(2);
        end_col = point2(2);
    else
        start_col = point2(2);
        end_col = point1(2);
    end
else
    start_row = point2(1);
    end_row = point1(1);
    if point1(2) <= point2(2)
        start_col = point1(2);
        end_col = point2(2);
    else
        start_col = point2(2);
        end_col = point1(2);
    end
end

%need to add conditional - if points are directly above/below each other -
%slope will be undefined


line = polyfit([end_row, start_row], [start_col, end_col], 1);
output_image = input_image;

for row = start_row:1:end_row
    for col = start_col:1:end_col
        pixel_row = round(line(1)*row + line(2));
        pixel_col = row;
        for line_row = (pixel_row - floor(line_width/2)):1:(pixel_row + ceil(line_width/2))
            for line_col = (pixel_col - floor(line_width/2)):1:(pixel_col + ceil(line_width/2))
                output_image(line_col, line_row) = 1;
            end
        end
    end
end
output_image(point1(1), point1(2)) = 1;
output_image(point2(1), point2(2)) = 1;

end