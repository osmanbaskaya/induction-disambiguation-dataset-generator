#! /usr/bin/python
# -*- coding: utf-8 -*-
__author__ = "Osman Baskaya"

import sys
import gzip
import argparse
from collections import defaultdict as dd


def get_filtered_instances(data_fn, min_num_of_inst, min_iaa, lexicon, ignore_set):
    tw_dict = dd(list)
    for line in gzip.open(data_fn):
        parsed_line = line.split('\t')
        tw = parsed_line[0]
        sense_lexicon, iaa = parsed_line[5:7]
        if iaa >= min_iaa and sense_lexicon == lexicon and tw not in ignore_set:
            tw_dict[tw].append(line)

    instances = []
    total_inst = 0
    total_tw = 0
    for tw, inst in tw_dict.iteritems():
        if len(inst) >= min_num_of_inst:
            instances.extend(inst)
            total_inst += len(inst)
            total_tw += 1

    print >> sys.stderr, "Info for filtering:\nTotal # of tw:{}\tTotal # of instance:{}".format(total_tw, total_inst)
    return instances
    

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('input_data', metavar='input_data')
    parser.add_argument('--min-instance', help="Min. # of instance for a target word", 
                        type=int, default=1)
    parser.add_argument('--iaa', help="Min. IAA", type=float, default=0.0)
    parser.add_argument('--lexicon', default='3.0')
    parser.add_argument('--ignore-set', nargs='+', default=set(), help="While dataset construction, ignore the set of target words.")

    args = parser.parse_args()
    print >> sys.stderr, args

    instances = get_filtered_instances(args.input_data, args.min_instance, args.iaa, 
                                       args.lexicon, args.ignore_set)
    for instance in instances:
        print instance,


if __name__ == '__main__':
    main()
