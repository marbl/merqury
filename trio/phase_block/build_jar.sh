#!/bin/bash

echo "Re build bedMerToPhaseBlock.jar"
echo
echo "This script is provided for manually building the bedMerToPhaseBlock.jar when needed."

mkdir -p bin

javac -d bin ./*.java ./*/*.java ./*/*/*.java

jar -cfe bedMerToPhaseBlock.jar MerToPhaseBlock bin/MerToPhaseBlock.class -C bin/ bin/bed/util/ bin/genome/ bin/IO/ bin/IO/basic/

rm -r bin
