#!/usr/bin/env python3

import csv, yaml
import sys


class MyDumper(yaml.Dumper):

    def increase_indent(self, flow=False, indentless=False):
        return super(MyDumper, self).increase_indent(flow, False)


def main():
  data = {'users': []}
  with open(sys.argv[1], 'r') as csv_file:
    csv_reader = csv.reader(csv_file)
    header = next(csv_reader)
    for counter, row in enumerate(csv_reader):
      new_entry = {}
      for counter2, title in enumerate(header):
        new_entry[title.strip()] = row[counter2].strip()
      data['users'].append(new_entry)
    yaml.dump(data,sys.stdout,Dumper=MyDumper, default_flow_style=False)


if __name__ == "__main__":
  main()

