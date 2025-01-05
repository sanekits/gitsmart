#!/bin/bash
# gitsmart.bashrc - shell init file for gitsmart sourced from ~/.bashrc

gitsmart-semaphore() {
    [[ 1 -eq  1 ]]
}


function gitsmart_yellow {
    echo -en "\033[;33m" >&2
    echo "$@" >&2
    echo -en "\033[;0m" >&2
}


git-find-root() {
    #help Shows the root path for current repo
    command git rev-parse --show-toplevel 2>/dev/null
}

# Set this to false elsewhere if you don't want the slight delay of checking
# git branches all the time:
PS1_INCLUDE_GIT_BRANCH=${PS1_INCLUDE_GIT_BRANCH:-true}
parse_git_branch() {
    if $PS1_INCLUDE_GIT_BRANCH; then
        command git branch 2> /dev/null | command sed -e '/^[^*]/d' -e 's/* \(.*\)/[\1]/'
    fi
    }

git_commit_review() {
    #help Review commits before adding to index
    ( command which code && command code -s | command grep -q Version ) &>/dev/null
    [[ $? -ne 0 ]] && {
        echo "Sorry, vscode not running."; false; return;
    }
    (
        command code changes;
    )
    command git add .
    command git diff --cached
    builtin read -n 1 -p "Commit now with ~/changes as message? [y/N]: "
    if [[ $REPLY =~ [yY] ]]; then
        command git commit -F ~/changes
    fi
}
alias gcr='git_commit_review'

git_remote_show() {
    #help Show all remotes
    local allremotes
    allremotes="$(command git remote show)"
    local remotes="$*"
    remotes=${remotes:-${allremotes}}  # Get all remotes if caller doesn't specify
    command git remote show ${remotes}
    printf " ------------\nRepo root is:\n"
    echo "    $(git-find-root)"
    command git branch -vv
}

git_show_urls() {
    git-remote-show-urls.sh "$@"
}
alias gurl=git_show_urls
#help Show URLs for this repo

git_attributes_init() {
    [[ -d .git ]] || return "$(errExit No .git/ here)"
    [[ -f .gitattributes ]] && return "$(errExit "Already has a .gitattributes here")"
    cp ${HOME}/bin/gitattributes-template .gitattributes || return $(errExit failed to create .gitattributes)
    echo ".gitattributes added to $PWD"
}

git_branch_diff_file() {
    # Compare one or more local files with peers on branch $GbrDiff, e.g. "GbrDiff=feature/br1 git_branch_diff_file README.md hello.cpp"
    [[ -z $GbrDiff ]] && return $(errExit "No \$GbrDiff set. Try GbrDiff=name/of/reference/branch")
    for file in "$@"; do
        echo "Diff for ${file} vs ${GbrDiff}:${file} -> "
        vimdiff ${file} <(git show ${GbrDiff}:${file})
    done
}

git_diff_fancy() {
    #help Use diff-so-fancy to view git diff output
    if which diff-so-fancy &>/dev/null; then
        # Use diff-so-fancy and less to magicalize it:
        command git diff --color "$@" | diff-so-fancy | less --tabs=4 -RFXS --pattern '^(Date|added|deleted|modified): '
    else
        command git diff --color "$@" | less --tabs=4 -RFXS
    fi
}

git_log_more() {
    #help List colored git log detail in pager
    git log --stat --color "$@" | less --tabs=4 -RFXS
}

git_remote_view() {
    #help List git remotes (alias:grv)
    git remote -v | grep -v \(push\) | sed -e "s/(fetch)//" -e "s/git@bbgithub.dev.bloomberg.com/bbgh/" | cat -n
}

git_do_recursive() {
    local line;
    while read -r line; do
        if [[ $line == .git ]]; then
            gitsmart_yellow "GDR in: $(pwd -P)"; echo
            "$@"
        else
            pushd $(dirname -- $line) &> /dev/null;
            gitsmart_yellow "GDR cd to: $(dirname -- $line)"; echo
            "$@";
            popd &> /dev/null;
        fi;
    done < <( command ls -d */.git)
}
alias gdr=git_do_recursive
#help Recursive $@ for all child git working copies


git_commit_sync() {
    local fwdArgs=()
    local edit_commit_msg=false
    local record_event=true
    local msg="Sync (auto)"
    local result
    while [[ -n "$1" ]]; do
        case "$1" in
            -e|--edit)  edit_commit_msg=true ;;
            -n|--no-history) record_event=false;;
            -h|--help) echo "Commit and push in one step.  -e to edit message, -n to suppress history recording" ; return ;;
            *)  fwdArgs+=( "$1" )
        esac
        shift
    done
    if [[ ${#fwdArgs} -gt 0 ]]; then
        msg="${fwdArgs[@]}"
    fi
    local kargs=( "-a" )
    $edit_commit_msg \
        && kargs+=( "--edit" )

    command git commit "${kargs[@]}" -m "${msg}"
    [[ $? -eq 0 ]] && result=true || {
        result=false
        record_event=false
    }
    $result \
        && { command git push || result=false ; }
    $record_event \
        && history -s "git_commit_sync \"$msg\" #$(git rev-parse --short=9 HEAD) from $(git-find-root)"
    $result
}

source ${LmHome}/bin/git-completion.bash &>/dev/null

git_branches_all() {
    # Show branches sorted by date (newest last).  If args are provided, we'll pass them as a pattern to grep
    local sort_by_date=${SortByDate:-false}

    local fmt="%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))"
    ${sort_by_date} && {
        # Warning: adding this sort option can hide branches which don't
        # have fetched remotes. This seems like a bug but perhaps a very deep
        # reading of the git manual would reveal a rationale?
        local sort_opt="-r --sort=committerdate"
    }
    if [[ $# == 0 ]]; then
        git branch -a "${sort_opt}" --format="$fmt"
    else
        git branch -a "${sort_opt}" --format="$fmt" | grep -E "$@"
    fi
    set +f
}


# Script-worthy git-status: check the branch, parseable output, etc.
# See-also: git-dirty
if [[ -n $PS1 ]]; then
    alias gs='git status '
    alias gc='git commit'
    alias gco='git checkout'
    alias ga='git add'
    alias gap='git add -p'
    alias gb='git branch -vv'
    alias gba='set -f; git_branches_all'
    alias gbr='set -f; SortByDate=true git_branches_all'
    alias gpa='git_commit_sync'
    alias gpu='git push -u'

    alias grs=git_remote_show

    alias gdf=git_diff_fancy
    alias gdt='git difftool'

    alias glm=git_log_more
    alias grv=git_remote_view
    alias glc='git-log-compact --decorate'
    alias ggr='git log --graph --oneline'
    alias grvh='git-reset-very-hard.sh'
    #help Reset working-copy and delete untracked files
    if type -t _complete_alias &>/dev/null; then
        complete -F _complete_alias gco
        complete -F _complete_alias gb
        complete -F _complete_alias gba
        complete -F _complete_alias gbr
        complete -F _complete_alias gpu
        complete -F _complete_alias ggr
        complete -F _complete_alias git-merge-safe
        complete -F _complete_alias gms

    fi
fi

gitgrep_f() {
    # Find files in git repo matching filename pattern $@
    git ls-files | grep -sE "$@"
    set +f
}

gitgrep_t() {
    # Find files in git repo matching text pattern $@
    while read -r file; do
        grep -snE "$@" "${file}" | sed "s%^%${file}#%"
    done < <(git ls-files .)
    set +f
}

alias gitgrep_t_all='gitgrep-all.sh --text'
#help Search for text, recursing through multiple working copies
alias gitgrep_f_all='gitgrep-all.sh --file'
#help Search for filename, recursing through multiple working copies

alias gitg='set -f; gitgrep_f'
#help Search filenames in git for pattern $@

alias gitgt='set -f; gitgrep_t'
#help Search content of git files for pattern $@

alias git-merge-safe='git merge --no-ff --no-commit'
#help Merge without commit or fast-forward
alias gms=git-merge-safe

alias git-wc-map='git-wc-map.mk map'
#help Map all git working copies under current directory

true
