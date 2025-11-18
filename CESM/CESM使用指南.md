# CESM使用指南 by Kiana_Chestnut
## 编于2025.10.28

> [CESM](http://www.cesm.ucar.edu/index.html)(Community Earth System Model)是一个由美国国家大气研究中心(NCAR)开发的气候系统模式，目前得到广泛的应用。此指南参考了[HanXiang0721](https://github.com/HanXiang0721)的成果与[CESM2.1官网](https://esmci.github.io/cime/versions/master/html/ccs/index.html)，部分内容来自AI。


## CESM移植安装与运行

### 预准备

首先查看目前CESM已经有的版本：

`svn list https://svn-ccsm-release.cgd.ucar.edu/model_versions`

然后下载需要的版本：

`svn co https://svn-ccsm-release.cgd.ucar.edu/model_versions/cesm1_2_1 cesm1_2_1`


然后利用命令：

```sh
cd ccsm4/scripts
./create_newcase -l
```

列出模式支持的系统信息。

### 定义目录

```sh
setenv MACH hpcc
setenv CCSMTAG CESM2-release-2.1.0
setenv CCSMROOT /share/home/minghuai/yliang/model/$CCSMTAG
setenv DATADIR  /share/home/minghuai/yliang/model/CESM_INPUT
# setenv PTMP  $CSCRATCH/CASES_SPCAM/$CASE
```
`CCSMROOT`和`DATADIR`都是祖传的，不要改动，`CCSMTAG`就是使用的CESM版本

### case-specific stuff 就是我个人的目录
```sh
setenv CASE    F2000_default
setenv CIME_OUTPUT_ROOT /share/home/ywliu/lxyyy/scratch/runout
setenv CASEROOT /share/home/ywliu/lxyyy/scratch/cesmrun/$CASE
setenv RUNDIR   $CIME_OUTPUT_ROOT/$CASE
```
`CIME_OUTPUT_ROOT`：CIME/CESM 的“运行输出根目录”，通常放在大容量或高速的 scratch/输出文件系统下，用来存放每个 case 的运行输出目录与结果。  

`CASEROOT`：具体某个 case 的工作目录（case root），包含 create_newcase 生成的 case 配置、脚本、XML、build/run 控制文件等。 

`RUNDIR` = $CIME_OUTPUT_ROOT/$CASE：实际运行时模型把输出写到这个目录。

### 新建CASE

执行下面这条命令：

` ./create_newcase --case $CASEROOT --mach $MACH --res f09_f09_mg17 --compset F2000climo \45 --compiler intel --queue mpi--walltime 01:00 --run-unsupported`

`-case`：新建的CASE的名字

`-res`：分辨率

`-compset`：需要哪些分量模式组合，如何组合等设置，具体参考手册

`-mach`：机器名，和前面的配置一致

### 配置环境
```sh
 55 ./xmlchange --file env_build.xml --id EXEROOT --val "${RUNDIR}/bld"
 56 ./xmlchange --file env_run.xml   --id RUNDIR  --val "${RUNDIR}/run"
 57 ./xmlchange --file env_run.xml   --id DOUT_S  --val 'FALSE'
 58 #./xmlchange --file env_run.xml   --id DOUT_S_ROOT          --val "${RUNDIR}/archive"
 59 #./xmlchange --file env_run.xml   --id DIN_LOC_ROOT         --val  $DATADIR
 60 #./xmlchange --file env_run.xml   --id DIN_LOC_ROOT_CLMFORC --val "$DATADIR/atm/datm7"
 61
 62
 63 # edit env_batch.xml
 64 # ./xmlchange --file env_batch.xml --id JOB_QUEUE          --val 'mpi'
 65 # ./xmlchange --file env_batch.xml --id JOB_WALLCLOCK_TIME --val '01:00'
 66
 67 set N = 48
 68 set M = 48
 69
 70 ./xmlchange --file env_mach_pes.xml --id NTASKS_ATM --val "$N"
 71 ./xmlchange --file env_mach_pes.xml --id NTHRDS_ATM --val '1'
 72 ./xmlchange --file env_mach_pes.xml --id ROOTPE_ATM --val '0'
 73
 74 ./xmlchange --file env_mach_pes.xml --id NTASKS_LND --val "$N"
 75 ./xmlchange --file env_mach_pes.xml --id NTHRDS_LND --val '1'
 76 ./xmlchange --file env_mach_pes.xml --id ROOTPE_LND --val '0'
 77
 78 ./xmlchange --file env_mach_pes.xml --id NTASKS_ICE --val "$M"
 79 ./xmlchange --file env_mach_pes.xml --id NTHRDS_ICE --val '1'
 80 ./xmlchange --file env_mach_pes.xml --id ROOTPE_ICE --val '0'
 81
 82 ./xmlchange --file env_mach_pes.xml --id NTASKS_OCN --val "$M"
 83 ./xmlchange --file env_mach_pes.xml --id NTHRDS_OCN --val '1'
 84 ./xmlchange --file env_mach_pes.xml --id ROOTPE_OCN --val '0'
 85
 86 ./xmlchange --file env_mach_pes.xml --id NTASKS_CPL --val "$M"
 87 ./xmlchange --file env_mach_pes.xml --id NTHRDS_CPL --val '1'
 88 ./xmlchange --file env_mach_pes.xml --id ROOTPE_CPL --val '0'
 89
 90 ./xmlchange --file env_mach_pes.xml --id NTASKS_GLC --val "$M"
 91 ./xmlchange --file env_mach_pes.xml --id NTHRDS_GLC --val '1'
 92 ./xmlchange --file env_mach_pes.xml --id ROOTPE_GLC --val '0'
 93
 94 ./xmlchange --file env_mach_pes.xml --id NTASKS_ROF --val "$M"
 95 ./xmlchange --file env_mach_pes.xml --id NTHRDS_ROF --val '1'
 96 ./xmlchange --file env_mach_pes.xml --id ROOTPE_ROF --val '0'
 97
 98 ./xmlchange --file env_mach_pes.xml --id NTASKS_WAV --val "$M"
 99 ./xmlchange --file env_mach_pes.xml --id NTHRDS_WAV --val '1'

```
`58`：模型编译结果会放在 RUNDIR/bld 下

`59`：运行时文件写入 RUNDIR/run

`60`：关闭短期归档（DOUT_S = FALSE），即不把 history 等文件短期拷贝到 DOUT_S_ROOT

`set N = 48 / set M = 48`：给两个变量 N 和 M 赋值为 48（核时，最小为24，必须是24的倍数）

`70-end`：  
这些命令设置每个组件的并行布局（PEs / threads）：
`NTASKS_<COMP>`：该组件的 MPI task 数（每个 task 对应一个 MPI rank）。
`NTHRDS_<COMP>`：每个 MPI task 的线程数（OpenMP 线程数）。
`ROOTPE_<COMP>`：该组件在全局 PE 空间中的起始 rank（起始 PE index）。

### 设置跑的时间以及输出间隔
```sh
119 ./xmlchange --file env_run.xml --id RUN_STARTDATE --val '2000-01-01'
120 ./xmlchange --file env_run.xml --id RESUBMIT      --val '0'
121 ./xmlchange --file env_run.xml --id STOP_N        --val '3'
122 ./xmlchange --file env_run.xml --id STOP_OPTION   --val 'ndays'
123 ./xmlchange --file env_run.xml --id REST_N        --val '1'
124 ./xmlchange --file env_run.xml --id REST_OPTION   --val 'ndays'
125 #./xmlchange --file env_run.xml --id ATM_NCPL --val '11
126 #./xmlchange --file env_run.xml --id INFO_DBUG  --val '3'
127 #./xmlchange --file env_run.xml --id PIO_DEBUG_LEVEL --val '4'
```
`RUN_STARTDATE`：模式起始日期

`RESUBMIT`：自动续提交次数（整数）。0 表示不自动续提交；>0 表示在本次 STOP 后自动重新提交指定次数，用于把长模拟分多次作业提交

`STOP_N`：本次运行的长度数值

`STOP_OPTION`：`STOP_N`的单位

`REST_N`：写重启文件（restart）或短期输出的间隔数值

`REST_OPTION`：`REST_N`的单位

**重启文件**的目的是：  

保存模式当前状态：包含各分量的物理场、累积量、模型时间、随机数种子等，能精确恢复到写文件那一刻的运行状态。  

故障恢复：作业中途出错或节点故障时，可从最近一次重启文件恢复，避免从头重跑。 

长期模拟分段运行：配合 RESUBMIT 或手动续提交，允许把长模拟分成多次作业连续运行。  

数据再现与调试：便于重现特定时刻的状态用于诊断、敏感性实验或后处理。  

支持后处理/耦合初始化：有时用于其它模型组件或下一个实验作为初始场。  

### 修改NAMELIST!（最重要的步骤！）
```sh
134 echo "user_nl_cam"
135 cat <<EOF >! user_nl_cam
136
137 !& camexp
138
139 !npr_yz          = 8, 4, 4, 8
140
141 avgflag_pertape = 'A'!,'A'!,'A'! !A:average; L:local time
142
143 nhtfrq          = -24!, 0 !,-24 !write frequency, 0:monthly average; -24: daily; -1:hourly
144 mfilt           = 1  !, 1 ! !maximum number of time samples
145
146 fincl1 = 'PRECT','T','U','V','U10'
147 !fincl2 =  'TMdst_a1', 'TMdst_a2', 'TMdst_a3','a2x_DSTWET1','a2x_DSTDRY1', 'a2x_DSTWET2', 'a2x_DSTDRY2', 'a2x_DSTWET3','a2x_DSTDRY3','a2x_DSTWET4','a2x_DSTD    RY4','dst_a2SF','dst_a1SF', 'dst_a3SF','DSTSFMBL', 'dst_a1DDF', 'dst_a2DDF', 'dst_a3DDF','dst_c1DDF', 'dst_c2DDF', 'dst_c3DDF', 'dst_a1SFWET' ,'dst_a2SFWET'    , 'dst_a3SFWET', 'dst_c1SFWET', 'dst_c2SFWET', 'dst_c3SFWET', 'CT_dst_a1', 'CT_dst_a2', 'CT_dst_a3', 'SFdst_a1', 'SFdst_a2', 'SFdst_a3', 'AODDUST1', 'AODdnD    UST1', 'AODDUST2', 'AODdnDUST2', 'AODDUST3', 'AODdnDUST3', 'AODDUST4', 'AODdnDUST4', 'AODDUST', 'AODDUSTdn', 'BURDENDUST', 'BURDENDUSTdn','dst_a1','dst_a2',    'dst_a3', 'dst_c1', 'dst_c2',  'dst_c3','num_a2SF', 'num_a1SF', 'num_a3SF','DF_dst_a1','DF_dst_a2','DF_dst_a3','dst_a1_SRF',  'dst_a2_SRF','dst_a3_SRF'
148
149
150 &cam_initfiles_nl
151 bnd_topo = '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/topo/fv_0.9x1.25_nc3000_Nsw042_Nrs008_Co060_Fi001_ZR_sgh30_24km_GRNL_c170103.nc'
152 ncdata  = '/share/home/minghuai/yliang/model/CESM_INPUT/atm/cam/inic/fv/f.e20.FCSD.f09_f09_mg17.cesm2.1-exp002.001.cam.i.2005-01-01-00000_c180801_32L.nc'
153 /
154
155 !&metdata_nl
156 ! met_data_file          = '2000/MERRA2_0.9x1.25_20000101.nc'
157 ! met_data_path          = '/share/home/minghuai/Liuym/DATA/MERRA2/CESM/0.9x1.25_32L/'
158 ! met_filenames_list     = '/share/home/ywliu/yhzhang/data/Nudging_filenames/filenames_2000-2024_365.txt'
159 ! met_rlx_time           = 0.0
160 /
161 EOF
```
`134`表明我正在写`user_nl_cam`文件

`135`表示会把这个`EOF`到下一个`EOF`之间的内容写进`user_nl_cam`文件

下面的就是CAM6里的变量名称，详见[namelist](https://docs.cesm.ucar.edu/models/cesm2/settings/current/cam_nml.html)  

**这里对已出现的做解释**

`avgflag_pertape`:  
Valid Values ['A', 'B', 'I', 'X', 'M', 'L', 'S']  
>A ==> Average  
 B ==> GMT 00:00:00 average  
 I ==> Instantaneous  
 M ==> Minimum  
 X ==> Maximum  
 L ==> Local-time  
 S ==> Standard deviation  

`nhtfrq`:  
Valid Values ['any integer(10)'] 

Array of write frequencies for each history file series.  
* If nhtfrq(1) = 0, the file will be a monthly average.
Only the first file series may be a monthly average.    
* If nhtfrq(i) > 0, frequency is specified as number of
timesteps.  
* If nhtfrq(i) < 0, frequency is specified
as number of hours.

`mfilt`:  
Valid Values ['any integer(10)']  

包含写入历史文件的最大时间样本数的数组。第一个值适用于主历史文件，第二到第十个值适用于辅助历史文件。

`fincl1`:  
Valid Values ['any char']  
添加的字段必须在主字段列表中。  
输出字段的平均标志可以通过在字段名后附加“:”和有效的平均标志来指定。  
有效平均标志同`avgflag_pertape`。

`cam_initfiles_nl`:用于指定地形、初始场等文件路径

`bnd_topo`:地形场的时间不变边界数据集的完整路径名。  
具体路径名在[namelist](https://docs.cesm.ucar.edu/models/cesm2/settings/current/cam_nml.html)中搜索`bnd_topo`即可。

`ncdata`:初始大气状态数据集的完整路径名。  
具体路径名在[namelist](https://docs.cesm.ucar.edu/models/cesm2/settings/current/cam_nml.html)中搜索`ncdata`即可。

### 提交并运行程序
```sh
166 cd $CASEROOT
167 ./case.setup
168
169 ./case.build --clean-all
170
171 ./case.build --skip-provenance-check
172
173 ./case.submit
```

## 编译 
在终端中先输入  
```sh
lxy
```
以进入编译环境  
再使用  
```sh
csh F2000_default.csh
```
进行编译  

### 运行出来的文件都是什么意思（来自D老师）

#### 核心概念：输出频率和流

CESM通过**“流”** 来管理输出。每个组件（大气、海洋、陆地等）都有预定义的输出流，控制着**输出什么变量、以什么频率输出、输出成什么文件**。这些设置在 `env_run.xml` 和每个组件的 `user_nl_xxx` 文件中定义。

---

#### 主要文件类型详解

##### 1. 历史输出文件 - 最主要的数据

这是你进行数据分析最常用到的文件，包含了模型在特定时间频率下的三维场和二维场。

- **命名模式**：`{CASE}.{COMP}.{TYPE}.{DATE}-{DATE}.nc`
- **例子**：`F2000_default.cam.h0.2000-01.nc`

这里的关键部分是 **`{TYPE}`**，通常是 `h` 后面跟一个数字：

- **`h0`**: **月度输出**。最常用的输出，包含了月平均的几乎所有变量（如温度、降水、风场等）。
- **`h1`**: **日平均输出**。输出日平均的变量。
- **`h2`**: **6小时平均输出**。用于高频率过程分析。
- **`h3`**: **3小时平均输出**。更高频率，常用于分析日循环等。
- **`h4`**: **日最高/最低值**。如日最高/最低温度。
- **`h5`**: **瞬时场**。在某些特定时刻的瞬时状态，用于重启或详细诊断。
- **`h6`**: **单点/站点输出**。
- **`h7`**: **月平均的日循环**。将一个月中每一天的同一个小时平均起来，得到日循环气候态。

**组件示例**：
- `F2000_default.cam.h0. ... .nc` -> **大气** 月平均数据
- `F2000_default.pop.h. ... .nc` -> **海洋** 数据（POP海洋模型有自己的命名习惯，常用 `h`/`hnd` 表示月平均）
- `F2000_default.clm2.h0. ... .nc` -> **陆地** 数据
- `F2000_default.cice.h. ... .nc` -> **海冰** 数据

##### 2. 重启文件

用于**让模型从中断的地方继续运行**。它包含了重新启动模型所需的**完整系统状态**，而不仅仅是平均后的物理量。

- **用途**：
    1.  模型意外中断后继续运行。
    2.  故意设置的“断点”，例如一个100年的模拟，可以每10年输出一组重启文件，如果后面5年结果有问题，可以从第10年的重启点重新开始，而不用从头跑。
- **命名模式**：`{CASE}.{COMP}.{DATE}.r.{RESTART_DATE}.nc`
- **例子**：`F2000_default.cam.r.2001-01-01-00000.nc`
- **特点**：文件通常很大，因为包含了所有网格点的状态变量。一般不会保留所有重启文件，只会保留最近的一个或几个。

##### 3. 日志文件

记录模型运行的详细信息，用于**调试和监控**。

- **命名模式**：`{COMP}.log.{DATE}`
- **例子**：
    - `cpl.log.200101-000000` -> **耦合器** 日志，记录各组件之间的同步和信息交换。
    - `cam.log.200101-000000` -> **大气** 组件日志。
    - `pop.log.200101-000000` -> **海洋** 组件日志。
- **内容**：包括模型的启动时间、每一步的计算耗时、可能的错误和警告信息等。如果模型运行失败，**第一个要查看的就是日志文件**。

##### 4. 时序文件（我的脚本好像并不会生成这个东西，D老师也前言不搭后语）

包含**单个变量随时间演变**的序列，通常是全局平均或区域平均的量。文件很小，适合快速查看模拟的整体行为。

- **命名模式**：`{CASE}.{COMP}.{VARIABLE}.{FREQUENCY}.nc`
- **例子**：
    - `F2000_default.cam.TGCLDLWP_TGCLDIWP.global_mean.txt` -> 全球平均云水路径和云冰路径的文本文件。
    - `F2000_default.cice.aice_nh.area_avg.txt` -> 北半球平均海冰密集度的文本文件。

---

#### 总结表格

| 文件类型 | 命名示例 | 主要用途 | 是否重要 | 通常大小 |
| :--- | :--- | :--- | :--- | :--- |
| **历史输出 (h0)** | `F2000.cam.h0.2000-01.nc` | **数据分析主力**，气候态、变量场 | **核心** | 中等 |
| **历史输出 (h1/h2)** | `F2000.cam.h1.2000-01-01.nc` | 日变化、天气过程分析 | 视研究目的而定 | 较大 |
| **重启文件** | `F2000.cam.2001-01-01.nc` | **继续运行模型** | **关键（运行期）** | 很大 |
| **耦合器日志** | `F2000.cpl.log....` | **检查运行状态/错误** | **关键（诊断）** | 小 |
| **时序文件** | `F2000.cam.PRECT.global_mean.txt` | 快速评估模拟稳定性 | 很有用 | 很小 |

**给你的建议**：
现在，你可以去你的 `RUNDIR` 目录下，用 `ls` 命令看看，对照上面的解释，你就能基本分辨出每个文件是干什么的了。开始分析时，就从 `cam.h0.pop.h.` 等文件开始。  

**（感谢D老师）**

## 写在后面
感动中国了，我终于写出来了这个使用指南，希望可以帮到未来的我自己和其他同行，具体的试验具体再说吧！