#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh

# Generate New Scanlist File
>SCANLIST.txt

# Loop over directories in Bruker raw folder
for Scan in ${BRUKER_RAW_DIR}/*/; do
    if test -f "${Scan}/acqp"; then
        echo "Scanning File $Scan";
        python3 ${SCRIPTS}/print_scan_name.py "${Scan}/acqp" >> SCANLIST.txt
    fi
done

mv SCANLIST.txt ${CONFIG_DIR}/SCANLIST_unsorted.txt

python3 ${SCRIPTS}/sort_scanlist.py --in ${CONFIG_DIR}/SCANLIST_unsorted.txt --out SCANLIST.txt

echo $0 " Done" 