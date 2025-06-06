#! /bin/bash
set -e # exit on error
trap "echo ERROR in $0. Rerun with 'bash -vx $0' to debug" ERR

## scatter settings
export num_scat_iters=3
## recon settings during scatter estimation
# adjust for your scanner (needs to divide number of views/4 as usual)
export scatter_recon_num_subsets=3
# keep num_scatter_iters*scatter_recon_num_subiterations relatively small as everything is at low resolution
export scatter_recon_num_subiterations=7

 
# set some initial variable such that the rest of the script is
# the same for all runs
ctac=CTAC.hv
output_suffix=_run
   
# run scatter in a subdirectory
rm -rf scatter${output_suffix}
mkdir -p scatter${output_suffix}
cd scatter${output_suffix}

## filenames for input
export sino_input=../my_prompts.hs
export atnimg=../${ctac}
export NORM=../my_norm.hs
export randoms3d=../my_randoms.hs
## filenames for output
export acf3d=my_acfs.hs
export scatter_prefix=scatter
export total_additive_prefix=addsino
# internal scatter variables. ignore
export mask_projdata_filename=mask.hs
export mask_image=mask_image.hv

echo "compute attenuation correction factors"
if [ -r ${acf3d} ]; then
    echo "Re-using existing ${acf3d}"
else
    calculate_attenuation_coefficients --ACF ${acf3d} ${atnimg} ${sino_input} ../forward_projector_proj_matrix_ray_tracing.par
fi

echo "Estimating scatter"
estimate_scatter ../scatter_estimation.par >& estimate_${scatter_prefix}.log

echo "Running OSEM with scatter estimate"
INPUT=${sino_input} \
MULTFACTORS=../my_multfactors.hs \
ADDSINO=${total_additive_prefix}_${num_scat_iters}.hs \
OUTPUT=OSEM_recon_with_estimated_scatter OSMAPOSL ../OSEM_full.par

echo "Running OSEM with actual scatter"
INPUT=${sino_input} \
MULTFACTORS=../my_multfactors.hs \
ADDSINO=../my_additive_sinogram.hs \
OUTPUT=OSEM_recon_with_actual_scatter OSMAPOSL ../OSEM_full.par

stir_math -s ../scatter_estimate${output_suffix}.hs ${scatter_prefix}_${num_scat_iters}.hs

if false; then
echo "Precorrect data for FBP"
INPUT=${sino_input} OUTPUT=precorrected.hs \
MULTFACTORS=../my_multfactors.hs \
ADDSINO=${total_additive_prefix}_${num_scat_iters}.hs \
correct_projdata ../correct_projdata.par
echo "Running FBP"
INPUT=precorrected.hs \
OUTPUT=FBP_recon_with_scatter_correction FBP2D ../FBP2D_full.par
stir_math ../FBP_recon_with_scatter_correction${output_suffix}.hv FBP_recon_with_scatter_correction.hv
fi

echo DONE
