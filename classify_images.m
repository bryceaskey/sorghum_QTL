%ignore bands 0_0_0 and 0_0_1
clc; clear;
directory = 'Desktop/SorghumSeedImages/SorghumImages/1-26-18_Sorghum_seed_915-001-PI 658758_2018-02-07_02-23-34_6994600/Hyp_SV_90';
if ~isfolder(directory)
    error_message = sprintf('Error: The following folder does not exist:\n%s', directory);
    uiwait(warndlg(error_message));
    return;
end
file_pattern = fullfile(directory, '*.png');
bands = dir(file_pattern);

band_names = cell(length(bands), 3);

%create cell array of band filenames
for band_count = 1:1:length(bands)
    band_names{band_count, 2} = bands(band_count).name;
    band_names{band_count, 1} = str2double(strtok(bands(band_count).name, '_'));
    band_names{band_count, 3} = strcat(bands(band_count).folder, '/', bands(band_count).name);
end

%sort by band number, and delete bands 0_0_0 and 0_0_1
band_names = sortrows(band_names, 1);
band_names(1:2, :) = [];

%load hyperspectral data into (n x m) x 243 array for classification
[height, width, pages] = size(imread(band_names{1, 3}));
all_pixels = zeros(height*width, 243);
for band_count = 1:1:length(band_names)
    pixel_count = 0;
    band = double(imread(band_names{band_count, 3}));
    band(:, :, 2:3) = [];
    for row = 1:1:height
        for col = 1:1:width
            pixel_count = pixel_count + 1;
            all_pixels(pixel_count, band_count) = band(row, col);
        end
    end
end

%load trained classification model into workspace
load('Documents/MATLAB/QuadraticSVM.mat');

%image classification with previously trained model
output = zeros(height, width);
pixel_count = 0;
for row = 1:1:height
    for col = 1:1:width
        pixel_count = pixel_count + 1;
%         A770 = all_pixels(pixel_count, 48);
%         A670 = all_pixels(pixel_count, 27);
%         NDVI = (A770 - A670)/(A770 + A670);
%         if NDVI < 0.50 %separate background with NDVI threshold
%             output(row, col) = 0;
%         else
        output(row, col) = QuadraticSVM.predictFcn(all_pixels(pixel_count, :));
    end
end
