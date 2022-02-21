#!/bin/sh

source common.sh

PREFIX=$PWD/install/libexec/spark

cd z3

rm -rf build

CC=gcc CXX=g++                                  \
    python scripts/mk_make.py                   \
    --prefix=$PREFIX                            \
    --gmp

cd build

make

make install
