
import numpy   as np
import os      as os
import pandas  as pd
import Vensim  as vs


v = vs.Vensim(
    "simulation",
     1,
     mdl_name="BTD.mdl",
     executable="wine vensim/vensimdp.exe"
)

v.make_cmd()

v.make_lst(list(pd.read_csv("outputs.lst", header = None)[0].values))


inputs = pd.read_csv("inputs.tsv", sep = "\t").set_index("Run")


results = None

for i, row in inputs.iterrows():
  v.make_cin(dict(row.iteritems()))
  try:
    v.run_vensim()
    result = v.read_tsv()
    result["Run"] = i
    results = result.set_index(["Run", "Time"]).append(results, sort = False)
    if i % 50 == 0:
      results.to_csv("outputs.tsv", sep = "\t")
  except:
    None

results.sort_index().to_csv("outputs.tsv", sep = "\t")
