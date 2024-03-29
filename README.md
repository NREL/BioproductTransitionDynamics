# Bioproducts Transition System Dynamics

This is the repository for all model development and analysis activities for the Bioproduct Transition Dynamics (BTD) model.

## Organization 

The primary model is `BTD.mdl`. Please make every effort to keep this model running after every commit where the model is changed.

Models under development and not yet integrated into BTD.mdl are stored in `/submodels`.

Files defining model inputs for analysis are stored in `/inputs`.

Vensim result files with extension `.vdf` are stored in `/result-files` unless they are the most current set of results, in which case they are stored in the top directory. Use care in naming older results files, and remove any that are no longer relevant.

Vensim results files are by default tracked in this repo. To have a VDF file ignored by the repo, name it with the ending `-local.vdf`. The majority of VDF files should be stored locally only, not in the repo.

## Committing

Use the command `git status` to see files that have been changed since the last commit, and create multiple commits if multiple files have been edited in different ways. Commits to `.mdl` files should be the result of some observable change to the model.

Make your commit messages brief but explanatory. Add comments to your commits if necessary. If a commit addresses or closes an issue, tag the issue in the commit message using a hashtag and the issue number, for instance `#31`.

Vensim will frequently save new versions of a model when the model has only been opened and closed without any edits. Do not commit these changes; instead use the command `git checkout -- BTD.mdl` (changing the file name as needed) to reset the model to its previous versions.

## Branching

The two branches that should (until the final model lock) remain in the repo are `master` and `dev`. `master` should always have a working copy of the BTD that gives correct results to our best knowledge. Small model changes can be made directly in `dev`, and we will pull `dev` into `master` regularly to keep our working BTD copy as up to date as possible. Larger model changes that will temporarily break the model or take multiple days to complete - for instance, when integrating a submodel into the BTD or when resolving a complex issue - should begin with a new branch off `dev`. Give the branch an explanatory name. Once BTD.mdl is running in the branch and related development is complete, create a pull request to pull the branch into `dev` and assign at least one reviewer.

## Repo contents

Only the model itself, models under development, key results files, and any files necessary for running sensitivity and other analyses may be stored in this repo. All other files should be stored elsewhere.
