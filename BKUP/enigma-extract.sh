#!/bin/bash

# This script is a modification of the one used to extract data
# that were collected from the 1.5T scanner to accomodate extraction
# of data collected at CAMH. It has been further modified to accomodate
# 1) New FMRI protocol including imitate and observe runs
# 2) Maps directories directly from Name_Info.txt

# This script should be run from within the raw data directory. 

echo $PWD

args=("$@")
#echo arguments to the shell
#echo ${args[0]} ${args[1]} ${args[2]}
subject=$1

# Set Export Type for FSL
# Required for fslsplit
FSLOUTPUTTYPE=NIFTI_GZ
export FSLOUTPUTTYPE

# Make the Required directories
# Note that we now have three different DTI scans, and a resting state Functional MRI Scan.
mkdir T1 T2 PD DTI_b1000 DTI_b3000 DTI_b4500 DTI_DIR60 FLAIR FMRI_resting FMRI_observe FMRI_imitate TE6 TE8
mkdir ../$subject

# A text file "Name_Info.txt" includes a description of each dataset.
# Therefore filecounts as a means for identification should no longer
# be required. Furthermore, combinations of cat, grep and cut can be used
# to map directories directly rather than guessing, as they are not always
# consistant.

# Convert DCM 2 NIFTI for all series
for b in Ex*;
do
dcm2nii ${b}/*.dcm -o ${b}/;
dcm2mnc ${b}/*.dcm $PWD
done

T1_DIR=$(cat Name_Info.txt | grep BRAVO | cut -d " " -f 1)
echo "T1 Directory" $T1_DIR | tee > Directories.txt
T2_DIR=$(cat Name_Info.txt | grep DE | cut -d " " -f 1)
echo "T2 Directory" $T2_DIR | tee >> Directories.txt
FLAIR_DIR=$(cat Name_Info.txt | grep FLAIR | cut -d " " -f 1)
echo "FLAIR Directory" $FLAIR_DIR | tee >> Directories.txt
DTI60_DIR=$(cat Name_Info.txt | grep 60 | cut -d " " -f 1)
echo "DTI60 Directory" $DTI60_DIR | tee >> Directories.txt
FMRI_RESTING_DIR=$(cat Name_Info.txt | grep RestingState | cut -d " " -f 1)
echo "RESTING Directory" $FMRI_RESTING_DIR | tee >> Directories.txt
FMRI_OBSERVE_DIR=$(cat Name_Info.txt | grep Observe | cut -d " " -f 1)
echo "OBSERVE Directory" $FMRI_OBSERVE_DIR | tee >> Directories.txt
FMRI_IMITATE_DIR=$(cat Name_Info.txt | grep Imitate | cut -d " " -f 1)
echo "IMITATE Directory" $FMRI_IMITATE_DIR | tee >> Directories.txt
DTI_b1000_DIR=$(cat Name_Info.txt | grep b1000 | cut -d " " -f 1)
echo "B1000 Directory" $DTI_b1000_DIR | tee >> Directories.txt
DTI_b3000_DIR=$(cat Name_Info.txt | grep b3000 | cut -d " " -f 1)
echo "B3000 Directory" $DTI_b3000_DIR | tee >> Directories.txt
DTI_b4500_DIR=$(cat Name_Info.txt | grep b4500 | cut -d " " -f 1)
echo "B4500 Directory" $DTI_b4500_DIR | tee >> Directories.txt
TE6_DIR=$(cat Name_Info.txt | grep Field | grep TE6 | cut -d " " -f 1)
echo "TE6" $TE6_DIR | tee >> Directories.txt
TE8_DIR=$(cat Name_Info.txt | grep Field | grep TE8 | cut -d " " -f 1)
echo "TE8" $TE8_DIR | tee >> Directories.txt
echo "$PWD" >> Directories.txt


# Copy T1.nii from Se04 into the T1 directory
if [ -z "$T1_DIR" ]; then
echo "No T1 DIR"
else
cd $T1_DIR
T1NII=$(ls | grep 201[0-9] | sed -n '1p')
echo $T1NII
# Copy NIFTI to T1
if [ -z "$T1NII" ] ; then
echo "No T1 NIFTI Found"
else
cp $T1NII ../T1/"$subject".nii.gz
gunzip ../T1/"$subject".nii.gz
nii2mnc -sagittal -flipx -flipy  ../T1/"$subject".nii "$subject".mnc 
fi
cd ..
fi

# Copy DTI B=4500
if [ -z "$DTI_b4500_DIR" ]; then
echo "No DTI 4500 DIR"
else
cd $DTI_b4500_DIR
cp -r * ../DTI_b4500/
#cp *.nii.gz ../DTI_b4500/
#cp *.bvec ../DTI_b4500/
#cp *.bval ../DTI_b4500/
cd ..
fi

# Copy DTI B=3000
if [ -z "$DTI_b3000_DIR" ]; then
echo "No DTI 3000 DIR"
else
cd $DTI_b3000_DIR
cp -r * ../DTI_b3000/
#cp *.nii.gz ../DTI_b3000/
#cp *.bvec ../DTI_b3000/
#cp *.bval ../DTI_b3000/
cd ..
fi

# Copy DTI B=1000
if [ -z "$DTI_b1000_DIR" ]; then
echo "No DTI 1000 DIR"
else
cd $DTI_b1000_DIR
cp -r * ../DTI_b1000/
#cp *.nii.gz ../DTI_b1000/
#cp *.bvec ../DTI_b1000/
#cp *.bval ../DTI_b1000/
cd ..
fi

# Enter into T2 directory
# NOTE T2 and PD extract separately via dcm2nii command
# fslsplit, is not required for these data
cd $T2_DIR
T2NII=$(ls | grep .nii.gz )
echo $T2NII
OR2=$( ls | grep a1001.nii.gz)
if [ -z "$OR2" ]; then
echo "OR2 Does not exit"
#fslsplit $T2NII
mv *0000.nii.gz ../PD/PD.nii.gz
mv *0001.nii.gz ../T2/T2.nii.gz
else
echo "Splitting T2_PD File"
fslsplit $OR2
mv *0000.nii.gz ../PD/PD.nii.gz
mv *0001.nii.gz ../T2/T2.nii.gz
fi

cd ..

# Move contents of FLAIR

if [ -z "$FLAIR_DIR" ]; then
echo "No FLAIR"
else
cd $FLAIR_DIR
cp -r * ../FLAIR
cd ..
fi

# Move contents of 60 Direction DTI
if [ -z "$DTI60_DIR" ]; then
echo "No DTI60"
else
cd $DTI60_DIR
cp -r * ../DTI_DIR60
cd ..
fi

# Move contents of FMRI_Imitate
if [ -z "$FMRI_IMITATE_DIR" ]; then
echo "No FMRI IMITATE"
else
cd $FMRI_IMITATE_DIR
cp -r * ../FMRI_imitate
cd ..
fi

# Move contents of FMRI_Resting
if [ -z "$FMRI_RESTING_DIR" ]; then
echo "No FMRI RESTING"
else
cd $FMRI_RESTING_DIR
cp -r * ../FMRI_resting
cd ..
fi

# Move contents of FMRI_Observe
if [ -z "$FMRI_OBSERVE_DIR" ]; then
echo "No FMRI OBSERVE"
else
cd $FMRI_OBSERVE_DIR
cp -r * ../FMRI_observe
cd ..
fi

# Extract and move field map data:

if [ -z "$TE6" ]; then
echo "No TE 6.5 Phase Map"
else
cd $TE6_DIR
cp -r * ../TE6/
cd ..
fi

if [ -z "$TE8" ]; then
echo "No TE 8.5 Phase Map"
else
cd $TE8_DIR
cp -r * ../TE8/
cd ..
fi



# Move data into a subject folder
# Easiest to Copy ALL for records
# then move with transfer script
# to specific data directory
#mkdir ../$subject
cp -r * ../$subject/


