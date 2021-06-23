INPUT=$1
OUTPUT=$2
PATH_SET_VARIABLES=$3

INPUT_DIR=$(dirname "${INPUT}")

source ${PATH_SET_VARIABLES}

mkdir -p ${INPUT_DIR}/tmp_degibbs_in/
mkdir -p ${INPUT_DIR}/tmp_degibbs_out/


${FSL_LOCAL}/fslsplit \
	${INPUT} \
	${INPUT_DIR}/tmp_degibbs_in/


for i in ${INPUT_DIR}/tmp_degibbs_in/*;
do
	i_File=$(basename "${i}")

	${MRDEGIBBS3D} -force -quiet \
		${INPUT_DIR}/tmp_degibbs_in/${i_File} \
		${INPUT_DIR}/tmp_degibbs_out/${i_File} 
done


${FSL_LOCAL}/fslmerge -t \
	${OUTPUT} \
	${INPUT_DIR}/tmp_degibbs_out/*

rm -rf ${INPUT_DIR}/tmp_degibbs*
