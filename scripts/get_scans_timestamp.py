#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
from datetime import datetime, timedelta
import argparse



DESCRIPTION = """
Compute an accurate timestamps for each volume based on method files.
"""

EPILOG = """
Michael Paquette, MPI CBS, 2021.
"""

class CustomFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawTextHelpFormatter):
    pass

def buildArgsParser():

    p = argparse.ArgumentParser(description=DESCRIPTION,
                                epilog=EPILOG,
                                formatter_class=CustomFormatter)

    p.add_argument('method', type=str, nargs='+', default=[],
                   help='Path of the input method file(s) (one or more).')
    p.add_argument('output', type=str,
                   help='Path of the output.')
    return p


# read all lines and parse into list
def rawtext(fname):
    with open(fname, 'r') as f:
        return f.readlines()


# find a tag and grap everything until the next '$$' or '##'
def grab_tag(rawmethod, tag):
    # remove tag marker if there
    if tag[:3] == '##$':
        tag = tag[3:]
    # loop list until found
    tagindex = None
    for i,l in enumerate(rawmethod):
        if l[:len(tag)+3] == '##$' + tag:
            tagindex = i
            break
    if i is None:
        print('tag not found')
        return None
    # find the end of tag
    end_tag = None
    j = 1
    while end_tag is None:
        tmp = rawmethod[i+j][:2]
        if (tmp == '$$') or (tmp == '##'):
            end_tag = i+j
        j += 1
    
    return rawmethod[i:end_tag]


# parse single line float tag
def parse_tag_single_line_float(rawtag):
    return np.array([float(rawtag[0].strip().split('=')[-1])])


# parse multiline float tag
def parse_tag_multi_line_float(rawtag):
    arrayshape = tuple([int(n) for n in rawtag[0].strip().split('=')[-1][1:-1].split(',')])
    array1D = np.concatenate([np.array([float(n) for n in l.strip().split(' ')]) for l in rawtag[1:]])
    return array1D.reshape(arrayshape)


# parse multiline string tag
def parse_tag_multi_line_string(rawtag):
    return rawtag[1].strip()[1:-1]


# parse any tag using heuristic to decide between:
#     parse_tag_single_line_float
#     parse_tag_multi_line_float
#     parse_tag_multi_line_string
def parse_tag(rawtag):
    if len(rawtag) == 1:
        return parse_tag_single_line_float(rawtag)
    elif rawtag[1][0] == '<':
        return parse_tag_multi_line_string(rawtag)
    else:
        return parse_tag_multi_line_float(rawtag)


# convert the dates, durations and number of sub partitions 
# into time in seconds from start of experiment
# for linear (in time) fit
def timestamp_to_seconds(end_timestamp, durations, n_partitions):
    # end_timestamp is a list of datetime object with the end of the events
    # durations is a list timedelta object with the length of each event
    # n_partitions is a list with the number of even-lenght sub-events in each event
    time_zero = min([end_timestamp[i]-durations[i] for i in range(len(end_timestamp))])
    subevent_timestamp = []
    for i in range(len(end_timestamp)):
        sub_event_duration = durations[i] / n_partitions[i]
        tmp = [end_timestamp[i] - (j+0.5)*sub_event_duration for j in range(n_partitions[i]-1, -1, -1)]
        subevent_timestamp.append([(t-time_zero).total_seconds() for t in tmp])
    return subevent_timestamp


def main():
    parser = buildArgsParser()
    args = parser.parse_args()


    end_timestamp = []
    durations = []
    n_partitions = []

    for fname in args.method:
        print(fname)
        rawmethod = rawtext(fname)

        # locate ##OWNER tag to find end of scan timestamp
        end_timestamp_line_index = np.argwhere([l[:7]=='##OWNER' for l in rawmethod])[0][0] + 1
        date_time_str = ' '.join(rawmethod[end_timestamp_line_index].split(' ')[1:3]) # strip non date part
        date_time_obj = datetime.strptime(date_time_str, '%Y-%m-%d %H:%M:%S.%f') # parse date with 4 digit year and miliseconds
        # print(date_time_obj)
        end_timestamp.append(date_time_obj)



        # locate PVM_ScanTimeStr for scan duration
        delta_time_str = parse_tag(grab_tag(rawmethod, 'PVM_ScanTimeStr'))
        # parse into deltatime
        tmp_boundary = [s.isdigit() for s in delta_time_str]
        breaks = [0]
        for i in range(len(tmp_boundary)-1):
            if not tmp_boundary[i] and tmp_boundary[i+1]: # looking for False-True
                breaks.append(i+1)
        breaks.append(None)

        # since the PVM_ScanTimeStr doesnt always have the same element
        # we parse and use **kwargs to create timedelta object
        timetag = {'d': 'days', 'h': 'hours', 'm': 'minutes', 's': 'seconds', 'ms': 'microseconds'}
        duration = {}
        for i in range(len(breaks)-1):
            # print(delta_time_str[breaks[i]:breaks[i+1]])

            el_list = delta_time_str[breaks[i]:breaks[i+1]]
            type_list = tmp_boundary[breaks[i]:breaks[i+1]]

            tmp1 = int(''.join([el_list[j] for j in range(len(el_list)) if type_list[j]]))
            tmp2 = ''.join([el_list[j] for j in range(len(el_list)) if not type_list[j]])

            duration[timetag[tmp2]] = tmp1

        delta_time_obj = timedelta(**duration)
        # print(delta_time_obj)
        durations.append(delta_time_obj)



        # not required if we only use budde sequence
        # but this could be use to return a 1 for non existing field
        # def get_val(rawmethod, tag):
        #   try:
        #       rawtag = grab_tag(rawmethod, tag)
        #       val = parse_tag(rawtag)
        #   except IndexError:
        #       val = np.array([1])
        #   return val


        # to estimate de total number of volume,
        # we multiply echos, repetitions, bvalue, bshape and bvecs
        # we can ignore average since they are internally averaged
        NEcho = parse_tag(grab_tag(rawmethod, 'PVM_NEchoImages'))[0]
        NRep = parse_tag(grab_tag(rawmethod, 'PVM_NRepetitions'))[0]
        Nbvec = parse_tag(grab_tag(rawmethod, 'DwNDirs'))[0]
        Nbval = parse_tag(grab_tag(rawmethod, 'DwNAmplitudes'))[0]
        # this is most likely wrong, I don't know how multiple waveform shape are stored in the method
        Nbshape = len(parse_tag(grab_tag(rawmethod, 'DwDynGradShapeEnum1')).split(' '))

        Nvol = int(NEcho * NRep * Nbvec * Nbval * Nbshape)  
        # print(Nvol)
        n_partitions.append(Nvol)


    # this is a list of list for all individual event
    time_for_drift_corr = timestamp_to_seconds(end_timestamp, durations, n_partitions)
    # we flatten the list
    time_for_drift_corr = np.array([item for sublist in time_for_drift_corr for item in sublist])


    np.savetxt(args.output, time_for_drift_corr, fmt='%d')


if __name__ == "__main__":
    main()

