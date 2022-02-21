#!/bin/sh

source common.sh

PREFIX=$PWD/install/libexec/spark

cd cvc4

antlr3=deps/install/bin/antlr3
test -f $antlr3 -a -x $antlr3 || contrib/get-antlr-3.4

CC=gcc CXX=g++                                  \
    ./configure.sh                              \
    --prefix=$PREFIX                            \
    --gpl                                       \
    --gmp-dir=$COMPILER

cd build

make

make install

install_name_tool                               \
  -change                                       \
  @rpath/libcvc4parser.7.dylib                  \
  @executable_path/../lib/libcvc4parser.7.dylib \
  $PREFIX/bin/cvc4

install_name_tool                               \
  -change                                       \
  @rpath/libcvc4.7.dylib                        \
  @executable_path/../lib/libcvc4.7.dylib       \
  $PREFIX/bin/cvc4
