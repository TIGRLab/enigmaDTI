#!/bin/bash -l
##############################################################################
# Distortion Correction
#
# INPUT
# 1) Subject
# 2) Non-linear registration method 
# 3) BET Method
#
#
###############################################################################

#set -x
set -e

module load civet/1.1.10
module load minc-tools/2011.11
module load fsl/5.0.6
module load R/3.0.2-precise64
module load ENIGMA/master

# HORRIBLE HACK
PYTHONPATH=/usr/lib/pymodules/python2.7:${PYTHONPATH}

# Initialize Arguments
function usage() {
    echo
    echo "###############################################################"
    echo " Usage: $0 [OPTIONS]"
    echo "  -h    print help."
    echo "  -s    Subject ID to process."
    echo "  -m    Non-Linear Registration Method: ANTS, TRAC, FNIRT." 
    echo "  -b    BET Method (not-required), methods are equivalent."
    echo ""
    echo "Req:"
    echo "    ./T2.nii.gz"
    echo "    ./DTI_DIR60/DTI.nii.gz"
    echo "    ./DTI_DIR60/DTI.bvecs"
    echo "    ./DTI_DIR60/DTI.bvals"
    echo ""
    echo "###############################################################"
    exit
}

function help() {
    echo
    echo "Apply Distortion Correction: Snippet"
    echo "This script requires two inputs:"
    echo " " 
    echo " 1. The name of the current subject to process"
    echo " " 
    echo " 2. The name of non-linear registration method."
    echo " ANTS, FNIRT, TRAC."
    echo " " 
    exit
}

function transpose() {
    awk ' 
        { 
                if (max_nf<NF) 
                      max_nf=NF 
                max_nr=NR 
                for (x=1; x<=NF; ++x) 
                       vector[x, NR]=$x 
        } 
 
        END { 
                for (x=1; x<=max_nf; ++x) { 
                    for (y=1; y<=max_nr; ++y) 
                        printf("%s ", vector[x, y]) 
                    printf("\n") 
                } 
            }'  ${1} 
} 

while getopts ":m:s:b:h" OPT; do
    case ${OPT} in

        m)
            METHOD=${OPTARG}
            ;;
        s)
            SUB=${OPTARG}
            ;;
        b)
            BET=${OPTARG}
            ;;
        h)
            help
            exit 1
            ;;
        *)
            echo "Unknown option: ${OPT}"
            usage
            exit 1
            ;;

    esac
done

if [ ${OPTIND} -eq 0 ]; then
    echo "No options were passed"
    shift ${OPTIND}
    echo "$# non-option arguments"
    usage
    exit 1
else
    echo "$# option arguments"
fi

args="$@"
BET=FSL

if [ ${METHOD} == "ANTS" ]; then
    echo "####################################################################"
    echo "MINCANTS Distortion Correction, with ${BET} skull stripping"
    echo "####################################################################"

elif [ ${METHOD} == "TRAC" ]; then
    echo "####################################################################"
    echo "MINCTRACC Distortion Correction, with ${BET} skull stripping"
    echo "Warning: No restricted transformation for minctracc!"
    echo "####################################################################"

elif [ ${METHOD} == "FNIRT" ]; then
    echo "####################################################################"
    echo "FNIRT Distortion Correction, with ${BET} skull stripping"
    echo "####################################################################"

else
    echo "####################################################################"
    echo "A distortion correction METHOD should be specified"
    echo "WARNING: ANTS will be selected by default!"
    echo "####################################################################"

fi

echo "Distortion Correction ${METHOD}: Subject ${SUB}"
echo "####################################################################"

cd ${SUB}
DIRNAME=Distortion_Corrected_T_"${METHOD}"
echo ${DIRNAME}
mkdir ${DIRNAME}

###############################################################################
# DTI
#

cp DTI_DIR60/*.bv* ${DIRNAME}
cp DTI_DIR60/*.nii.gz ${DIRNAME}
cd ${DIRNAME}

# Split DTI volume
fslsplit *.nii.gz

# Conversion to MINC
for VOL in vol*nii*; do
    gunzip ${VOL}
    VOLUME=$(basename ${VOL} .nii.gz)

    # if [ ${BET} == "FSL" ]; then
    bet "${VOL}" "${VOLUME}"_bet -R -f 0.1
    gunzip "${VOLUME}"_bet.nii.gz
    nii2mnc "${VOLUME}"_bet.nii "${VOLUME}"_M.mnc
    
    # elif [ ${BET} = "MINC" ]; then
    #     nii2mnc "${VOL}".nii "${VOLUME}"_MINC.mnc
    #     mincbet "${VOLUME}"_MINC.mnc "${VOLUME}"_M
    
    # else
    #     echo "FSL BET Used as Default!"
    #     bet "${VOL}" "${VOLUME}"_bet -R -f 0.1
    #     gunzip "${VOLUME}"_bet.nii.gz
    #     nii2mnc "${VOLUME}"_bet.nii "${VOLUME}"_M.mnc
    # fi
done

###############################################################################
# T2
#
cp ../T2.nii.gz ./T2.nii.gz
gunzip T2.nii.gz
bet T2.nii T2_brain.nii -R

###############################################################################
# Register T2 to B-ZERO
#
flirt -interp sinc \
      -sincwidth 7 \
      -noresample \
      -noresampblur \
      -sincwindow blackman \
      -in T2_brain.nii \
      -ref vol0000.nii.gz \
      -nosearch \
      -o T2_REG \
      -omat T2_Trans.txt \
      -paddingsize 1 

gunzip T2_REG.nii.gz
nii2mnc T2_REG.nii T2_REG.mnc
cp T2_REG.nii T2_REG_F.nii
cp vol0000_M.mnc average_blur.mnc

# Select and Run Non-Linear Regsitration Algorithm 
if [ ${METHOD} == "ANTS"]; then 
    echo "Running ANTS Based Distortion Correction"
    echo '#! /bin/bash' > nonlin.sh
    echo "module load minc-tools/2011.11" >> nonlin.sh
    echo "mincANTS 3 -m MI[average_blur.mnc,T2_REG.mnc,1,4] --number-of-affine-iterations 20x20x10 --MI-option 32x16000 --Restrict-Deformation 0x1x0 --affine-gradient-descent-option 0.5x0.95x1.e-4x1.e-4 --use-Histogram-Matching -r Gauss[3,0] -t SyN[0.5] -o Average_OUTPUT.xfm -i 10x10" >> nonlin.sh

    chmod +x nonlin.sh
    ./nonlin.sh

elif [ ${METHOD} == "TRAC" ]; then
    echo "Running MINCTRACC Based Distortion Correction"
    echo '#! /bin/bash' > nonlin.sh
    echo "module load minc-tools/2011.11" >> nonlin.sh
    echo "nlfit_smr_modelless_trans_mod T2_REG.mnc average_blur.mnc Average_OUTPUT.xfm" >> nonlin.sh

    chmod +x nonlin.sh
    ./nonlin.sh

elif [ ${METHOD} == "FNIRT" ]; then
    echo "Running FNIRT Based Distortion Correction"
    echo '#! /bin/bash' > nonlin.sh
    echo "fnirt --ref=T2_REG_F.nii --in=vol0000.nii --iout=FNIRT_NL.nii --fout=field_xyz.nii" >> nonlin.sh
    echo "fslsplit field_xyz.nii NL" >> nonlin.sh
    echo "mv NL0001.nii.gz Y_deform.nii.gz" >> nonlin.sh
    echo "gunzip Y_deform.nii.gz" >> nonlin.sh
    echo "nii2mnc Y_deform.nii" >> nonlin.sh
    echo "cp Y_deform.mnc X.mnc" >> nonlin.sh
    echo "cp Y_deform.mnc Z.mnc" >> nonlin.sh
    echo "minccalc -expression "A[0]*0" X.mnc X_ZERO.mnc" >> nonlin.sh
    echo "minccalc -expression "A[0]*0" Z.mnc Z_ZERO.mnc" >> nonlin.sh
    echo "minccalc -expression "A[0]*-1" Y_deform.mnc Y_NEG.mnc" >> nonlin.sh
    echo "mincconcat -concat_dimension t X_ZERO.mnc Y_NEG.mnc Z_ZERO.mnc FNIRT_TRANSFORM.mnc" >> nonlin.sh

    chmod +x nonlin.sh
    ./nonlin.sh

else
    echo "You must specify a distortion correction method!"
    echo "Running ANTS Distortion Correction"
    echo '#! /bin/bash' > nonlin.sh
    echo "module load minc-tools/2011.11" >> nonlin.sh
    echo "mincANTS 3 -m MI[average_blur.mnc,T2_REG.mnc,1,4] --number-of-affine-iterations 20x20x10 --MI-option 32x16000 --Restrict-Deformation --affine-gradient-descent-option 0.5x0.95x1.e-4x1.e-4 --use-Histogram-Matching -r Gauss[3,0] -t SyN[0.5] -o Average_OUTPUT.xfm -i 10x10" >> nonlin.sh

    chmod +x nonlin.sh
    ./nonlin.sh

fi

###############################################################################
# Collect and clean transforms

# compute the actual linear registrations with MINC tools
parallel --gnu "bestlinreg \
                    -clobber \
                    -lsq12 {1} \
                    vol0000_M.mnc {1/.}.xfm ::: vol*_M.mnc"

# calculate some FSL linear registrations for QC purposesse
parallel --gnu "flirt \
                    -in {1/.}_bet.nii \
                    -ref vol0000_bet.nii \
                    -out {1/.}_flirted.nii.gz \
                    -paddingsize 1 \
                    -omat {1/.}_flirt.txt" ::: vol????.nii

# create full/formatted transform files
for VOL in vol*_M.mnc; do
    BASE=$(basename ${VOL} .mnc)

    echo "MNI Transform File" > ${BASE}_transform.xfm
    cat ${BASE}.xfm | tail -5 >> ${BASE}_transform.xfm
    echo "Transform_Type = Grid_Transform;" >> ${BASE}_transform.xfm
    echo "Displacement_Volume = FNIRT_TRANSFORM.mnc;" >> ${BASE}_transform.xfm
done
    
# Apply transforms, convert to NIFTI.GZ format
parallel --gnu "mincresample \
                    -sinc \
                    -width 2 \
                    -tfm \
                    -transformation {1/.}_transform.xfm {1} \
                    EPI_Trans_{1/.}.mnc" ::: vol????_M.mnc
parallel --gnu "mnc2nii \
                EPI_Trans_{1/.}.mnc \
                {1/.}_S.nii" ::: vol????_M.mnc

echo "########################################################################"
echo "Transformation Complete: Merging Files"
echo "########################################################################"

cat vol????_flirt.txt > transform.txt
transpose *.bvec > dirs_60.dat

## we need to have this accept an arbitrary number of directions
matlab -nojvm < /quarantine/ENIGMA/finitestrain.m
perl /quarantine/ENIGMA/dattonrrd.pl newdirs.dat newdirs.nhdr

cat newdirs.nhdr |cut -d " " -f 2 | tr '\n' ' ' > bvecs
echo '' >> bvecs
cat newdirs.nhdr | cut -d " " -f 3 | tr '\n' ' ' >> bvecs
echo '' >> bvecs
cat newdirs.nhdr | cut -d " " -f 4 | tr '\n' ' ' >> bvecs

fslmerge -t Distortion_Corrected vol????_M_S.nii
gunzip Distortion_Corrected.nii.gz

cp *.bval DWI.bval
cp bvecs DWI.bvec

# this is super ugly -- I'm calling a version of python that isn't in the minc 
# module this script depends on so I can import nibabel appropriately. The 
# best work-around will likely be a re-do of the minc-tools module.
#
# For now, uglyness. -- jdv

/usr/bin/python2.7 /quarantine/ENIGMA/nifti2nrrd -i Distortion_Corrected.nii

bet Distortion_Corrected.nii CORR -m -f 0.1
dtifit -k Distortion_Corrected.nii -m CORR_mask.nii.gz -b DWI.bval -r DWI.bvec -o CORR

# Exit distortion correction directory
echo "########################################################################"
echo "Making Sub Directories"
echo "########################################################################"

mkdir FA
mv CORR_FA.nii.gz FA/
cd FA


echo "########################################################################"
echo "Cleaning Temporary Files"
echo "########################################################################"

rm -rf vol*

#cd ..

# Submit script to queue.
# qsub -q main.q -cwd -V -N DIST_"$base" epi2epi.sh
#!/bin/bash 
 
