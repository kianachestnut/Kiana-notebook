#!/bin/bash
# CESM运行诊断脚本
# 使用方法: bash diagnose_cesm.sh

echo "======================================================================"
echo "CESM运行诊断 - F2000_control"
echo "======================================================================"
echo ""

# 定义路径
CASEROOT="/share/home/ywliu/lxyyy/scratch/cesmrun/F2000_control"
RUNDIR="/share/home/ywliu/lxyyy/scratch/runout/F2000_control"
CCSMROOT="/share/home/minghuai/yliang/model/CESM2-release-2.1.0"

# 1. 检查case目录
echo "1. 检查case目录"
echo "----------------------------------------------------------------------"
if [ -d "$CASEROOT" ]; then
    echo "✓ Case目录存在: $CASEROOT"
    ls -lh $CASEROOT | head -10
else
    echo "✗ Case目录不存在: $CASEROOT"
    echo "  可能原因:"
    echo "  - create_newcase失败"
    echo "  - 路径权限问题"
    echo "  - 脚本执行被中断"
fi
echo ""

# 2. 检查运行目录
echo "2. 检查运行目录"
echo "----------------------------------------------------------------------"
if [ -d "$RUNDIR" ]; then
    echo "✓ 运行目录存在: $RUNDIR"
    
    # 检查子目录
    if [ -d "$RUNDIR/run" ]; then
        echo "  ✓ run目录存在"
        echo "  文件数量: $(ls $RUNDIR/run 2>/dev/null | wc -l)"
    else
        echo "  ✗ run目录不存在"
    fi
    
    if [ -d "$RUNDIR/bld" ]; then
        echo "  ✓ bld目录存在"
    else
        echo "  ✗ bld目录不存在"
    fi
else
    echo "✗ 运行目录不存在: $RUNDIR"
fi
echo ""

# 3. 检查日志文件
echo "3. 检查日志文件"
echo "----------------------------------------------------------------------"
if [ -d "$CASEROOT" ]; then
    # 查找最新的日志文件
    echo "Case日志文件:"
    ls -lht $CASEROOT/*.log 2>/dev/null | head -5
    echo ""
    
    # 查找错误日志
    echo "CaseDoc中的配置:"
    ls -lh $CASEROOT/CaseDocs/ 2>/dev/null | head -5
    echo ""
    
    # 检查构建日志
    if [ -d "$RUNDIR/bld" ]; then
        echo "构建日志:"
        ls -lht $RUNDIR/bld/*.log 2>/dev/null | head -3
    fi
    echo ""
    
    # 检查运行日志
    if [ -d "$RUNDIR/run" ]; then
        echo "运行日志:"
        ls -lht $RUNDIR/run/*.log* 2>/dev/null | head -5
    fi
else
    echo "Case目录不存在,无法检查日志"
fi
echo ""

# 4. 检查作业状态
echo "4. 检查作业队列状态"
echo "----------------------------------------------------------------------"
echo "当前用户的作业:"
squeue -u $(whoami) 2>/dev/null || qstat -u $(whoami) 2>/dev/null || echo "无法查询作业队列"
echo ""

# 5. 检查最近的错误
echo "5. 检查最近的错误信息"
echo "----------------------------------------------------------------------"
if [ -d "$CASEROOT" ]; then
    # case.run日志
    if [ -f "$CASEROOT/case.run" ]; then
        echo "检查case.run脚本..."
        tail -20 $CASEROOT/case.run 2>/dev/null
    fi
    
    # 查找ERROR关键字
    echo ""
    echo "查找日志中的ERROR:"
    find $CASEROOT -name "*.log" -type f -exec grep -l "ERROR" {} \; 2>/dev/null | head -5
    echo ""
    
    # 显示最新日志的最后几行
    LATEST_LOG=$(find $CASEROOT -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -f2- -d" ")
    if [ -n "$LATEST_LOG" ]; then
        echo "最新日志文件: $LATEST_LOG"
        echo "最后20行:"
        tail -20 "$LATEST_LOG"
    fi
fi
echo ""

# 6. 检查编译状态
echo "6. 检查编译状态"
echo "----------------------------------------------------------------------"
if [ -d "$RUNDIR/bld" ]; then
    # 检查可执行文件
    echo "可执行文件:"
    find $RUNDIR/bld -name "cesm.exe" -o -name "*.exe" 2>/dev/null
    
    # 检查编译日志
    if [ -f "$RUNDIR/bld/cesm.bldlog" ]; then
        echo ""
        echo "编译日志最后50行:"
        tail -50 $RUNDIR/bld/cesm.bldlog
    fi
fi
echo ""

# 7. 检查关键配置
echo "7. 检查关键配置文件"
echo "----------------------------------------------------------------------"
if [ -d "$CASEROOT" ]; then
    echo "env_run.xml中的关键设置:"
    if [ -f "$CASEROOT/env_run.xml" ]; then
        grep -E "RUN_STARTDATE|STOP_N|STOP_OPTION" $CASEROOT/env_run.xml
    fi
    echo ""
    
    echo "user_nl_cam内容:"
    if [ -f "$CASEROOT/user_nl_cam" ]; then
        cat $CASEROOT/user_nl_cam
    else
        echo "user_nl_cam文件不存在"
    fi
fi
echo ""

# 8. 磁盘空间检查
echo "8. 检查磁盘空间"
echo "----------------------------------------------------------------------"
df -h /share/home/ywliu/ 2>/dev/null || df -h /share/ 2>/dev/null
echo ""

# 9. 权限检查
echo "9. 检查目录权限"
echo "----------------------------------------------------------------------"
echo "用户: $(whoami)"
echo "用户组: $(groups)"
echo ""
if [ -d "$CASEROOT" ]; then
    ls -ld $CASEROOT
fi
if [ -d "$RUNDIR" ]; then
    ls -ld $RUNDIR
fi
echo ""

# 10. 给出建议
echo "======================================================================"
echo "诊断建议"
echo "======================================================================"
echo ""

if [ ! -d "$CASEROOT" ]; then
    echo "🔴 Case目录不存在 - 可能原因:"
    echo "   1. create_newcase命令失败"
    echo "   2. 需要检查: cat /share/home/ywliu/lxyyy/scratch/cesmrun/case.setup.log"
    echo "   3. 手动尝试运行:"
    echo "      cd $CCSMROOT/cime/scripts"
    echo "      ./create_newcase --case $CASEROOT --mach hpcc --res f09_f09_mg17 --compset F2000climo --compiler intel --queue mpi --walltime 01:00 --run-unsupported"
    echo ""
elif [ ! -d "$RUNDIR/bld" ]; then
    echo "🟡 Case创建成功,但编译目录不存在"
    echo "   可能在case.setup或case.build阶段失败"
    echo "   检查: $CASEROOT/case.setup.log"
    echo "   检查: $CASEROOT/case.build.log"
    echo ""
elif [ ! -d "$RUNDIR/run" ]; then
    echo "🟡 编译可能完成,但运行目录不存在"
    echo "   可能在case.submit之前就失败了"
    echo "   检查: $CASEROOT/case.build.log"
    echo ""
else
    echo "✓ 目录结构看起来正常"
    echo "  检查作业是否在队列中运行"
    echo "  检查运行日志: $RUNDIR/run/*.log"
    echo ""
fi

echo "======================================================================"
echo "下一步操作建议"
echo "======================================================================"
echo ""
echo "如果case.setup失败:"
echo "  cd $CASEROOT"
echo "  ./case.setup 2>&1 | tee setup.log"
echo ""
echo "如果case.build失败:"
echo "  cd $CASEROOT"
echo "  ./case.build --skip-provenance-check 2>&1 | tee build.log"
echo ""
echo "如果case.submit失败:"
echo "  cd $CASEROOT"
echo "  ./case.submit 2>&1 | tee submit.log"
echo ""
echo "查看详细错误:"
echo "  tail -100 $CASEROOT/*.log"
echo ""
