%smooth edges of binary image with savitzky-golay filter method

%identify edges
image = leaves;
boundaries = bwboundaries(leaves);
for ii = 1:1:size(boundaries, 1)
    boundary = 