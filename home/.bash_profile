# .bash_profile

logger -p user.info -t bash_profile sourced

# Get the aliases and functions
if [[ ( -f ~/.bashrc || -L ~/.bashrc ) && -z "$DOT_BASHRC_DONE" ]]; then
	. ~/.bashrc
fi

