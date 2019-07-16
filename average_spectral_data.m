function [average_spectra] =  average_spectral_data(filepath);

if ~isfile(filepath)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s', filepath);
    uiwait(warndlg(errorMessage));
    return;
end

data = readmatrix(filepath);
[height, width] = size(data);

background = data(1, :);
leaves = data(1, :);
stalk = data(1, :);
panicle = data(1, :);

for pixel = 2:1:height
    if data(pixel, 1) == 0 %background
        background = [background; data(pixel, :)];
    elseif data(pixel, 1) == 1 %leaves
        leaves = [leaves; data(pixel, :)];
    elseif data(pixel, 1) == 2 %stalk
        stalk = [stalk; data(pixel, :)];
    else %panicle
        panicle = [panicle; data(pixel, :)];
    end
end

%initialize array to hold average spectral data
average_spectra = zeros(5, width);
average_spectra(1, :) = data(1, :);
average_spectra(2, 1) = 0;
average_spectra(3, 1) = 1;
average_spectra(4, 1) = 2;
average_spectra(5, 1) = 3;

for band = 2:1:width
    average_spectra(2, band) = mean(background(:, band));
    average_spectra(3, band) = mean(leaves(:, band));
    average_spectra(4, band) = mean(stalk(:, band));
    average_spectra(5, band) = mean(panicle(:, band));
end

end