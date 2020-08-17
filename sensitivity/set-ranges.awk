BEGIN {
  FS = "\t"
  OFS = FS
}

FNR == 1 {
  print $0, "Sensitivity Minimum", "Sensitivity Maximum", "Sensitivity Default"
}

FNR > 1 {
  smin = $4 == "?" ? 0.60 * $6 : ($4 + 0.60 * $6) / 2
  smax = $5 == "?" ? 1.60 * $6 : ($5 + 1.60 * $6) / 2
  print $0, smin, smax, $6
}
