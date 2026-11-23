# ;-*- mode: sh;-*-
# distributed from chezmoi
# Source global definitions

logger -p user.info -t bashrc sourced

if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

pathmunge () {
    # If the path is a compat symlink, do nothing.
    [ -h "$1" ] && return

    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
}

alias mydstat='dstat -cmsgdn'
# devices='sda'
# for dev in sd{b..z}; do
#     if test -b "/dev/${dev}"; then
#         devices="${devices},${dev}"
#     fi
# done
# alias dnstat="dstat -dn -D ${devices} --disk-util -N br0"
#alias trr='transmission-remote'
#alias playlist="mpc -f '%position%:\t [%artist%][%albumartist%]\t%album%\t%track% - %title%\t(%file%)' playlist"
alias zlsnap="zfs list -t snapshot -o name,used,written,refer,logicalreferenced,creation"

if which eza >/dev/null 2>&1 ; then
    alias ls='eza --group --icons=always'
    alias lsold='ls -sold -lr'
fi

if which pulp >/dev/null 2>&1 ; then
    eval "$(_PULP_COMPLETE=source_bash pulp)"
    export PULP_CLI_PROFILE=mirrors
    pipx ensurepath >/dev/null 2>&1
fi


# User specific environment and startup programs
#PATH="${PATH:+${PATH}:}~/opt/bin"   # appending
#PATH="~/opt/bin${PATH:+:${PATH}}"   # prepending

declare -a add_paths=("${HOME}/bin" "${HOME}/.local/bin" "${HOME}/.cargo/bin" "${HOME}/go/bin" "/sbin" "/usr/sbin" "/usr/local/sbin" "${HOME}/perl5/bin")
for p in ${add_paths[@]}; do
    if [[ -d "${p}" ]]; then
        pathmunge "${p}" after
    fi
    # if ! [[ "${PATH}" =~ "${p}" ]]; then
    #     #echo "adding $p to existing path ${PATH}" > /dev/stderr
    #     if [[ -d "${p}" ]]; then
    #         PATH="${PATH:+${PATH}:}${p}"
    #     fi
    # fi
done

# if rbenv is installed, activate it
if which rbenv >/dev/null 2>&1; then
    if [[ $(type -t rbenv) != "function" ]]; then
        old_path="${PATH}"
        eval "$(rbenv init - --no-rehash bash)"
        PATH=$old_path
        # this may not always be correct:
        pathmunge "${HOME}/.rbenv/shims"
    fi
fi

export PATH
# Uncomment the following line if you don't like systemctl's auto-paging feature:
export SYSTEMD_PAGER=


if [ -f ~/.cargo/env ]; then
    . "$HOME/.cargo/env"
fi
if [[ -x /opt/homebrew/bin/brew ]]; then
   eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# we could check these as well, but let's just not
PERL5LIB="${HOME}/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="${HOME}/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"${HOME}/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=${HOME}/perl5"; export PERL_MM_OPT;

# if emacs is installed in /usr/bin/emacs, use it?
if which emacs >/dev/null 2>/dev/null; then
    export ALTERNATE_EDITOR="vim" EDITOR="emacsclient" VISUAL="emacsclient"
else
    # I don't think ALTERNATE_EDITOR is used by any program except emacsclient, but there it is anyway
    export ALTERNATE_EDITOR="vi" EDITOR="vim" VISUAL="vim"
fi

export NETHACKOPTIONS='!autopickup,color,name:Victron,fruit:wacky fruit,catname:Al,dogname:Elektra,female,horsename:Trotter,showexp,time'

if [[ "${TERM}" == "xterm-kitty" && -x ~/bin/oh-my-posh ]]; then
    eval "$( ~/bin/oh-my-posh init bash --config ~/.poshthemes/tokyo.omp.json )"
elif [[ $(uname) == "Darwin" && -x '/opt/homebrew/bin/oh-my-posh' ]]; then
    eval "$( /opt/homebrew/bin/oh-my-posh init bash --config ~/.poshthemes/tokyo.omp.json )"
else
    for git_prompt_sh in ~/bin/git-prompt.sh /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh /usr/{,local}/share/git-core/contrib/completion/git-prompt.sh; do
        if [[ -f $git_prompt_sh ]]; then
            source $git_prompt_sh
            case $TERM in
                xterm*|vte*)
                    PROMPT_COMMAND='printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}";__git_ps1 "[\u@\h:\w]" "\\\$ "'
                    ;;
                dumb*)
                    # inside emacs you get dumb
                    PROMPT_COMMAND='__git_ps1 "[\u@\h:\w]" "\\\$ "'
                    ;;
                screen*)
                    PROMPT_COMMAND='printf "\033k%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}";__git_ps1 "[\u@\h:\w]" "\\\$ "'
                    ;;
            esac
            break;
        fi
    done
fi

function eac {
local wineprefix="$HOME/.eac-prefix"
local eacdir="${wineprefix}/drive_c/Program Files/Exact Audio Copy"
pushd "${eacdir}/Microsoft.VC80.CRT"
WINEPREFIX=$wineprefix WINEDEBUG=-all wine "${eacdir}/EAC.exe"
popd
}
export BAO_ADDR="https://yendor.crashland:8300/"
export VAULT_ADDR="${BAO_ADDR}"
# try to limit noise from this library:
export TSS2_LOG=fapi+NONE
export HISTCONTROL=ignoreboth
export HISTSIZE=1000

# just use keychain, although this was useful:
# ssh-reagent () {
#     for agent in /tmp/ssh-*/agent.*; do
#         export SSH_AUTH_SOCK=$agent
#         if ssh-add -l >/dev/null 2>&1 ; then
#             echo Found working SSH Agent:
#             ssh-add -l
#             return
#         fi
#     done
#     echo Cannot find ssh agent - maybe you should reconnect and forward it?
# }

complete -C /home/spin/bin/mc mc

unset -f pathmunge
