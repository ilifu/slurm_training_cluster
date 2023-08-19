#!/bin/bash
packer inspect . | grep "var\." | sed 's/var\.//' | sed 's/: / = /' | sed 's/\(.*\)/# \1/'> variables.auto.hcl.template

