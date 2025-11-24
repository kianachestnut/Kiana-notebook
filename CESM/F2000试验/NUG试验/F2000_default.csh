#!/bin/csh -fx

# Zhun Guo, zhun.guo@pnnl.gov; guozhun@lasg.iap.ac.cn
# Modified by yhzhang 2025.03.12
# To output albedo

# ====================================================================
# define directories
# ====================================================================

setenv MACH hpcc
setenv CCSMTAG CESM2-release-2.1.0
setenv CCSMROOT /share/home/minghuai/yliang/model/$CCSMTAG
setenv DATADIR  /share/home/minghuai/yliang/model/CESM_INPUT
# setenv PTMP  $CSCRATCH/CASES_SPCAM/$CASE

# ====================================================================
# case-specific stuff
# ====================================================================

setenv CASE    F2000_default
setenv CIME_OUTPUT_ROOT /share/home/ywliu/lxyyy/scratch/runout
setenv CASEROOT /share/home/ywliu/lxyyy/scratch/cesmrun/$CASE
setenv RUNDIR   $CIME_OUTPUT_ROOT/$CASE

# ====================================================================
# create new case, configure, compile and run
# ====================================================================

if ( -e ${CASEROOT} ) then
    rm -rf $CASEROOT
endif

if ( -e ${RUNDIR} ) then
    rm -rf $RUNDIR
endif

# ----------------------------------
# create new case
# ----------------------------------

cd $CCSMROOT/cime/scripts

./create_newcase --case $CASEROOT --mach $MACH --res f09_f09_mg17 --compset F2000climo \
                 --compiler intel --queue mpi --walltime 01:00 --run-unsupported

# ----------------------------------
# set environment
# ----------------------------------

cd $CASEROOT

#./xmlchange CAM_CONFIG_OPTS="-phys cam6 -chem trop_mam4 -offline_dyn -nlev 32"

./xmlchange --file env_build.xml --id EXEROOT --val "${RUNDIR}/bld"
./xmlchange --file env_run.xml   --id RUNDIR  --val "${RUNDIR}/run"
./xmlchange --file env_run.xml   --id DOUT_S  --val 'FALSE'
#./xmlchange --file env_run.xml   --id DOUT_S_ROOT          --val "${RUNDIR}/archive"
#./xmlchange --file env_run.xml   --id DIN_LOC_ROOT         --val  $DATADIR
#./xmlchange --file env_run.xml   --id DIN_LOC_ROOT_CLMFORC --val "$DATADIR/atm/datm7"


# edit env_batch.xml
# ./xmlchange --file env_batch.xml --id JOB_QUEUE          --val 'mpi'
# ./xmlchange --file env_batch.xml --id JOB_WALLCLOCK_TIME --val '01:00'

set N = 48
set M = 48

./xmlchange --file env_mach_pes.xml --id NTASKS_ATM --val "$N"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ATM --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_ATM --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_LND --val "$N"
./xmlchange --file env_mach_pes.xml --id NTHRDS_LND --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_LND --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_ICE --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ICE --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_ICE --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_OCN --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_OCN --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_OCN --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_CPL --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_CPL --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_CPL --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_GLC --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_GLC --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_GLC --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_ROF --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ROF --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_ROF --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_WAV --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_WAV --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_WAV --val '0'

./xmlchange --file env_mach_pes.xml --id NTHRDS_ESP --val '1'


cd $CASEROOT

##----- To modify source code-----
#if ( -e ${mymodscam} ) then
#  ln -s ${mymodscam}/* SourceMods/src.clm # put your mods in here
#endif


cd $CASEROOT
# ----------------------------------
# configure
# ----------------------------------


./xmlchange --file env_run.xml --id RUN_STARTDATE --val '2000-01-01'
./xmlchange --file env_run.xml --id RESUBMIT      --val '0'
./xmlchange --file env_run.xml --id STOP_N        --val '3'
./xmlchange --file env_run.xml --id STOP_OPTION   --val 'ndays'
./xmlchange --file env_run.xml --id REST_N        --val '1'
./xmlchange --file env_run.xml --id REST_OPTION   --val 'ndays'
#./xmlchange --file env_run.xml --id ATM_NCPL --val '11
#./xmlchange --file env_run.xml --id INFO_DBUG  --val '3'
#./xmlchange --file env_run.xml --id PIO_DEBUG_LEVEL --val '4'


####--------------------------
##Modifying namelistsi of CAM6
####--------------------------

echo "user_nl_cam"
cat <<EOF >! user_nl_cam

!& camexp

!npr_yz          = 8, 4, 4, 8

avgflag_pertape = 'A'!,'A'!,'A'! !A:average; L:local time

nhtfrq          = -24!, 0 !,-24 !write frequency, 0:monthly average; -24: daily; -1:hourly
mfilt           = 1  !, 1 ! !maximum number of time samples

fincl1 = 'PRECT','T','U','V','U10'
!fincl2 =  'TMdst_a1', 'TMdst_a2', 'TMdst_a3','a2x_DSTWET1','a2x_DSTDRY1', 'a2x_DSTWET2', 'a2x_DSTDRY2', 'a2x_DSTWET3','a2x_DSTDRY3','a2x_DSTWET4','a2x_DSTDRY4','dst_a2SF','dst_a1SF', 'dst_a3SF','DSTSFMBL', 'dst_a1DDF', 'dst_a2DDF', 'dst_a3DDF','dst_c1DDF', 'dst_c2DDF', 'dst_c3DDF', 'dst_a1SFWET' ,'dst_a2SFWET', 'dst_a3SFWET', 'dst_c1SFWET', 'dst_c2SFWET', 'dst_c3SFWET', 'CT_dst_a1', 'CT_dst_a2', 'CT_dst_a3', 'SFdst_a1', 'SFdst_a2', 'SFdst_a3', 'AODDUST1', 'AODdnDUST1', 'AODDUST2', 'AODdnDUST2', 'AODDUST3', 'AODdnDUST3', 'AODDUST4', 'AODdnDUST4', 'AODDUST', 'AODDUSTdn', 'BURDENDUST', 'BURDENDUSTdn','dst_a1','dst_a2','dst_a3', 'dst_c1', 'dst_c2',  'dst_c3','num_a2SF', 'num_a1SF', 'num_a3SF','DF_dst_a1','DF_dst_a2','DF_dst_a3','dst_a1_SRF',  'dst_a2_SRF','dst_a3_SRF'
                                                                                                   

&cam_initfiles_nl
bnd_topo = '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/topo/fv_0.9x1.25_nc3000_Nsw042_Nrs008_Co060_Fi001_ZR_sgh30_24km_GRNL_c170103.nc'
ncdata	= '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/inic/fv/f.e20.FCSD.f09_f09_mg17.cesm2.1-exp002.001.cam.i.2005-01-01-00000_c180801_32L.nc'
/

!&metdata_nl
! met_data_file          = '2000/MERRA2_0.9x1.25_20000101.nc'
! met_data_path          = '/share/home/minghuai/Liuym/DATA/MERRA2/CESM/0.9x1.25_32L/'
! met_filenames_list     = '/share/home/ywliu/yhzhang/data/Nudging_filenames/filenames_2000-2024_365.txt'
! met_rlx_time           = 0.0 
/
EOF



# submit and run scripts
cd $CASEROOT
./case.setup

./case.build --clean-all

./case.build --skip-provenance-check

./case.submit

date
