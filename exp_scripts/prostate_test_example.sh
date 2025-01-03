#!/bin/bash

### GPU batch job ###
#SBATCH --job-name=csdg
#SBATCH --account=st-ilker-1-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --gpus=1
#SBATCH --mem=12G
#SBATCH --time=01:00:00
#SBATCH --output=outputs/%x-%j_output.txt
#SBATCH --error=outputs/%x-%j_error.txt
# #SBATCH --mail-user=alvinbk@student.ubc.ca
# #SBATCH --mail-type=ALL

#############################################################################

module load git

source ~/.bashrc
conda activate csdg
which python
echo ""

# GIN and IPA for prostate images
SCRIPT=dev_traintest_ginipa.py
GPUID1=0
NUM_WORKER=1
MODEL='efficient_b2_unet'
CPT='test_prostate'

# visualization
PRINT_FREQ=50000
VAL_FREQ=50000
TEST_EPOCH=50
EXP_TYPE='ginipa'

BSIZE=20
NL_GIN=4
N_INTERM=2

LAMBDA_WCE=1.0 # not using weights, actually standard multi-class ce
LAMBDA_DICE=1.0
LAMBDA_CONSIST=10.0 # Xu et al.

SAVE_EPOCH=1000
SAVE_PRED=True # save predictions or not

DATASET='PROSTATE'
CHECKPOINTS_DIR="./my_exps/$DATASET"
NITER=50
NITER_DECAY=1950
IMG_SIZE=192

OPTM_TYPE='adam'
LR=0.0003
ADAM_L2=0.00003
TE_DOMAIN="NA" # will be override by exclu_domain. take the rest of five domains for testing

# blender config
BLEND_GRID_SIZE=24
PHASE='test'

ALL_TRS=("A" "B" "C" "D" "E" "F") # repeat the experiment for different source domains. For the full set of experiments, use A B C D E F
NCLASS=2

# KL term
CONSIST_TYPE='kld'

for TR_DOMAIN in "${ALL_TRS[@]}"
do
    set -ex
    export CUDA_VISIBLE_DEVICES=$GPUID1

    NAME=${CPT}_tr${TR_DOMAIN}_exclude${TR_DOMAIN}_${MODEL}
    LOAD_DIR=$NAME

    RELOAD_MODEL="checkpoints/CAUSALDG_prostate_ginipa_example_tr${TR_DOMAIN}_exclude${TR_DOMAIN}_efficient_b2_unet/1/snapshots/latest_net_Seg.pth"

    python3 $SCRIPT with exp_type=$EXP_TYPE\
        name=$NAME\
        model=$MODEL\
        nThreads=$NUM_WORKER\
        print_freq=$PRINT_FREQ\
        validation_freq=$VAL_FREQ\
        batchSize=$BSIZE\
        lambda_wce=$LAMBDA_WCE\
        lambda_dice=$LAMBDA_DICE\
        save_epoch_freq=$SAVE_EPOCH\
        load_dir=$LOAD_DIR\
        infer_epoch_freq=$TEST_EPOCH\
        niter=$NITER\
        niter_decay=$NITER_DECAY\
        fineSize=$IMG_SIZE\
        lr=$LR\
        adam_weight_decay=$ADAM_L2\
        data_name=$DATASET\
        nclass=$NCLASS\
        tr_domain=$TR_DOMAIN\
        te_domain=$TE_DOMAIN\
        exclu_domain=$TR_DOMAIN \
        optimizer=$OPTM_TYPE\
        save_prediction=$SAVE_PRED\
        lambda_consist=$LAMBDA_CONSIST\
        blend_grid_size=$BLEND_GRID_SIZE\
        exclu_domain=$TR_DOMAIN\
        consist_type=$CONSIST_TYPE\
        display_freq=$PRINT_FREQ\
        gin_nlayer=$NL_GIN\
        gin_n_interm_ch=$N_INTERM\
        phase=$PHASE\
        reload_model_fid=$RELOAD_MODEL
done
