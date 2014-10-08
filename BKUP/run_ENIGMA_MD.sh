#!/bin/bash
#$ -S /bin/bash


#######
## part 1 - loop through all subjects to create a subject ROI file 
#######

#make an output directory for all files
mkdir MD_1
dirO1=./MD_1/

for subject in $( ls /projects/david/3T_DIST_CORR/REDUX/TBSS_FA/TBSS_MD_ALPHA/FA/ | grep FA_to_target_MD.nii.gz)

do
base=$(basename $subject _FA_FA_to_target_DISP.nii.gz);
echo "Basename $base"
./singleSubjROI_exe ENIGMA_look_up_table.txt mean_FA_skeleton_mask.nii.gz JHU-WhiteMatter-labels-1mm.nii.gz ${dirO1}${base}_ROIout /projects/david/3T_DIST_CORR/REDUX/TBSS_FA/TBSS_MD_ALPHA/FA/${subject}

done


#######
## part 2 - loop through all subjects to create ROI file 
##			removing ROIs not of interest and averaging others
#######

#make an output directory for all files
mkdir ENIGMA_ROI_STEP2_FW
dirO2=./ENIGMA_ROI_STEP2_FW/

# you may want to automatically create a subjectList file 
#    in which case delete the old one
#    and 'echo' the output files into a new name
rm ./subjectList.csv

for subject in $( ls ../FA | grep FA_to_target_FW_S.nii.gz)

do
base=$(basename $subject _FA_to_target_FW_S.nii.gz);
./averageSubjectTracts_exe ${dirO1}${base}_ROIout.csv ${dirO2}${base}_ROIout_avg.csv


# can create subject list here for part 3!
echo ${base},${dirO2}${base}_ROIout_avg.csv >> ./subjectList.csv
done


#######
## part 3 - combine all 
#######
Table=./ALL_Subject_Info_2.csv
subjectIDcol=subjectID
subjectList=./subjectList.csv
outTable=./combinedROItable.csv
Ncov=2
covariates="Age;Sex"
Nroi="all" #2
rois="IC;EC"

#location of R binary 
#Rbin=/usr/local/R-2.9.2_64bit/bin/R
Rbin=/quarantine/minc-tools/2012.01/x86_64/bin/R
#Run the R code
${Rbin} --no-save --slave --args ${Table} ${subjectIDcol} ${subjectList} ${outTable} ${Ncov} ${covariates} ${Nroi} ${rois} <  ./combine_subject_tables.R  
