ENIGMA QC Pipeline for DTI Acquisitions
---------------------------------------

See here http://enigma.ini.usc.edu/ongoing/dti-working-group/ for details, and the originators of this project.

This pipeline takes an input FA map from a DTI acquisition and reports (!!!Spooky Various Things!!!) about your DTI data.

This project was mostly produced by David Rotenberg, [the Rotenator](mailto:david.rotenberg@camh.ca).


Instructions
------------

This code will print out the average FA value along a skeleton and ROI values on that skeleton according to an ROI atlas, for example the JHU-ROI atlas (provided with this code).

The look up table for the atlas should be tab-delimited --  the first column should refer to the voxel value within the image and the second column should refer to the desired label of the region.

    ./singleSubjROI_exe look_up_table.txt skeleton.nii.gz JHU-WhiteMatter-labels-1mm.nii.gz OutputfileName Subject_FAskeleton.nii.gz
	
Example:
 
    ./singleSubjROI_exe ENIGMA_look_up_table.txt mean_FA_skeleton.nii.gz JHU-WhiteMatter-labels-1mm.nii.gz Subject*_ROIout Subject*_FA.nii.gz
