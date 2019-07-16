% function [...] = pixel_classification(filepath)
clc; clear;

filepath = 'Desktop/training_data.csv';
if ~isfile(filepath)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s', filepath);
    uiwait(warndlg(errorMessage));
    return;
end

data = readmatrix(filepath);
data(1, :) = [];

[height, width] = size(data);
