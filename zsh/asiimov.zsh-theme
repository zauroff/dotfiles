# asiimov.zsh-theme
#
# af-magic (Andy Fleming) recolored with the Asiimov palette. Colors are ANSI
# palette slots, not hex, so the prompt follows whatever the terminal loaded
# from ghostty/themes/asiimov-{light,dark} and switches with toggle-theme.sh:
#   %F{1} red          error code
#   %F{2} moss         git branch
#   %F{3} ember-text   prompt symbol, dirty marker
#   %F{8} ink-faint    separator, parens, user@host
#   %f    ink          directory

# dashed separator size
function afmagic_dashes {
  # check either virtualenv or condaenv variables
  local python_env_dir="${VIRTUAL_ENV:-$CONDA_DEFAULT_ENV}"
  local python_env="${python_env_dir##*/}"

  # if there is a python virtual environment and it is displayed in
  # the prompt, account for it when returning the number of dashes
  if [[ -n "$python_env" && "$PS1" = *\(${python_env}\)* ]]; then
    echo $(( COLUMNS - ${#python_env} - 3 ))
  elif [[ -n "$VIRTUAL_ENV_PROMPT" && "$PS1" = *${VIRTUAL_ENV_PROMPT}* ]]; then
    echo $(( COLUMNS - ${#VIRTUAL_ENV_PROMPT} - 3 ))
  else
    echo $COLUMNS
  fi
}

# primary prompt: dashed separator, directory and vcs info
PS1="%F{8}\${(l.\$(afmagic_dashes)..-.)}%f
%~\$(git_prompt_info)\$(hg_prompt_info) %F{3}%(!.#.»)%f "
PS2="%F{1}\ %f"

# right prompt: return code, virtualenv and context (user@host)
RPS1="%(?..%F{1}%? ↵%f)"
if (( $+functions[virtualenv_prompt_info] )); then
  RPS1+='$(virtualenv_prompt_info)'
fi
RPS1+=" %F{8}%n@%m%f"

# git settings
ZSH_THEME_GIT_PROMPT_PREFIX=" %F{8}(%F{2}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="%F{3}*%f"
ZSH_THEME_GIT_PROMPT_SUFFIX="%F{8})%f"

# hg settings
ZSH_THEME_HG_PROMPT_PREFIX=" %F{8}(%F{2}"
ZSH_THEME_HG_PROMPT_CLEAN=""
ZSH_THEME_HG_PROMPT_DIRTY="%F{3}*%f"
ZSH_THEME_HG_PROMPT_SUFFIX="%F{8})%f"

# virtualenv settings
ZSH_THEME_VIRTUALENV_PREFIX=" %F{8}["
ZSH_THEME_VIRTUALENV_SUFFIX="]%f"
