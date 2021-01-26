#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse 
import glob
import os

DESCRIPTION =   'Apply Eddy Warps to split data. Cornelius Eichner 2020'
FSL_LOCAL = '/data/pt_02101_dMRI/software/fsl6/bin/'

def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument('--split_folder', dest='split', action='store', type=str,
                            help='Folderpath containing the split data')

    p.add_argument('--warp_folder', dest='warp', action='store', type=str,
                            help='Folderpath containing warp fields')

    p.add_argument('--jac_folder', dest='jac', action='store', type=str,
                            help='Folderpath to save the jacobian determinants')

    p.add_argument('--out_folder', dest='output', action='store', type=str,
                            help='Folderpath of the output folder')
    return p


def main():

    # Load parser to read data from command line input
    parser = buildArgsParser()
    args = parser.parse_args()

    # Load input variables
    PATH_SPLIT_DATA 		= os.path.realpath(args.split) + '/'
    PATH_WARP_FIELDS 		= os.path.realpath(args.warp) + '/'
    PATH_JAC_DETERMINANTS 	= os.path.realpath(args.jac) + '/'
    PATH_OUT        		= os.path.realpath(args.output) + '/'
    

    # Create Temporary Path for Non Jacobi Modulated Warped Data
    PATH_OUT_BEFOREJAC = PATH_OUT + '/tmp/'
    cmd = 'mkdir -p ' + PATH_OUT_BEFOREJAC
    os.system(cmd)

    # Create File lists in folders
    FILES_SPLIT_DATA 		= sorted(os.listdir(PATH_SPLIT_DATA))
    FILES_WARP_FIELDS 		= sorted(os.listdir(PATH_WARP_FIELDS))
    FILES_JAC_DETERMINANTS 	= sorted(os.listdir(PATH_JAC_DETERMINANTS))

    # Apply individual warps to split data
    for i in range(len(FILES_SPLIT_DATA)):
        cmd = FSL_LOCAL + '/applywarp \
                -i ' + PATH_SPLIT_DATA + str(FILES_SPLIT_DATA[i]) + ' \
                -r ' + PATH_SPLIT_DATA + str(FILES_SPLIT_DATA[0]) + ' \
                -o ' + PATH_OUT_BEFOREJAC + str(FILES_SPLIT_DATA[i]) + ' \
                -w ' + PATH_WARP_FIELDS + str(FILES_WARP_FIELDS[i]) + ' \
                --interp=spline \
                --datatype=float' 
        
        print('Warping Volume {} / {}'.format(i, len(FILES_SPLIT_DATA)))
        
        # print(cmd)
        os.system(cmd)

    ######################
    # Correct for warp signal bias using Jacobian determinante
    os.system("echo Correction of signal intensities with Jacobian Determinant")

    for i in range(len(os.listdir(PATH_WARP_FIELDS))):
        cmd = FSL_LOCAL + '/fslmaths ' + PATH_OUT_BEFOREJAC + '/' + FILES_SPLIT_DATA[i] + ' -mul  ' + PATH_JAC_DETERMINANTS + '/' + FILES_JAC_DETERMINANTS[i] + ' ' + PATH_OUT + FILES_SPLIT_DATA[i]

        # print(cmd)
        os.system(cmd)


if __name__ == '__main__':
    main()
