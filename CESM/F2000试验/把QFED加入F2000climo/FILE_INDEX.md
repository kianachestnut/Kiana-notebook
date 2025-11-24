# 📁 CESM火灾排放研究 - 文件总索引

## 🌟 核心文件 (必读必用)

### 1️⃣ 开始阅读
📘 **README.md** - 从这里开始!
- 快速开始指南
- 文件用途说明
- 常见问题索引

📘 **COMPLETE_WORKFLOW.md** - 完整流程
- 详细分步骤操作
- 时间安排
- 检查清单

### 2️⃣ CESM模式运行 (校服 - ywliu)
🔧 **F2000_control.csh** - Control试验 (必需)
🔧 **F2000_QFED.csh** - QFED试验 (必需)

### 3️⃣ Python分析工具 (组服 - zzsun)
🐍 **check_qfed.py** - QFED数据检查 (必需)
🐍 **analyze_cesm_output.py** - 结果分析 (必需)
🔧 **install_conda_onestep.sh** - 环境安装 (必需)

## 📚 参考文档

### 变量和配置
📄 **fire_variables_guide.txt** - 变量完整列表
📄 **user_nl_cam_verified.txt** - 验证过的配置
📄 **QFED_Configuration_Guide.md** - QFED详细配置

### 问题排查
🔍 **cesm_failure_diagnosis.md** - 运行失败诊断
🔍 **quick_troubleshoot.md** - 快速排查
🔍 **diagnose_cesm.sh** - 自动诊断脚本

### 备用工具
⚙️ **manual_run_guide.sh** - 手动运行指南
⚙️ **check_qfed_simple.sh** - 简化版检查(无需Python)

## 📂 其他配置文件

📋 **FHIST_QFED_example.csh** - FHIST compset示例
📋 **F2000_QFED_standard.csh** - 标准配置版本
📋 **F2000_QFED_final.csh** - 最终优化版本

---

## 🎯 使用路线图

### 新手入门路线
```
1. 读 README.md (5分钟)
2. 读 COMPLETE_WORKFLOW.md (20分钟)  
3. 运行 install_conda_onestep.sh (5分钟)
4. 运行 check_qfed.py (2分钟)
5. 运行 F2000_control.csh (30分钟)
6. 运行 F2000_QFED.csh (30分钟)
7. 运行 analyze_cesm_output.py (5分钟)
```

### 遇到问题路线
```
1. 查 README.md "常见问题"
2. 查 COMPLETE_WORKFLOW.md "问题排查"
3. 查 cesm_failure_diagnosis.md
4. 运行 diagnose_cesm.sh
```

### 深入研究路线
```
1. 读 fire_variables_guide.txt - 了解所有变量
2. 读 QFED_Configuration_Guide.md - 深入配置
3. 修改 analyze_cesm_output.py - 定制分析
4. 参考 FHIST_QFED_example.csh - 尝试其他compset
```

---

## 📖 文件详细说明

### ⭐ README.md
**用途**: 项目总览和快速开始
**包含**:
- 文件清单
- 快速开始5步骤
- 路径配置
- 预期结果
- 问题索引

**何时使用**: 刚拿到这个文件包时第一个读!

---

### ⭐ COMPLETE_WORKFLOW.md
**用途**: 完整的研究流程指南
**包含**:
- 5个阶段详细步骤
- 环境准备
- 模式运行
- 数据分析
- 结果整理
- 时间安排
- 问题排查
- 完成检查清单

**何时使用**: 
- 第一次运行前通读
- 每个阶段开始前查阅对应章节
- 遇到问题时查"常见问题排查"

---

### ⭐ F2000_control.csh
**用途**: Control试验脚本(无火灾)
**关键设置**:
```csh
CASE: F2000_control
RUN_STARTDATE: 2018-07-01
STOP_N: 3 (运行3天)
无 srf_emis_specifier (无额外排放)
```

**运行方法**:
```bash
# 在校服 ywliu用户
cd /share/home/ywliu/lxyyy/scripts
csh F2000_control.csh
```

**输出位置**:
```
/share/home/ywliu/lxyyy/scratch/runout/F2000_control/run/
├── F2000_control.cam.h0.2018-07-01-00000.nc
├── F2000_control.cam.h0.2018-07-02-00000.nc
└── F2000_control.cam.h0.2018-07-03-00000.nc
```

**预期时间**: ~30-40分钟

---

### ⭐ F2000_QFED.csh
**用途**: QFED试验脚本(含火灾)
**关键设置**:
```csh
CASE: F2000_QFED_201807
RUN_STARTDATE: 2018-07-01
STOP_N: 3
srf_emis_specifier: 指向QFED文件
```

**关键配置**:
```fortran
srf_emis_specifier = 
  'bc_a4  -> /work13/zzsun/lxy_data/QFED/qfed2.emis_bc.061.%y%m%d.nc4:biomass',
  'pom_a4 -> /work13/zzsun/lxy_data/QFED/qfed2.emis_oc.061.%y%m%d.nc4:biomass',
  'SO2    -> /work13/zzsun/lxy_data/QFED/qfed2.emis_so2.061.%y%m%d.nc4:biomass'
```

**验证方法**:
```bash
# 检查SFbc_a4是否有非零值
ncdump -v SFbc_a4 output.nc | tail -30
```

---

### ⭐ check_qfed.py
**用途**: QFED数据验证工具
**功能1** - 检查完整性:
```bash
python check_qfed.py /work13/zzsun/lxy_data/QFED/ --check-dir
# 输出: OK - All files present! (或列出缺失文件)
```

**功能2** - 查看详细信息:
```bash
python check_qfed.py /work13/zzsun/lxy_data/QFED/qfed2.emis_bc.061.20180701.nc4
# 输出: 维度、变量、单位、统计值、CESM配置建议
```

**依赖**: Python 3.x + netCDF4

---

### ⭐ analyze_cesm_output.py
**用途**: CESM输出分析和可视化
**功能**:
- 加载Control和QFED输出
- 计算差异
- 生成对比图
- 区域统计

**运行方法**:
```bash
conda activate cesm_analysis
python analyze_cesm_output.py
```

**输出位置**:
```
/work13/zzsun/cesm_analysis/figures/
├── SFbc_a4_20180715.png
├── bc_a4_SRF_comparison.png
└── ...
```

**可定制**: 修改脚本中的区域、变量、时间范围

---

### ⭐ install_conda_onestep.sh
**用途**: 自动安装Miniconda
**特点**:
- 批量模式,无需手动输入
- 兼容老系统(GLIBC 2.17)
- 自动初始化

**运行方法**:
```bash
bash install_conda_onestep.sh
source ~/.bashrc
```

---

### 📄 fire_variables_guide.txt
**用途**: 所有可用变量的完整列表
**包含**:
- 火灾排放通量
- 气溶胶浓度
- 光学特性
- 辐射变量
- 气象变量
- 变量命名规则
- 推荐配置

**何时使用**: 
- 设计输出变量时
- 查询变量含义时
- 检查变量是否存在时

---

### 📄 user_nl_cam_verified.txt
**用途**: 已验证的user_nl_cam配置
**特点**: 所有变量都确认存在于F2000climo
**直接使用**: 复制到case的user_nl_cam文件

---

### 🔍 cesm_failure_diagnosis.md
**用途**: CESM运行失败诊断指南
**包含**:
- 5类常见错误
- 每类的症状、原因、解决方案
- 日志查看方法
- 快速修复命令

**何时使用**: Control或QFED运行失败时

---

### 🔧 diagnose_cesm.sh
**用途**: 自动诊断CESM运行状态
**功能**:
- 检查目录结构
- 查找日志文件
- 搜索错误信息
- 给出诊断建议

**运行方法**:
```bash
bash diagnose_cesm.sh > diagnosis.txt
cat diagnosis.txt
```

---

## 🗺️ 文件依赖关系

```
README.md (入口)
    ↓
COMPLETE_WORKFLOW.md (详细流程)
    ↓
├─→ install_conda_onestep.sh (环境)
├─→ check_qfed.py (数据检查)
├─→ F2000_control.csh (Control)
├─→ F2000_QFED.csh (QFED)
│       ↓
│   需要: QFED数据 + user_nl_cam配置
│       ↓
│   参考: fire_variables_guide.txt
│         user_nl_cam_verified.txt
│         QFED_Configuration_Guide.md
│       ↓
├─→ analyze_cesm_output.py (分析)
│
└─→ 遇到问题:
    ├─→ quick_troubleshoot.md
    ├─→ cesm_failure_diagnosis.md
    └─→ diagnose_cesm.sh
```

---

## ✅ 推荐阅读顺序

### 第一次使用 (Day 1)
1. ✅ README.md (了解全貌)
2. ✅ COMPLETE_WORKFLOW.md (理解流程)
3. ✅ fire_variables_guide.txt (了解变量)

### 环境准备 (Day 1-2)
4. ✅ install_conda_onestep.sh (安装环境)
5. ✅ check_qfed.py (验证数据)

### 开始运行 (Day 3-4)
6. ✅ F2000_control.csh (运行Control)
7. ✅ 参考 cesm_failure_diagnosis.md (如遇问题)

### 火灾试验 (Day 5-7)
8. ✅ QFED_Configuration_Guide.md (深入理解)
9. ✅ F2000_QFED.csh (运行QFED)

### 结果分析 (Day 8-10)
10. ✅ analyze_cesm_output.py (分析结果)

---

## 💡 专业提示

### 提示1: 保存中间结果
```bash
# 每个阶段完成后截图或保存日志
cp cesm.log cesm.log.backup.$(date +%Y%m%d)
```

### 提示2: 建立自己的笔记
在COMPLETE_WORKFLOW.md旁边创建你自己的运行日志

### 提示3: 版本控制
如果修改了脚本,保留原版本:
```bash
cp F2000_QFED.csh F2000_QFED.csh.original
```

### 提示4: 与同学分享
这些脚本可以分享给做类似研究的同学

---

## 📞 获取帮助

### 文件内帮助
- 每个脚本都有详细注释
- markdown文档都有目录结构
- 遇到困惑先搜索文档

### 外部资源
- CESM论坛: https://bb.cgd.ucar.edu/cesm/
- QFED文档: https://portal.nccs.nasa.gov/datashare/iesa/aerosol/emissions/QFED/

---

**最后更新**: 2025-11-24
**版本**: 1.0
**状态**: 已完成测试 ✅

祝研究顺利! 🎉🔥🌍
