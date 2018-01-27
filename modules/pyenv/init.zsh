#
# Enables local Python package installation with
#   pyenv and pyenv-virtualenvwrapper
#
# Inspired by Python module
#

# Load pyenv
export PYENV_ROOT=$(pyenv root)
eval "$(pyenv init -)"

# Load pyenv-virtualenvwrapper
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
export WORKON_HOME=$HOME/.virtualenvs
export VIRTUAL_ENV_DISABLE_PROMPT=1
pyenv virtualenvwrapper_lazy

function _python-workon-cwd {
  # Check if this is a Git repo
  local GIT_REPO_ROOT=""
  local GIT_TOPLEVEL="$(git rev-parse --show-toplevel 2> /dev/null)"
  if [[ $? == 0 ]]; then
    GIT_REPO_ROOT="$GIT_TOPLEVEL"
  fi
  # Get absolute path, resolving symlinks
  local PROJECT_ROOT="${PWD:A}"
  while [[ "$PROJECT_ROOT" != "/" && ! -e "$PROJECT_ROOT/.venv" \
            && ! -d "$PROJECT_ROOT/.git"  && "$PROJECT_ROOT" != "$GIT_REPO_ROOT" ]]; do
    PROJECT_ROOT="${PROJECT_ROOT:h}"
  done
  if [[ "$PROJECT_ROOT" == "/" ]]; then
    PROJECT_ROOT="."
  fi
  # Check for virtualenv name override
  local ENV_NAME=""
  if [[ -f "$PROJECT_ROOT/.venv" ]]; then
    ENV_NAME="$(cat "$PROJECT_ROOT/.venv")"
  elif [[ -f "$PROJECT_ROOT/.venv/bin/activate" ]];then
    ENV_NAME="$PROJECT_ROOT/.venv"
  elif [[ "$PROJECT_ROOT" != "." ]]; then
    ENV_NAME="${PROJECT_ROOT:t}"
  fi
  if [[ -n $CD_VIRTUAL_ENV && "$ENV_NAME" != "$CD_VIRTUAL_ENV" ]]; then
    # We've just left the repo, deactivate the environment
    # Note: this only happens if the virtualenv was activated automatically
    deactivate && unset CD_VIRTUAL_ENV
  fi
  if [[ "$ENV_NAME" != "" ]]; then
    # Activate the environment only if it is not already active
    if [[ "$VIRTUAL_ENV" != "$WORKON_HOME/$ENV_NAME" ]]; then
      if [[ -e "$WORKON_HOME/$ENV_NAME/bin/activate" ]]; then
        workon "$ENV_NAME" && export CD_VIRTUAL_ENV="$ENV_NAME"
      elif [[ -e "$ENV_NAME/bin/activate" ]]; then
        source $ENV_NAME/bin/activate && export CD_VIRTUAL_ENV="$ENV_NAME"
      fi
    fi
  fi
}

# Load auto workon cwd hook
if zstyle -t ':prezto:module:pyenv:virtualenv' auto-switch 'yes'; then
  # Auto workon when changing directory
  add-zsh-hook chpwd _python-workon-cwd
fi
