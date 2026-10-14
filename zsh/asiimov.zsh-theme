# asiimov.zsh-theme
#
# arrow (oh-my-zsh) recolored with the Asiimov palette. Colors are ANSI
# palette slots, not hex, so the prompt follows whatever the terminal loaded
# from ghostty/themes/asiimov-{light,dark} and switches with toggle-theme.sh.

# anonymous function keeps the color names out of the interactive shell
() {
  local red='%F{1}' moss='%F{2}' ember='%F{3}' faint='%F{8}' reset='%f'

  # directory, then the arrow: red as root, ember otherwise
  PROMPT="%c %(!.$red.$ember)➤$reset "
  RPROMPT=' $(git_prompt_info)'

  ZSH_THEME_GIT_PROMPT_PREFIX="${faint}git:$moss"
  ZSH_THEME_GIT_PROMPT_SUFFIX="$reset"
  ZSH_THEME_GIT_PROMPT_DIRTY="$ember*"
  ZSH_THEME_GIT_PROMPT_CLEAN=""
}
