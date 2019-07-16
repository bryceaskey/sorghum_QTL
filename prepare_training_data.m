%prepare training data
training_data = readmatrix('Desktop/training_data.csv');

%delete band labels in first row
training_data(1, :) = [];

%delete all rows classified as background -> will be removed with NDVI threshold
[height, width] = size(training_data);
x = training_data(:, 1) == 0;
training_data(x, :) = [];