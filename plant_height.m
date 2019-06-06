%calculate plant height from segmented image

%input image is a 3d matrix
%first two dimensions describe location

%third dimension designates organ classification:
%background = 0
%leaves = 1
%stalk = 2
%panicle = 3

function [overall_height, stem_height, panicle_height] = plant_height(filename)
image = readmatrix(filename);
stem_top = 


end