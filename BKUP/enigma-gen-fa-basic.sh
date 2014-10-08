#!/bin/bash

# eddy-current correct DTI image
eddy_correct *.nii.gz eddy_corrected.nii.gz 0

# create brain mask
bet eddy_corrected.nii.gz brain -m -f 0.1

# fit DTI data
dtifit -k eddy_corrected.nii.gz \
       -m brain_mask.nii.gz \
       -b *.bval \
       -r *.bvec \
       -o CORR
