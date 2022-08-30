# gitsmart.bashrc - shell init file for gitsmart sourced from ~/.bashrc

gitsmart-semaphore() {
    [[ 1 -eq  1 ]]
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
    local allremotes="$(command git remote show)"
    local remotes="$@"
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

git_attributes_init() {
    [[ -d .git ]] || return $(errExit No .git/ here)
    [[ -f .gitattributes ]] && return $(errExit Already has a .gitattributes here)
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
    #help Recursive $@ for all child git working copies
    local line;
    while read line; do
        if [[ $line == .git ]]; then
            yellow "GDR in: $(pwd -P)"; echo
            $@;
        else
            pushd $(dirname -- $line) &> /dev/null;
            yellow "GDR cd to: $(dirname -- $line)"; echo
            $@;
            popd &> /dev/null;
        fi;
    done < <( command ls -d */.git)
}
alias gdr=git_do_recursive

git_commit_sync() {
    # If arg is supplied, that's our commit message.  Otherwise the msg
    # is just 'Sync (auto)'
    local msg="Sync (auto)"
    if [[ $# -gt 0 ]]; then
        msg="$@"
    fi
    command git commit -am "$msg"
    command git push
}

if $isBash; then
    source ${LmHome}/bin/git-completion.bash &>/dev/null
fi

git_branches_all() {
    # Show branches sorted by date (newest last).  If args are provided, we'll pass them as a pattern to grep
    local filter=cat
    local fmt="%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))"
    if [[ $# == 0 ]]; then
        git branch -r --sort=committerdate --format="$fmt"
    else
        git branch -r --sort=committerdate --format="$fmt" | grep -E "$@"
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
    alias gpa='git_commit_sync'
    alias gpu='git push -u'

    alias grs=git_remote_show

    alias gdf=git_diff_fancy
    alias gdt='git difftool'

    alias glm=git_log_more
    alias grv=git_remote_view
    alias glc='git-log-compact --decorate'
    if type -t _complete_alias &>/dev/null; then
        complete -F _complete_alias gco
        complete -F _complete_alias gb
        complete -F _complete_alias gba
        complete -F _complete_alias gpu

    fi
fi

gitgrep() {
    # Find files in git repo matching pattern $1
    git ls-files | grep -E "$@"
    set +f
}
alias gitg='set -f; gitgrep'

