#!/bin/bash
# Simple QFED file checker using ncdump (no Python dependencies)
# Usage: bash check_qfed_simple.sh /path/to/qfed/file.nc4

if [ $# -eq 0 ]; then
    echo "Usage: bash check_qfed_simple.sh /path/to/qfed/file.nc4"
    exit 1
fi

FILEPATH=$1

echo "======================================================================"
echo "Checking QFED file: $FILEPATH"
echo "======================================================================"
echo ""

# Check if file exists
if [ ! -f "$FILEPATH" ]; then
    echo "ERROR: File does not exist: $FILEPATH"
    exit 1
fi

echo "1. File Information:"
echo "----------------------------------------------------------------------"
ls -lh "$FILEPATH"
echo ""

echo "2. NetCDF Header (dimensions, variables, attributes):"
echo "----------------------------------------------------------------------"
ncdump -h "$FILEPATH" 2>&1
echo ""

echo "======================================================================"
echo "3. CESM Configuration Suggestion:"
echo "======================================================================"
echo ""
echo "Based on the variable names above, add to user_nl_cam:"
echo ""
echo "Common QFED variable name is 'biomass'"
echo ""
echo "Example configuration:"
echo ""
cat << 'EOF'
srf_emis_specifier = 'bc_a4  -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_bc.061.%y%m%d.nc4:biomass',
                     'pom_a4 -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_oc.061.%y%m%d.nc4:biomass',
                     'SO2    -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_so2.061.%y%m%d.nc4:biomass',
                     'CO     -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_co.061.%y%m%d.nc4:biomass',
                     'NO     -> /share/home/ywliu/lxyyy/data/QFED/qfed2.emis_no.061.%y%m%d.nc4:biomass'
EOF
echo ""
echo "Replace 'biomass' with the actual variable name shown in the header above"
echo ""
echo "======================================================================"
echo "4. Check File Completeness for July 2018:"
echo "======================================================================"
echo ""

QFED_DIR=$(dirname "$FILEPATH")
MISSING_COUNT=0

echo "Checking files in: $QFED_DIR"
echo ""

for species in bc oc so2 co no; do
    echo "Checking $species files:"
    for day in {01..31}; do
        FILE="${QFED_DIR}/qfed2.emis_${species}.061.201807${day}.nc4"
        if [ ! -f "$FILE" ]; then
            echo "  MISSING: qfed2.emis_${species}.061.201807${day}.nc4"
            MISSING_COUNT=$((MISSING_COUNT + 1))
        fi
    done
done

echo ""
if [ $MISSING_COUNT -eq 0 ]; then
    echo "OK - All files present for July 2018!"
else
    echo "WARNING - $MISSING_COUNT files missing"
fi

echo ""
echo "======================================================================"
echo "Check completed!"
echo "======================================================================"
