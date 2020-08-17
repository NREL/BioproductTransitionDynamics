#!/usr/bin/env -S gawk -f

BEGIN {
  FS = "="
  OFS = "\t"
}

FNR == NR {
  inputs[$0] = 1
}

/=/ {
  active = 0
}

FNR != NR && $1 in inputs {
  input = $1
  active = 1   
}

active == 1 && /]/ {
  z = gensub("^.*\\[\\(.*\\)].*$", "\\1", "g")
  print input, z
}
