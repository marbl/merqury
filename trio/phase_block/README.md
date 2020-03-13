# Build bedMerToPhaseBlock.jar

This is provided for manually building the bedMerToPhaseBlock.jar when needed.


After editing MerToPhaseBlock.java, run `build_jar.sh`.
It does the following:

```
mkdir -p bin	# where all the .class files will go

javac -d bin ./*.java ./*/*.java ./*/*/*.java	# compile

jar -cfe bedMerToPhaseBlock.jar MerToPhaseBlock bin/MerToPhaseBlock.class -C bin/ bin/bed/util/ bin/genome/ bin/IO/ bin/IO/basic/	# make a jar

rm -r bin	# remove the .class files
```

Test run with

```
java -jar -Xmx128m bedMerToPhaseBlock.jar
```

A help message should be displayed.
