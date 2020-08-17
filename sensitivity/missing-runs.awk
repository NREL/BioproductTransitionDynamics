#!/usr/bin/gawk -f

BEGIN {
  FS = "\t"
}

NR == 1 {
  print
}

FNR == NR && FNR > 1 {
  last[$1] = 0
  inputs[$1] = $0
}

FNR != NR && FNR > 1 {
  last[$1] = $2
}

END {
  for (run in last)
    if (last[run] != 2050)
      print inputs[run]
}
