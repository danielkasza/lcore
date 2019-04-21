#!/bin/bash

set -e
#set -x

cd `dirname $0`

verilator --cc --exe main.cpp ../cpu.sv -I..

cd obj_dir
make -f Vcpu.mk
