BEGIN {
  FS="\t"
  print "SPECIAL>NOINTERACTION"
  print "SPECIAL>LOADMODEL|BTD.mdl"
  print "SIMULATE>RUNNAME|debugging.vdf"
}

FNR > 1 {
  last[$1]=$2
}

END {
  good = 0
  for (run in last) {
    if (last[run] == 2050)
      good = run
    else if (run == good + 1) {
      print "SPECIAL>CLEARRUNS"
      print "SIMULATE>READCIN|tmp\\run-" run ".cin"
      print "MENU>RUN|o"
    }
  }
}
