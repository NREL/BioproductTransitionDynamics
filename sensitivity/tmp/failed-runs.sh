#!/usr/bin/env bash

gawk 'BEGIN {FS="\t"; print "cp -nv ../BTD.mdl /xshare/6A20/Public/BushData/BTD/failed/"} FNR>1 {last[$1]=$2} END {for (run in last) if (last[run]!=2050) print "cp -nv run-" run ".cin /xshare/6A20/Public/BushData/BTD/failed/"}' ../outputs.tsv | bash
