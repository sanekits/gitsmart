# make-kit.mk for gitsmart
#  This makefile is included by the root shellkit Makefile
#  It defines values that are kit-specific.
#  You should edit it and keep it source-controlled.

# TODO: update kit_depends to include anything which
#   might require the kit version to change as seen
#   by the user -- i.e. the files that get installed,
#   or anything which generates those files.
kit_depends := \
    bin/gitsmart.bashrc \
    bin/gitsmart.sh

.PHONY: publish

publish-common: conformity-check

publish: pre-publish publish-common release-upload release-list
	cat tmp/draft-url
	@echo ">>>> publish complete OK. (FINAL)  <<<"

# We have a tree-setup dependency on diff-so-fancy, so that keeps it
# up-to-date with the upstream source.  The only thing needed is
# the raw perl script and its lib/ subdir, so we're not putting those
# into our git tree (see bin/.gitignore)
tree-setup: tmp/diff-so-fancy.update-semaphore
tmp/diff-so-fancy.update-semaphore:
	@
	rm -rf ${TMPDIR}/diff-so-fancy &>/dev/null || :
	git clone https://github.com/so-fancy/diff-so-fancy ${TMPDIR}/diff-so-fancy
	cp ${TMPDIR}/diff-so-fancy/diff-so-fancy bin/diff-so-fancy
	cp -r ${TMPDIR}/diff-so-fancy/lib bin/
	touch $@
