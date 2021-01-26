#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import numpy as np 
import os


DESCRIPTION =   'Create Fake Eddy Index and Acqp Files'

def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)

    p.add_argument('--folder', dest='folder', action='store', type=str,
                            help='Forder to Save Fake Eddy Files')

    p.add_argument('--Ndir', dest='Ndir', action='store', type=int,
                            help='Number of Diffusion Directions')

    p.add_argument('--TE', dest='TE', action='store', type=float,
                            help='Acquisition Echo Time')

    p.add_argument('--PE', dest='PE', action='store', type=float,
                            help='Phase Encoding Direction, 1 or -1')

    return p

def main():
    parser = buildArgsParser()
    args = parser.parse_args()

    # Load input variables
    FOLDEROUT = os.path.realpath(args.folder)
    TE = args.TE
    N = args.Ndir
    PE = args.PE

    if int(np.abs(PE)) != 1:
        print('Change PE direction to 1 or -1')

    np.savetxt(FOLDEROUT + '/index', np.ones(N).astype(int), fmt='%i')
    np.savetxt(FOLDEROUT + '/acqp', np.array([[PE * 1, 0, 0, TE]]), fmt='%.5f')


if __name__ == '__main__':
    main()
