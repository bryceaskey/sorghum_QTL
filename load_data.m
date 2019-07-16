%function to reduce hyperspectral data
%function [reduced_data] = load_data(filepath);
filepath = '/home/schnable/Desktop/training_data.csv';
if ~isfile(filepath)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s', filepath);
    uiwait(warndlg(errorMessage));
    return;
end

data = readmatrix(filepath);
[height, width] = size(data);
spectral_data = data(2:height, 2:width); %predictors
classification = data(2:height, 1); %response

model = fscnca(spectral_data, classification);

percentile = 97;
cutoff = prctile(model.FeatureWeights, percentile);
reduced = data;

for band = width-1:-1:1
    if model.FeatureWeights(band) < cutoff
        reduced(:, band) = [];
    end
end

%end