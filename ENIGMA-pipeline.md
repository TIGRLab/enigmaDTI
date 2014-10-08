DTI Quick Start
---------------

To properly generate FA maps, TBSS, and ENIGMA QC for each DTI acquisition, you need the following:
    
    ./SUBJECT/T2.nii.gz
    ./SUBJECT/DTI_60DIR/DTI.nii.gz
    ./SUBJECT/DTI_60DIR/DTI.bvecs
    ./SUBJECT/DTI_60DIR/DTI.bvals

Then, run something like this (from the folder containing all the subjects):

1) enigma-gen-fa.sh -s ${SUBJECTNAME} -m FNIRT
2) enigma-main.sh
3) enigma-extract.sh

Full Pipeline
-------------

1) DWI Preprocessing
You can call DIST_CORR.sh as follows:

./DIST_CORR.sh -s (SUBJECT) -m (FNIRT) -b (FSL)

Here, SUBJECT can be anything, however the script expects a sub-directory DTI_DIR60. 

This subdirectory should contain one .nii.gz and  a .bval and .bvec file. It doesnt matter if there are DICOMS present as well. 

In addition to the DTI_DIR60 directory, there must be a T2.nii.gz file directly within the subjects directory. 

Other than this, you should have the correct modules for FSL and MINC loaded that currently work in your environment for the registrations commands required by the script. 

NOTE: If this gives you any trouble at all, we can use a more rudimentary eddy_correct script 

2) ENIGMA

The ENIGMA master script can be first referenced using a new module (ENIGMA) which you can load into your environment. This script should be called directly, from any directory that contains (only) the FA maps in .nii.gz or .nii format. TBSS should run to completion and the ENIGMA regions of interest should be extracted.

3) EXTRACTION Script 

The extraction script has a higher level, but I will ignore this for the time being as that is the part you will be modifying. I have attached one of the current extraction scripts for DTIG1MR, that uses the included text file to match up the series and scan types. It may not be useful in and of itself, but it should indicate how things are currently structured. 

Let me know if you have any questions!

 
ENIGMA DTI extraction protocol (April 10, 2014)
-----------------------------------------------
 
REQUIRED:
 
ENIGMA FA average, mask, skeleton, skeleton mask, and distance map (are all found in “/home/dan/Downloads/enigmaDTI”).
 
Each subject to be analyzed must be preprocessed using /dti/Merged_data/Scripts/TBSS_Preproc (for 3 repetitions) or /dti/Merged_data/Scripts/tbss_preproc (for single repetition), as the input for step 1 requires an FA map for each subject.
 
1. Perform TBSS on all subjects FA maps as follows:
 
tbss_1_preproc *.nii.gz
 
tbss_2_reg -t ENIGMA_DTI_FA.nii.gz 
 
tbss_3_postreg -S
 
2. Extract registered FA maps from “FA/” directory (*FA_to_target.nii.gz*) and place in new 
 
directory (“FA_to_target/”)
 
3. cd into “FA_to_target/” and skeletonize each registered FA map as follows:
 
for a in *; do tbss_skeleton 
 
-i ENIGMA_DTI_FA.nii.gz 
 
-p 0.049 
 
ENIGMA_DTI_FA_skeleton_mask_dst.nii.gz
 
/usr/share/fsl/4.1/data/standard/LowerCingulum_1mm.nii.gz 
 
${a} 
 
${a}_FAskel 
 
-s ENIGMA_DTI_FA_skeleton_mask.nii.gz ; 
 
done
 
#NOTE: the ENIGMA* templates in the above script may not be in the current working directory (i.e. 
 
“FA_to_target/”), so ensure that where they are referenced (lines 3, 5, and 9), you provide a full 
 
pathname so that the script can find the template in your file system.
 
5. mv new FA skeletons (*_FAskel.nii.gz*) to a new directory (“FA_skels/”)
 
6. Perform ROI extraction using modified run_ENIGMA_ROI_ALL_script.sh found 
 
in “/projects/dan/ROIextraction_info”, by changing datapath (line 15 in run_ENIGMA_ROI_ALL_script.sh) to “FA_skels” (make sure to include full path name)
 
7. .csv files containing FA values for each ENIGMA ROI will be contained in the  “ENIGMA_ROI_part1” directory in “/projects/dan/ROIextraction_info”
