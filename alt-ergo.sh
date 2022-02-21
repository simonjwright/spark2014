#!/bin/sh

source common.sh

PREFIX=$PWD/install/libexec/spark

cd alt-ergo

opam install alt-ergo

cp $HOME/.opam/default/bin/alt-ergo $PREFIX/bin

