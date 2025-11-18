# 要点总结（先读这段）

* 目标：把 Freitas 等 (2007) 的 1-D plume-rise 在线/交互式接入你的 F2000（等价于 Lu 等人在 E3SM 中做的 NUG_PLR / NUG_NDC / NUG_CTL 实验）。Lu 等人在 E3SM 中按**小时调用 plume-rise、用 4 个 FRP bin、把 emissions 在上下界之间平均分配**等策略实现并进行了 NUG（nudged）一年试验以验证。 

---

# 具体步骤（逐步可执行）

## 1) 准备：需求与输入数据

1. 必要输入：

   * 每日（或更优：每火点）FRP（MODIS 或 QFED 提供的 FRP 聚合），以及 BBA（BC, POM）日发射量（Lu 用的是 QFED 的 daily BC/POM）。
   * 主模型环境场：温度、压强、密度、风场、PBL 高度（plume 模型在每个格点用这些做环境剖面）。
2. FRP bin 设置（Lu 实现可复用）：

   * 小：1–10 MW、中：10–100 MW、大：100–500 MW、极端：500–1000 MW（四个 bin），并为每格累计各 bin 的 FRP 总和并按比例分配 emissions。
3. 火强到热通量的标度：Lu 等按 Val Martin 等做法，假设热通量 ≈ **10 × MODIS FRP**（用于计算 buoyancy flux）。你也可以用相同标度。

---

## 2) 把 Freitas(2007) 模型代码加入（两条路径）

**A. 在线（在模型每小时调用 plume 模块）** — 与 Lu 等相同（推荐）

* 在 emissions driver / preprocessor 中增加一个子例程：对每个 model grid、每个 FRP bin，调用 Freitas 1-D 模型，输入：火的热通量下限/上限、活跃火半径（或火面积）、环境剖面（温度/密度/风/湿度）、entrainment coefficient α（默认 0.05），plume duration（默认 30 min）。模型返回 plume 注入高度剖面（vertical distribution / injection height）。Lu 的实现每格对四个 bin 计算上下界并把 emissions 在上下界之间均匀分配。
* 调用频率：**每小时**（E3SM 在 ne30 配置里 Lu 等每小时调用以节省开销）。

**B. 离线预算表 / 参数化（若在线算太慢）**

* 用 Ke et al. (2021) 样的 paramization（将离线大量 Freitas 模拟做成查表/经验公式），然后在线调用快速参数化（Lu 文中也提到这种替代）。若想快速开始可先用离线查找表再迁移到在线实现。

**实现提示（代码层面）**

* 如果你的 F2000 是基于 E3SM/CAM 家族：找 emissions driver（emissions/dynamic partition）和 fire-emissions 接口，把 plume 子例程放在 emissions 分配流程里，确保 model 在 hourly step 前得到 vertical emission profile。
* 若 F2000 没有现成 plume 模块，可以拿 WRF-Chem / Freitas 的 Fortran 实现参考（文中与 Grell et al. 2011 的 WRF-Chem 集成有关，可参考实现思路）。

---

## 3) 关键算法参数（直接复用 Lu 的设置）

* **entrainment coefficient α = 0.05**（Freitas 默认值）。
* **plume-rise duration**：默认 **30 min**（Lu 用此默认值；注意短时长会把烟柱限制在低层，5 min 会使 BBA 基本都在 <2km）。可以做敏感实验（5、30、60 min）。
* **火大小**：Lu 用“最大 MODIS-FRP 对应 1 km²”并对每 FRP bin 做尺度缩放（生成 look-up 表按 PFT/区域/月份的 max-FRP）。建议也生成类似 lookup 表。
* **heat flux scaling**：heat flux = **10 × FRP**（Val Martin 方法），用于计算 buoyancy。
* **FRP bin 上下界**：按 Lu 文的四 bin（见上）并对每个 bin 用几何平均作为本次 plume 的代表 FRP 来缩放子像元火尺寸。

---

## 4) Fire diurnal cycle（NUG_PLR 需要）

* Lu 在 NUG_PLR 实验中把 daily emissions 用一个固定 diurnal shape（Li et al. 2019 在 CONUS 的观测 diurnal，峰值在 local 14:00）按小时分配，并**在模型里关闭 emissions 的 temporal interpolation**（以避免 00UTC 带来的人工 diurnal）。你在复现时也要：

  1. 生成 daily→hourly 的分配函数（参考 Li et al. 2019 的形状或你所在域的观测）。
  2. 在 run script / emissions linker 里确保按小时直接读入/注入 hourly emissions（不要再做模型内部插值）。

---

## 5) 修改 run 脚本（例如你的 F2000_default.csh）

* 在 run 脚本中加入开关变量，例如 `USE_PLUME_RISE=.true.`、`USE_FIRE_DIURNAL=.true.`、`FRP_BIN_FILE=/path/to/lookup`，并确保在启动前把这些传到 model 的 namelist / configuration。Lu 的实验区分 NUG_CTL / NUG_NDC / NUG_PLR，通过改 namelist 控制 vertical profile 来源与火 diurnal 标志。
* 如果你要做 **NUG（nudged）** 实验，还需要把 U,V 流场 nudging 指向 MERRA-2，并把 relaxation timescale 设为 6 hr（Lu 的设置）。其它温湿不被 nudged。

---

## 6) 输出、分配与投放

* plume 模块输出：对每个格点、每个 FRP bin 应返回 **vertical fraction profile**（在 grid 的多层上分配）。把每个 bin 的 fraction × bin 内 emissions 加起来构成最终每层的 BBA 注入（Lu 把最低 bin 的 emissions 直接放在最低层以节省算力）。
* 频率：**小时输出** plume 结果（或至少在小时步调用并把每小时的 emission profiles 写出用于诊断）。

---

## 7) 验证 / 敏感试验（必须做）

1. **短期测试**：先做小区域（或单格）和短期（几天或 1 个月）试验，确认 plume 模块能跑通且输出合理（注入高度在物理范围）。
2. **NUG 一年试验**：复现 Lu 的 NUG_CTL、NUG_NDC、NUG_PLR 三组之一或三组对比（nudged to MERRA-2），对比 MISR plume-height product 与 WE-CAN 等实测资料来验证。Lu 使用 MISR 和 WE-CAN 验证并给出对比指标。
3. **参数敏感**：测试 plume-duration（5 vs 30 min）、α 值、FRP bin 边界、heat-flux scaling。Lu 文中指出这些设置会显著影响注入高度与地面 PM2.5。

---

## 8) 性能 & 工程注意

* 直接在线调用 Freitas 每小时每格做 4 个 plume 模拟计算量不小（Lu 也提到计算成本问题）。如果你发现太慢，可先用离线查表或只在有显著火源的格点触发 plume 计算（例如 FRP 总和超过阈值再调用）。
* Lu 为节省算力把最低 FRP bin（即小火）直接放最低层（认为为 smoldering）；可以先沿用这一策略。

---

# 参考 / 证据（来自你上传的 Lu et al. (2023)）

* Lu 等确实是把 Freitas (2007) 的 1-D plume-rise 接入 E3SM，并用 4 个 FRP bin + 每小时调用 + diurnal cycle 来生成 NUG_PLR / NUG_NDC / NUG_CTL 三个对比实验并用 MISR/WE-CAN 验证。
* 关键实现细节（heat flux scaling, FRP bins, entrainment α=0.05, plume-duration=30min, 每小时调用，diurnal cycle 来源 Li et al.）都在文中有明确说明。

---

# 快速行动计划（你可以立刻执行的最小可行工作流）

1. 准备 QFED（日）BC&POM + MODIS FRP（或 QFED 的 FRP 聚合），并生成每格每日各 FRP bin 的 FRP 汇总表与 daily emissions 文件。
2. 在 F2000 的 emissions driver 中加入一个 hourly hook：当格点有 FRP>阈值 时调用 plume 子例程（Freitas），否则用原始 vertical profile（或直接放底层）。
3. 用 Lu 的参数（4 bins, heat flux=10×FRP, α=0.05，plume-duration=30min, diurnal shape）跑一个 1 个月的 nudged（MERRA-2）测试。对比 MISR / （若在 NA）WE-CAN（Lu 的验证流程）。


