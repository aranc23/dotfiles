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

alias zlsnap="zfs list -t snapshot -o name,used,written,refer,logicalreferenced,creation"

case "$(hostname -s)" in
    a-lnx005)
        alias sshadd='ssh-add -s /usr/lib64/pkcs11/libtpm2_pkcs11.so ~/.ssh/id_ecdsa-cert.pub; ssh-add ~/.ssh/id_ed25519_sk'
        export LIBVIRT_DEFAULT_URI=qemu:///system
        ;;
    beast)
        alias zmsnap="zfs list -t snapshot -o name,used,written,refer,creation -r data/music"
        alias sshadd='ssh-add -s /usr/lib/x86_64-linux-gnu/libtpm2_pkcs11.so.1 ~/.ssh/id_rsa-cert.pub ~/.ssh/id_ecdsa-cert.pub'
        alias rtcwake_afterwork='sudo rtcwake --date 17:00 -m off'
        alias rtcwake_morning='sudo rtcwake --date 06:30 -m off'
        export SNAPRAID_CONFIG_FILE="${HOME}/etc/snapraid.conf"
        ;;
    lazarus)
        alias sshadd='ssh-add -s /usr/lib64/pkcs11/libtpm2_pkcs11.so ~/.ssh/id_ecdsa-cert.pub ; ssh-add ~/.ssh/id_ed25519_sk'
        export SSH_ASKPASS=/usr/libexec/openssh/gnome-ssh-askpass
        ;;
    benway)
        alias sshadd='ssh-add -s /usr/lib64/pkcs11/libtpm2_pkcs11.so ~/.ssh/id_rsa-cert.pub ~/.ssh/id_ecdsa-cert.pub ; ssh-add ~/.ssh/id_ed25519_sk'
        export SSH_ASKPASS=/usr/libexec/openssh/gnome-ssh-askpass
        ;;
    wintermute)
        alias sshadd='ssh-add -s /usr/lib/x86_64-linux-gnu/pkcs11/libtpm2_pkcs11.so.1 ~/.ssh/id_ecdsa-cert.pub'
        ;;
esac

if which eza >/dev/null 2>&1 ; then
    alias ls='eza --group --icons=always'
    alias lsold='ls -sold -lr'
fi

if which pulp >/dev/null 2>&1 ; then
    eval "$(_PULP_COMPLETE=source_bash pulp)"
    export PULP_CLI_PROFILE=mirrors
    pipx ensurepath >/dev/null 2>&1
fi

if [[ "$(uname -s)" == "Linux" ]]; then
    export LANG=en_US.UTF-8
fi

# User specific environment and startup programs
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

# if mise/rbenv is installed, activate it
if test -x "${HOME}/.local/bin/mise"; then
    if [[ $(type -t rbenv) == "function" ]]; then
        unset -f rbenv
    fi
    if [[ $(type -t rbenv) != "function" ]]; then
        old_path="${PATH}"
        eval "$(${HOME}/.local/bin/mise activate bash)"
        PATH=$old_path
        # this may not always be correct:
        pathmunge "${HOME}/.local/share/mise/shims"
        # remove rbenv shims, if previously set:
        PATH=$(echo $PATH | sed -e "s|:${HOME}/.rbenv/shims||")
    fi
elif which rbenv >/dev/null 2>&1; then
    if [[ $(type -t rbenv) != "function" ]]; then
        old_path="${PATH}"
        eval "$(rbenv init - --no-rehash bash)"
        PATH=$old_path
        # this may not always be correct:
        pathmunge "${HOME}/.rbenv/shims"
    fi
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
    if which keychain >/dev/null 2>&1; then
        if [[ -z "${SSH_AUTH_SOCK:-}" || ! -S "$SSH_AUTH_SOCK" ]]; then
            # If no agent or no keys, run keychain to start a local agent
            eval $(keychain --eval --systemd --noinherit --quiet)
        fi
    fi
fi

export PATH
# Uncomment the following line if you don't like systemctl's auto-paging feature:
export SYSTEMD_PAGER=

# what needs this?
if [ -f ~/.cargo/env ]; then
    . "$HOME/.cargo/env"
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
       eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
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

export NETHACKOPTIONS='!autopickup,color,name:Manshoon,fruit:wacky fruit,catname:Al,dogname:Elektra,female,horsename:Trotter,showexp,time'

if [[ "${TERM}" != "dumb" && "${TERM}" != "linux" ]]; then
    if which oh-my-posh >/dev/null 2>/dev/null; then
        eval "$( oh-my-posh init bash --config ~/.poshthemes/tokyo.omp.json )"
    fi
    unset posh
fi

# try to limit noise from this library:
export TSS2_LOG=fapi+NONE
export HISTCONTROL=ignoreboth
export HISTSIZE=1000

which fzf 2>/dev/null >/dev/null && eval "$(fzf --bash)"
which zoxide 2>/dev/null >/dev/null && eval "$(zoxide init bash)"
unset -f pathmunge
