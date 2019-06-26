clc; clear; close all

[image, all_plant, stake, stake_bin] = stake_segmentation('Documents/MATLAB/RGB_test3.png');

[panicle_row, panicle_col] = panicle_identification(all_plant, image, stake, stake_bin);