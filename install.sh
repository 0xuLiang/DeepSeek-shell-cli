#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi
# Check dependencies
if type curl &>/dev/null; then
  echo "" &>/dev/null
else
  echo "You need to install 'curl' to use the deepseek script."
  exit
fi
if type jq &>/dev/null; then
  echo "" &>/dev/null
else
  echo "You need to install 'jq' to use the deepseek script."
  exit
fi

# Installing imgcat if using iTerm
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
  if [[ ! $(which imgcat) ]]; then
    curl -sS https://iterm2.com/utilities/imgcat -o /usr/local/bin/imgcat
    chmod +x /usr/local/bin/imgcat
    echo "Installed imgcat"
  fi
fi

# Installing magick if using kitty
if [[ "$TERM" == "xterm-kitty" ]]; then
  if [[ ! $(which magick) ]]; then
    curl -sS https://imagemagick.org/archive/binaries/magick -o /usr/local/bin/magick
    chmod +x /usr/local/bin/magick
    echo "Installed magick"
  fi
fi

# Installing deepseek script
curl -sS https://raw.githubusercontent.com/0xuLiang/DeepSeek-shell-cli/master/deepseek.sh -o /usr/local/bin/deepseek

# Replace open image command with xdg-open for linux systems
if [[ "$OSTYPE" == "linux"* ]] || [[ "$OSTYPE" == "freebsd"* ]]; then
  sed -i 's/open "\${image_url}"/xdg-open "\${image_url}"/g' '/usr/local/bin/deepseek'
fi
chmod +x /usr/local/bin/deepseek
echo "Installed deepseek script to /usr/local/bin/deepseek"

echo "The script will add the DEEPSEEK_API_KEY environment variable to your shell profile and add /usr/local/bin to your PATH"
echo "Would you like to continue? (Yes/No)"
# Ensure reading from the terminal even if script is piped
if [ -t 0 ]; then
  read -r answer
else
  read -r answer < /dev/tty
fi

if [ "$answer" == "Yes" ] || [ "$answer" == "yes" ] || [ "$answer" == "y" ] || [ "$answer" == "Y" ] || [ "$answer" == "ok" ]; then

  echo "Please enter your DeepSeek API key: "
  if [ -t 0 ]; then
    read -r key
  else
    read -r key < /dev/tty
  fi

  # Adding DeepSeek API key to shell profile
  # zsh profile
  if [ -f ~/.zprofile ]; then
    echo "export DEEPSEEK_API_KEY=$key" >>~/.zprofile
    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
      echo 'export PATH=$PATH:/usr/local/bin' >>~/.zprofile
    fi
    echo "DeepSeek API key and deepseek path added to ~/.zprofile"
  # zshrc profile for debian
  elif [ -f ~/.zshrc ]; then
    echo "export DEEPSEEK_API_KEY=$key" >>~/.zshrc
    if [[ ":$PATH:" == *":/usr/local/bin:"* ]]; then
      echo 'export PATH=$PATH:/usr/local/bin' >>~/.zshrc
    fi
    echo "DeepSeek API key and deepseek path added to ~/.zshrc"
  # bash profile mac
  elif [ -f ~/.bash_profile ]; then
    echo "export DEEPSEEK_API_KEY=$key" >>~/.bash_profile
    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
      echo 'export PATH=$PATH:/usr/local/bin' >>~/.bash_profile
    fi
    echo "DeepSeek API key and deepseek path added to ~/.bash_profile"
  # profile ubuntu
  elif [ -f ~/.profile ]; then
    echo "export DEEPSEEK_API_KEY=$key" >>~/.profile
    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
      echo 'export PATH=$PATH:/usr/local/bin' >>~/.profile
    fi
    echo "DeepSeek API key and deepseek path added to ~/.profile"
  else
    export DEEPSEEK_API_KEY=$key
    echo "You need to add this to your shell profile: export DEEPSEEK_API_KEY=$key"
  fi
  echo "Installation complete"

else
  echo "Please take a look at the instructions to install manually: https://github.com/0xuLiang/DeepSeek-shell-cli/tree/master#manual-installation "
  exit
fi
