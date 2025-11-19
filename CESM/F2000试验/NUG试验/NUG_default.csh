#!/bin/csh -fx

# ====================================================================
# 用户设置部分 (User Defined)
# ====================================================================

# 1. 定义机器和编译器环境
setenv MACH hpcc
setenv CCSMTAG CESM2-release-2.1.0

# 2. 定义不能动的公共路径
setenv CCSMROOT /share/home/minghuai/yliang/model/$CCSMTAG
setenv DATADIR  /share/home/minghuai/yliang/model/CESM_INPUT

# 3. 定义自己的路径
setenv MY_ROOT  /share/home/ywliu/lxyyy  
setenv CIME_OUTPUT_ROOT $MY_ROOT/scratch/runout

# 4. 定义Case名字 
setenv CASE    F2000_1807_NUG
setenv CASEROOT $MY_ROOT/scratch/cesmrun/$CASE
setenv RUNDIR   $CIME_OUTPUT_ROOT/$CASE

# 5. 定义源代码路径 (如果你有改好的Fortran代码，放在这里)
# 如果暂时没有，可以先注释掉 setenv mymodscam 这一行
# setenv mymodscam $MY_ROOT/scripts/mycode/Lu2023_SourceMods

# ====================================================================
# 清理旧Case (慎用，防止手滑删错)
# ====================================================================

if ( -e ${CASEROOT} ) then
    rm -rf $CASEROOT
endif

if ( -e ${RUNDIR} ) then
    rm -rf $RUNDIR
endif

# ====================================================================
# 创建 New Case
# ====================================================================

cd $CCSMROOT/cime/scripts

# 使用 F2000climo (F compset: 强迫海温的大气实验)，这是做气溶胶-气候相互作用的标准配置
./create_newcase --case $CASEROOT --mach $MACH --res f09_f09_mg17 --compset F2000climo \
                 --compiler intel --queue mpi --walltime 01:00 --run-unsupported

# ====================================================================
# 配置环境 (xmlchange)
# ====================================================================

cd $CASEROOT

# 修改运行目录
./xmlchange --file env_build.xml --id EXEROOT --val "${RUNDIR}/bld"
./xmlchange --file env_run.xml   --id RUNDIR  --val "${RUNDIR}/run"

# 输出数据归档设置 (调试阶段可以设为FALSE，正式跑设为TRUE)
./xmlchange --file env_run.xml   --id DOUT_S  --val 'FALSE'

# 设置运行时间
# 文章中NUG实验跑了1年 (2018年)。这里先跑5天测试能不能通。
./xmlchange --file env_run.xml --id RUN_STARTDATE --val '2018-07-01'
./xmlchange --file env_run.xml --id STOP_N        --val '5'
./xmlchange --file env_run.xml --id STOP_OPTION   --val 'ndays'

# 并行核心设置 (参考你的原脚本)
set N = 48
set M = 48

./xmlchange --file env_mach_pes.xml --id NTASKS_ATM --val "$N"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ATM --val '1'
./xmlchange --file env_mach_pes.xml --id ROOTPE_ATM --val '0'
# ... (其他组件保持跟大气一致即可，因为是F case，海洋是数据模式，开销很小)
./xmlchange --file env_mach_pes.xml --id NTASKS_LND --val "$N"
./xmlchange --file env_mach_pes.xml --id NTASKS_ICE --val "$M"
./xmlchange --file env_mach_pes.xml --id NTASKS_OCN --val "$M"
./xmlchange --file env_mach_pes.xml --id NTASKS_CPL --val "$M"
./xmlchange --file env_mach_pes.xml --id NTASKS_GLC --val "$M"
./xmlchange --file env_mach_pes.xml --id NTASKS_ROF --val "$M"
./xmlchange --file env_mach_pes.xml --id NTASKS_WAV --val "$M"
./xmlchange --file env_mach_pes.xml --id NTHRDS_ESP --val '1'

# ====================================================================
# 链接源代码 (SourceMods) - 核心步骤
# ====================================================================
cd $CASEROOT

# 如果你定义了 mymodscam 且文件夹存在，就把代码链过来
if ( $?mymodscam ) then
  if ( -d ${mymodscam} ) then
    echo "Linking SourceMods from ${mymodscam}"
    ln -s ${mymodscam}/* SourceMods/src.cam
  endif
endif

# ====================================================================
# 配置 namelist (Nudging 和 变量输出)
# ====================================================================

# 警告：请确保下面的 met_data_path 和 met_filenames_list 真实存在！
# 如果这些文件不存在，模型会报错直接停掉。

echo "user_nl_cam"
cat <<EOF >! user_nl_cam

! --- 气溶胶与物理包设置 ---
! 文章使用的是 trop_mam4，通常在 xmlchange CAM_CONFIG_OPTS 中设置，
! 但默认的 F2000climo 已经是 MAM4 了。

! --- Nudging (松弛逼近) 设置 ---
! Lu et al. 2023: "U, V components ... nudged to MERRA-2 ... relaxation timescale of 6 hr"
! 这里的设置是开启Nudging的关键

Nudge_Model = .true.
Nudge_Path  = '/share/home/minghuai/Liuym/DATA/MERRA2/CESM/0.9x1.25_32L/'
Nudge_File_Template = '/share/home/ywliu/lxyyy/data/Nudging_filenames/filenames_2000-2024_365.txt'
! 注意：你需要确认上面这个txt文件里是否包含2018年的文件名

ndgs_tau    = 6, 6, 6, 6   ! 松弛时间尺度 6小时
nudge_u     = .true.       ! 同化 U 风
nudge_v     = .true.       ! 同化 V 风
nudge_t     = .false.      ! 文章说: temperatures ... are not nudged
nudge_q     = .false.      ! 文章说: water vapors are not nudged
nudge_ps    = .false.      ! 地面气压通常也不nudging，除非文章特指

! --- 输出变量设置 ---
avgflag_pertape = 'A'     ! A:平均态
nhtfrq          = -24     ! -24: 输出日平均
mfilt           = 30      ! 一个文件存30个时次

! 输出变量列表 (总降水率，温度，U，V，10米风速，比湿，位势高度，地表气压，可见光波段，黑碳 AOD，颗粒有机物 AOD，沙尘 AOD，硫酸盐 AOD，总云量，云滴数浓度，大气层顶净短波辐射通量，大气层顶净长波辐射通量)
fincl1 = 'PRECT','T','U','V','U10','Q','Z3','PS',
         'AODVIS','AODDUST','AODBC','AODPOM','AODSO4',
         'CLDTOT','CDNUMC','FSNT','FLNT'

! 如果你要复现Plume Rise，你可能需要输出特定的变量
! 例如注入高度等，这取决于你在SourceMods里加了什么变量
! fincl1 = ..., 'PLUME_HEIGHT', ...

! --- 初始场设置 ---
! 保持原脚本的设置，或者根据你的年份修改
&cam_initfiles_nl
bnd_topo = '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/topo/fv_0.9x1.25_nc3000_Nsw042_Nrs008_Co060_Fi001_ZR_sgh30_24km_GRNL_c170103.nc'
ncdata   = '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/inic/fv/f.e20.FCSD.f09_f09_mg17.cesm2.1-exp002.001.cam.i.2005-01-01-00000_c180801_32L.nc'
/
EOF

# ====================================================================
# 编译和提交
# ====================================================================

cd $CASEROOT
./case.setup

# 如果之前编译过想省时间，可以不加 --clean-all。
# 但因为你可能要加 SourceMods，建议必须 clean-all 重新编译。
./case.build --clean-all

./case.build --skip-provenance-check

./case.submit

date
