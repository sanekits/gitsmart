# Recommended settings
git config --global column.ui auto
git config --global branch.sort -committerdate
git config --global tag.sort version:refname
git config --global init.defaultBranch main
git config --global diff.algorithm histogram
git config --global diff.colorMoved plain
git config --global diff.mnemonicPrefix true
git config --global diff.renames true
git config --global push.default simple
git config --global push.autoSetupRemote true
git config --global push.followTags true
git config --global fetch.prune true
git config --global fetch.pruneTags true
git config --global fetch.all true
git config --global help.autocorrect prompt
git config --global commit.verbose true
git config --global rerere.enabled true
git config --global rerere.autoupdate true
git config --global core.excludesfile ~/.gitignore
git config --global rebase.autoSquash true
git config --global rebase.autoStash true
git config --global rebase.updateRefs true

# Optional / personal taste
# Uncomment to enable

# git config --global core.fsmonitor true
# git config --global core.untrackedCache true
# git config --global merge.conflictstyle zdiff3
# git config --global pull.rebase true
