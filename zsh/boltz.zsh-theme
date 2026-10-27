# boltz.zsh-theme
#
# arrow (oh-my-zsh) recolored with the Boltz palette. Colors are ANSI
# palette slots, not hex, so the prompt follows whatever the terminal loaded
# from ghostty/themes/boltz-{light,dark} and switches with toggle-theme.sh.

# anonymous function keeps the color names out of the interactive shell
() {
  local red='%F{1}' green='%F{2}' orange='%F{3}' grey='%F{8}' reset='%f'

  # directory, then the arrow: red as root, orange otherwise
  PROMPT="%c %(!.$red.$orange)➤$reset "
  RPROMPT=' $(git_prompt_info)'

  ZSH_THEME_GIT_PROMPT_PREFIX="${grey}git:$green"
  ZSH_THEME_GIT_PROMPT_SUFFIX="$reset"
  ZSH_THEME_GIT_PROMPT_DIRTY="$orange*"
  ZSH_THEME_GIT_PROMPT_CLEAN=""
}
