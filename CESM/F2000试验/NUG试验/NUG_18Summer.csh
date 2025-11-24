#!/bin/csh -fx

# ====================================================================
# 用户设置
# ====================================================================

# 1. 定义机器和编译器
setenv MACH hpcc
setenv CCSMTAG CESM2-release-2.1.0

# 2. 公共路径（不能改）
setenv CCSMROOT /share/home/minghuai/yliang/model/$CCSMTAG
setenv DATADIR  /share/home/minghuai/yliang/model/CESM_INPUT

# 3. 你的路径
setenv MY_ROOT  /share/home/ywliu/lxyyy
setenv CIME_OUTPUT_ROOT $MY_ROOT/scratch/runout

# 4. Case 名字
setenv CASE    NUG_1807_CTL
setenv CASEROOT $MY_ROOT/scratch/cesmrun/$CASE
setenv RUNDIR   $CIME_OUTPUT_ROOT/$CASE

# 5. SourceMods（如果没有就注释）
# setenv mymodscam $MY_ROOT/scripts/mycode/Lu2023_SourceMods

# ====================================================================
# 清理旧 Case
# ====================================================================

if ( -e ${CASEROOT} ) then
  rm -rf $CASEROOT
endif

if ( -e ${RUNDIR} ) then
  rm -rf $RUNDIR
endif

# ====================================================================
# 创建 new case
# ====================================================================

cd $CCSMROOT/cime/scripts

./create_newcase --case $CASEROOT --mach $MACH --res f09_f09_mg17 --compset F2000climo \
                 --compiler intel --queue mpi --walltime 01:00 --run-unsupported

cd $CASEROOT

# ====================================================================
# CAM 配置：必须加入 nudging 模块
# ====================================================================

# offline dynamics + nudging vertical levels
./xmlchange --file env_build.xml --append --id CAM_CONFIG_OPTS --val " -offline_dyn -nlev_nudge 32"

echo "-------------------------------------------------------"
echo "CHECK CAM_CONFIG_OPTS:"
./xmlquery CAM_CONFIG_OPTS
echo "-------------------------------------------------------"

# ====================================================================
# 路径设置
# ====================================================================

./xmlchange --file env_build.xml --id EXEROOT --val "${RUNDIR}/bld"
./xmlchange --file env_run.xml   --id RUNDIR  --val "${RUNDIR}/run"

# 日志与输出
./xmlchange --file env_run.xml --id DOUT_S --val 'FALSE'

# ====================================================================
# 设置实验时间（先跑 5 天测试）
# ====================================================================

./xmlchange --file env_run.xml --id RUN_STARTDATE --val '2018-07-01'
./xmlchange --file env_run.xml --id STOP_N        --val '5'
./xmlchange --file env_run.xml --id STOP_OPTION   --val 'ndays'

# ====================================================================
# 并行核心
# ====================================================================

set N = 48
set M = 48

./xmlchange --file env_mach_pes.xml --id NTASKS_ATM --val "$N"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ATM --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_ATM --val '0'

./xmlchange --file env_mach_pes.xml --id NTASKS_LND --val "$N"
./xmlchange --file env_mach_pes.xml --id NTASKS_ICE --val "$M"
./xmlchange --file env_mach_pes.xml --id NTASKS_OCN --val "$M"
./xmlchange --file env_mach_pes.xml --id NTASKS_CPL --val "$M"
./xmlchange --file env_mach_pes.xml --id NTASKS_GLC --val "$M"
./xmlchange --file env_mach_pes.xml --id NTASKS_ROF --val "$M"
./xmlchange --file env_mach_pes.xml --id NTASKS_WAV --val "$M"

# ====================================================================
# 链接 SourceMods
# ====================================================================

if ( $?mymodscam ) then
  if ( -d ${mymodscam} ) then
    echo "Linking SourceMods from ${mymodscam}"
    ln -s ${mymodscam}/* SourceMods/src.cam
  endif
endif

# ====================================================================
# 写 user_nl_cam
# ====================================================================

cat <<EOF >! user_nl_cam
&metdata_nl
  met_data_path       = '/share/home/minghuai/Liuym/DATA/MERRA2/CESM/0.9x1.25_32L/'    ! ←检查路径1
  met_filenames_list  = '/share/home/ywliu/lxyyy/data/Nudging_filenames/filenames_2000-2024_365.txt'  ! ←检查路径2
  met_nudge_u  = .true.
  met_nudge_v  = .true.
  met_nudge_t  = .false.
  met_nudge_q  = .false.
  met_nudge_ps = .false.
  met_rlx_time = 6
/

! 输出变量
&cam_history_nl
 avgflag_pertape = 'A'
 nhtfrq          = -24
 mfilt           = 30
 fincl1 = 'PRECT','T','U','V','U10','Q','Z3','PS',
          'AODVIS','AODDUST','AODBC','AODPOM','AODSO4',
          'CLDTOT','CDNUMC','FSNT','FLNT'
/
EOF

# ====================================================================
# case.setup + compile + submit
# ====================================================================

./case.setup

./case.build --clean-all
./case.build   --skip-provenance-check

./case.submit

date
