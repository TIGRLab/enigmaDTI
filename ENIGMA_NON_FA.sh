#!/bin/bash -l
#$ -S /bin/bash

# Generalized October 2nd David Rotenberg.
#######
## part 1 - loop through all subjects to create a subject ROI file 
#######
#make an output directory for all files


function usage() {
  echo
  echo "###############################################################"
  echo " Usage: $0 [OPTIONS]"
  echo "  -h    print help."
  echo "  -t    Define Metric Name (FA, FA_CORR, FW, MD)."
  echo "  -d    Directory where FA/...to_target...nii.gz are located." 
  echo "###############################################################"
  exit
}

function help() {
  echo
  echo "Apply Distortion Correction: Snippet"
  echo "This script requires two inputs:"
  echo " " 
  echo " 1. Type of Data."
  echo " FA, FA_CORR, FW, MD (...)"
  echo " "
  echo " 2. Dataset Name."
  echo " "
  echo " /////////////////////////////" 
  exit
}

while getopts ":h" opt; do
  case $opt in
    h)
      help
      exit 1
      ;;
    *)
      echo "Unknown option: $opt"
      usage
      exit 1
    ;;
  esac
done

if [ $OPTIND -eq 0 ]; then
   echo "No options were passed"
   shift $OPTIND
   echo "$# non-option arguments"
   usage
   exit 1
else
   echo "$# option arguments"
fi

echo  "Default Type = FA"

ENIGMA_DIR=/quarantine/ENIGMA

mkdir ${typed}_to_target
mkdir ${typed}_skels

echo "TBSS STEP 1"
tbss *.nii.gz

echo "TBSS_STEP 2"
tbss_2_reg -t ${ENIGMA_DIR}/ENIGMA_DTI_FA.nii.gz

pause_crit=$( qstat | grep tbss_2_reg);

while [ -n "$pause_crit" ];
do
    pause_crit=$( qstat | grep tbss_2_reg)
    sleep 20
done
echo "Registration Complete"

echo "TBSS STEP 3"
tbss_3_postreg -S

cp FA/*FA_to_target.nii.gz FA_to_target/ && cd FA_to_target

for a in *; 
do tbss_skeleton -i ${ENIMGA_DIR}/ENIGMA_DTI_FA.nii.gz -p 0.049 ${ENIGMA_DIR}ENIGMA_DTI_FA_skeleton_mask_dst.nii.gz /usr/share/data/fsl-mni152-templates/LowerCingulum_1mm.nii.gz ${a} ${a}_FAskel -s ${ENIGMA_DIR}/ENIGMA_DTI_FA_skeleton_mask.nii.gz
done

cp *skel* ../FA_skel/ && cd ../FA_skel

for sub in * ;
do 
fslmaths $sub -mul 1 $sub -odt float
done

cd ..

mkdir ${dataset}_${typed}
dirO1=./${dataset}_${typed}/



for subject in $( ls FA_skel | grep .nii.gz)

do

base=$(basename $subject .nii.gz);
echo "Basename $base"
${ENIMGA_DIR}/singleSubjROI_exe ${ENIGMA_DIR}/ENIGMA_look_up_table.txt ${ENIGMA_DIR}/mean_FA_skeleton_mask.nii.gz ${ENIGMA_DIR}/JHU-WhiteMatter-labels-1mm.nii.gz ${dirO1}${base}_ROIout FA_skel/${subject}

done


#######
## part 2 - loop through all subjects to create ROI file 
##			removing ROIs not of interest and averaging others
#######

#make an output directory for all files
mkdir ${dataset}_${typed}_2
dirO2=./${dataset}_${typed}_2/


# you may want to automatically create a subjectList file 
#    in which case delete the old one
#    and 'echo' the output files into a new name
rm ./subjectList.csv

for subject in $( ls FA_skel/ | grep .nii.gz)

do
base=$(basename $subject .nii.gz);
${ENIGMA_DIR}//averageSubjectTracts_exe ${dirO1}${base}_ROIout.csv ${dirO2}${base}_ROIout_avg.csv


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
Rbin=/quarantine/R/3.0.2/12.04/bin/R
#Run the R code
${Rbin} --no-save --slave --args ${Table} ${subjectIDcol} ${subjectList} ${outTable} ${Ncov} ${covariates} ${Nroi} ${rois} <  ./combine_subject_tables.R  
