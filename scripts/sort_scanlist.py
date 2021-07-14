import argparse
import numpy as np
import os


DESCRIPTION =   """
Put some ordering in the strange Bruker Scanlist
Cornelius Eichner 2021
"""


def func(elem):
    try:
        num = int(elem.split(' (E')[1].split(')>')[0])
    except:
        num = np.nan    
    return num

def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument('--in', dest='input', action='store', type=str,
                            help='Name of the input SCANLIST file')

    p.add_argument('--out', dest='output', action='store', type=str,
                            help='Name of the output SCANLIST file')

    return p


def main():

    # Load parser to read data from command line input
    parser = buildArgsParser()
    args = parser.parse_args()

    # Load input variables
    PATH_IN = os.path.realpath(args.input)
    PATH_OUT = os.path.realpath(args.output)
    
    with open(PATH_IN) as f:
        content = f.readlines()

    content = [x.strip() for x in content] # remote newlines

    # Extract Scan Numbers from ' (E??)>' Format
    scan_numbers = []
    for i_scan,scan in enumerate(content):
        scan_numbers.append(func(scan))

    content_array = np.array(content, dtype=np.object)
    content_array_sort = np.array(list(filter(None, content_array[np.argsort(scan_numbers)])), dtype=np.object)
    
    np.savetxt(PATH_OUT, content_array_sort, fmt="%s")


if __name__ == '__main__':
    main()
