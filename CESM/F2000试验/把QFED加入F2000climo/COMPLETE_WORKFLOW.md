# CESM火灾排放研究完整流程指南

## 📋 项目概述

**研究目标**: 使用CESM模拟2018年7月QFED火灾排放对气溶胶、辐射和气象的影响

**工作环境**:
- 校服(ywliu): 运行CESM模式
- 组服(zzsun): 数据处理和分析

**数据路径**:
- QFED数据: `/work13/zzsun/lxy_data/QFED/`
- CESM输出: `/share/home/ywliu/lxyyy/scratch/runout/`

---

## 🗂️ 目录结构

```
校服 (ywliu):
/share/home/ywliu/lxyyy/
├── scripts/                    # 脚本目录
│   ├── F2000_control.csh      # Control试验脚本
│   └── F2000_QFED.csh         # QFED试验脚本
└── scratch/
    ├── cesmrun/               # Case目录
    │   ├── F2000_control/
    │   └── F2000_QFED_201807/
    └── runout/                # 输出目录
        ├── F2000_control/
        └── F2000_QFED_201807/

组服 (zzsun):
/work13/zzsun/
├── lxy_data/
│   └── QFED/                  # QFED输入数据
├── cesm_analysis/
│   ├── scripts/               # 分析脚本
│   │   ├── check_qfed.py
│   │   ├── analyze_cesm.py
│   │   └── plot_results.py
│   ├── figures/               # 生成的图
│   └── processed_data/        # 处理后的数据
└── miniconda3/                # Conda环境
```

---

## 第一阶段: 环境准备

### A. 组服环境设置 (zzsun用户)

#### 1. 安装Miniconda

```bash
cd ~
wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.12.0-Linux-x86_64.sh
bash Miniconda3-py38_4.12.0-Linux-x86_64.sh -b -p /home/zzsun/miniconda3
/home/zzsun/miniconda3/bin/conda init bash
source ~/.bashrc
```

#### 2. 创建分析环境

```bash
conda create -n cesm_analysis python=3.8 -y
conda activate cesm_analysis
conda install -c conda-forge netcdf4 xarray numpy pandas matplotlib cartopy scipy dask seaborn -y
```

#### 3. 验证环境

```bash
python -c "import netCDF4; print('netCDF4:', netCDF4.__version__)"
python -c "import xarray; print('xarray:', xarray.__version__)"
python -c "import matplotlib; print('matplotlib:', matplotlib.__version__)"
```

#### 4. 检查QFED数据

```bash
cd /work13/zzsun/cesm_analysis/scripts/
python check_qfed.py /work13/zzsun/lxy_data/QFED/ --check-dir
python check_qfed.py /work13/zzsun/lxy_data/QFED/qfed2.emis_bc.061.20180701.nc4
```

**预期结果**: 显示"OK - All files present!"和详细的变量信息

---

## 第二阶段: Control试验 (无火灾)

### A. 准备Control试验 (校服 - ywliu用户)

#### 1. 创建工作目录

```bash
mkdir -p /share/home/ywliu/lxyyy/scripts
cd /share/home/ywliu/lxyyy/scripts
```

#### 2. 运行Control试验

```bash
# 使用提供的F2000_control.csh脚本
csh F2000_control.csh
```

#### 3. 监控运行

```bash
# 查看作业状态
bjobs

# 查看case状态
cd /share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control
cat CaseStatus

# 实时监控日志
tail -f /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/cesm.log.*
```

#### 4. 检查结果

```bash
# 成功标志
cd /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run
ls *.cam.h0.*.nc

# 应该看到类似:
# F2000_control.cam.h0.2018-07-01-00000.nc

# 检查日志最后几行
tail -50 cesm.log.* | grep -i "success\|error"
```

**预期运行时间**: 
- 编译: ~10-20分钟
- 运行1天: ~5-10分钟
- 总计(测试3天): ~30-40分钟

---

## 第三阶段: QFED试验 (含火灾)

### A. 准备QFED试验 (校服 - ywliu用户)

#### 1. 确保QFED数据可访问

```bash
# 测试访问权限
ls /work13/zzsun/lxy_data/QFED/qfed2.emis_bc.061.20180701.nc4

# 如果无法访问,需要添加权限
# 由zzsun用户执行:
# chmod -R 755 /work13/zzsun/lxy_data/QFED/
```

#### 2. 运行QFED试验

```bash
cd /share/home/ywliu/lxyyy/scripts
csh F2000_QFED.csh
```

#### 3. 监控运行

```bash
# 查看作业
bjobs

# 查看日志
tail -f /share/home/ywliu/lxyyy/scratch/runout/F2000_QFED_201807/run/cesm.log.*
```

#### 4. 验证QFED是否工作

```bash
cd /share/home/ywliu/lxyyy/scratch/runout/F2000_QFED_201807/run

# 检查BC排放通量
ncdump -v SFbc_a4 F2000_QFED_201807.cam.h0.2018-07-01-00000.nc | tail -30

# 应该看到非零值,特别是在火灾活跃区域
```

---

## 第四阶段: 数据分析

### A. 快速检查 (组服 - zzsun用户)

```bash
conda activate cesm_analysis
cd /work13/zzsun/cesm_analysis/scripts

python << EOF
import xarray as xr
import numpy as np

# 加载数据
control = xr.open_dataset('/share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/F2000_control.cam.h0.2018-07-01-00000.nc')
qfed = xr.open_dataset('/share/home/ywliu/lxyyy/scratch/runout/F2000_QFED_201807/run/F2000_QFED_201807.cam.h0.2018-07-01-00000.nc')

# 比较BC排放
print('Control BC emission max:', control['SFbc_a4'].max().values)
print('QFED BC emission max:', qfed['SFbc_a4'].max().values)

# 比较BC浓度
bc_diff = qfed['bc_a4_SRF'].mean() - control['bc_a4_SRF'].mean()
print('BC concentration increase:', bc_diff.values)
EOF
```

### B. 完整分析

```bash
# 运行分析脚本
python analyze_cesm.py

# 生成对比图
python plot_results.py
```

### C. 区域分析

```python
# 中国区域
python region_analysis.py --region china --lat1 18 --lat2 54 --lon1 73 --lon2 135

# 全球
python region_analysis.py --region global
```

---

## 第五阶段: 结果整理

### A. 生成报告

```bash
cd /work13/zzsun/cesm_analysis
python generate_report.py
```

### B. 关键结果检查清单

- [ ] Control试验成功运行
- [ ] QFED试验成功运行
- [ ] QFED排放通量(SFbc_a4, SFpom_a4)有明显的空间分布
- [ ] BC/POM浓度在火灾区域增加
- [ ] AOD增加
- [ ] 辐射通量有变化
- [ ] 生成对比图

---

## 📊 关键输出变量说明

### 火灾排放验证
- `SFbc_a4`: BC地表排放通量
- `SFpom_a4`: POM地表排放通量
- `SFSO2`: SO2地表排放通量

### 气溶胶浓度
- `bc_a4`, `bc_a4_SRF`: BC浓度(3D和地表)
- `pom_a4`, `pom_a4_SRF`: POM浓度
- `PM25`: PM2.5浓度

### 光学特性
- `AEROD_v`, `AODVIS`: 总AOD
- `AODPOM`: POM光学厚度
- `AODSOA`: SOA光学厚度

### 辐射效应
- `FSNT`, `FSNTC`: 顶层净短波通量
- `SWCF`: 短波云辐射强迫
- `LWCF`: 长波云辐射强迫

### 气象响应
- `PRECT`: 总降水
- `CLDTOT`: 总云量
- `TREFHT`: 2米温度

---

## 🔧 常见问题排查

### 问题1: Control试验运行失败

**症状**: 运行几秒后失败
**检查**:
```bash
tail -100 /share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/cesm.log.*
```
**常见原因**:
- user_nl_cam中变量名拼写错误
- 输入文件路径不正确

### 问题2: QFED试验找不到排放文件

**症状**: 错误信息"Cannot find file"
**检查**:
```bash
ls /work13/zzsun/lxy_data/QFED/qfed2.emis_bc.061.20180701.nc4
```
**解决**: 确认路径正确且有读取权限

### 问题3: QFED排放没有生效

**症状**: SFbc_a4全部为0
**检查**:
```bash
# 查看实际使用的namelist
cat /share/home/ywliu/lxyyy/scratch/runout/F2000_QFED_201807/run/atm_in | grep -A10 srf_emis
```
**解决**: 检查srf_emis_specifier配置是否正确

### 问题4: 分析脚本报错

**症状**: Python脚本无法读取nc文件
**检查**:
```bash
conda activate cesm_analysis
python -c "import netCDF4"
```
**解决**: 重新安装netCDF4

---

## 📈 预期科学结果

### 直接效应
- BC/POM浓度增加 50-200%
- AOD增加 0.05-0.2
- PM2.5浓度增加 5-20 μg/m³

### 辐射效应
- 短波辐射减少 5-15 W/m²
- 气溶胶直接辐射强迫: -2 to -5 W/m²

### 间接效应
- 云滴数浓度变化
- 云量变化
- 降水响应(可能增加或减少)

---

## 📚 参考文献

1. QFED数据集: https://portal.nccs.nasa.gov/datashare/iesa/aerosol/emissions/QFED/
2. CESM用户指南: https://www.cesm.ucar.edu/models/cesm2/
3. CAM6文档: https://ncar.github.io/CAM/doc/build/html/

---

## 📞 联系和支持

如遇问题:
1. 检查日志文件
2. 查看本指南的常见问题部分
3. 咨询导师或组内同学
4. CESM论坛: https://bb.cgd.ucar.edu/cesm/

---

## ✅ 完成检查清单

### 环境准备
- [ ] Conda环境安装完成
- [ ] QFED数据验证通过
- [ ] Python包安装完成

### 模式运行
- [ ] Control试验完成
- [ ] QFED试验完成
- [ ] 输出文件生成

### 数据分析
- [ ] 排放通量验证
- [ ] 浓度对比分析
- [ ] 辐射效应分析
- [ ] 图表生成

### 结果整理
- [ ] 关键结果总结
- [ ] 图表整理
- [ ] 报告撰写

---

## 🎯 时间安排建议

**第1-2天**: 环境准备和数据检查
**第3-4天**: Control试验
**第5-7天**: QFED试验
**第8-10天**: 数据分析和可视化
**第11-14天**: 结果整理和报告

**总计**: 约2周完成完整流程

---

**祝研究顺利!** 🎉
