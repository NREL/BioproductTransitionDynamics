
import numpy    as np
import os       as os
import pandas   as pd
import platform as pl
import Vensim   as vs

from subprocess import TimeoutExpired


v = vs.Vensim(
    "simulation",
     5,
     mdl_name = "BTD.mdl",
     executable = "wine vensim/vensimdp.exe" if pl.system() == "Linux" else "c:\\Program Files (x86)\\Vensim\\vensimdp.exe",
)

v.make_cmd()

v.make_lst(list(pd.read_csv("outputs.lst", header = None)[0].values))


inputs = pd.read_csv("inputs.tsv", sep = "\t").set_index("Run")


results = None
if os.path.exists("outputs.tsv"):
  os.remove("outputs.tsv")

for i, row in inputs.iterrows():
  v.make_cin(dict(row.iteritems()))
  try:
    v.run_vensim(timeout = 15)
    result = v.read_tsv()
    result["Run"] = i
    results = result.set_index(["Run", "Time"]).append(results, sort = False)
    if i % 50 == 0:
      results.to_csv("outputs.tsv", sep = "\t")
  except (vs.VensimFailed, TimeoutExpired):
    pass
  os.rename("simulation.cin", "tmp/run-" + str(i) + ".cin")

results.sort_index().to_csv("outputs.tsv", sep = "\t")
