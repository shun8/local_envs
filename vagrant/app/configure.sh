#!/bin/bash
# 必要なパッケージ
sudo yum -y install expect

# sqlcmdとbcp 参考:https://docs.microsoft.com/ja-jp/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15
if !(type "sqlcmd" > /dev/null 2>&1); then
  echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
  echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
fi

sudo curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/8/prod.repo
sudo yum -y remove unixODBC-utf16 unixODBC-utf16-devel #to avoid conflicts
sudo ACCEPT_EULA=Y yum -y install msodbcsql17
# optional: for bcp and sqlcmd
sudo ACCEPT_EULA=Y yum -y install mssql-tools
# optional: for unixODBC development headers
sudo yum -y install unixODBC-devel

# psql
sudo yum -y install postgresql

# zsh (個人的なやつだけどpoetryの設定が入りそうなので先に)
sudo yum -y install zsh

# python
sudo yum -y install python3
sudo curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3
source ~/.bash_profile
poetry config virtualenvs.in-project true

# 個人的に使うツールとか
# sudo yum -y install emacs
sudo yum -y install gcc
sudo yum -y install wget
# 他も必要なパッケージ都度入れた
sudo yum -y install make
sudo yum -y install gnutls-utils
sudo yum -y install gnutls-devel
sudo yum -y install ncurses-devel

# emacs 26.3入れた(yumで入るバージョンが古いのでソースから) http://mirrors.ibiblio.org/gnu/ftp/gnu/emacs/
# https://suwaru.tokyo/%E3%80%90centos%E3%80%91%E5%84%AA%E3%81%97%E3%81%84emacs%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E6%96%B9%E6%B3%95%E3%80%90ubuntu%E3%80%91/
# ./configure はオプション無し(gnutls-utilsインストールしてから)
if !(type "emacs" > /dev/null 2>&1); then
  cd /tmp
  wget http://mirrors.ibiblio.org/gnu/ftp/gnu/emacs/emacs-26.3.tar.gz
  tar zxvf emacs-26.3.tar.gz
  cd emacs-26.3
  sudo ./configure
  sudo make
  sudo make install
  cd /tmp
  rm -rf /tmp/emacs-26.3
  rm -f emacs-26.3.tar.gz
fi

sudo yum -y install tmux
sudo yum -y install git
sudo yum -y install jq
sudo yum -y install net-tools

# Catatsuyさんのemacs
if [ ! -d ~/.emacs.d ]; then
  git clone git://github.com/catatsuy/dot.emacs.d.git ~/.emacs.d
fi

# Catatsuyさんのzsh
if [ ! -d ~/.zsh ]; then
  git clone --recursive https://github.com/catatsuy/dot.zsh.git ~/.zsh
  echo "export ZDOTDIR=$HOME/.zsh" >> ~/.zshenv
fi

# Catatsuyさんのtmuxをベースに
cat <<\EOF > ~/.tmux.conf
# Prefix
set-option -g prefix C-z

#setw -g utf8 on
#set -g status-utf8 on

# status
set -g status-interval 10

# KeyBindings
# pane
unbind 1
bind 1 break-pane
bind 2 split-window -v
bind 3 split-window -h

bind C-r source-file ~/.tmux.conf
bind C-k kill-pane
bind k kill-window
unbind &
bind -r ^[ copy-mode
bind -r ^] paste-buffer

set -s escape-time 0

# shell
set-option -g default-shell /bin/zsh
set-option -g default-command /bin/zsh

#set-window-option -g mode-mouse on
set-option -g mouse on
bind -n WheelUpPane   select-pane -t= \; copy-mode -e \; send-keys -M
bind -n WheelDownPane select-pane -t= \;                 send-keys -M

#### COLOUR (Solarized dark)
#### cf: https://github.com/altercation/solarized/blob/master/tmux/tmuxcolors-dark.conf

# default statusbar colors
set-option -g status-bg black #base02
set-option -g status-fg yellow #yellow
set-option -g status-attr default

# default window title colors
set-window-option -g window-status-fg brightblue #base0
set-window-option -g window-status-bg default
#set-window-option -g window-status-attr dim

# active window title colors
set-window-option -g window-status-current-fg brightred #orange
set-window-option -g window-status-current-bg default
#set-window-option -g window-status-current-attr bright

# pane border
set-option -g pane-border-fg black #base02
set-option -g pane-active-border-fg brightgreen #base01

# message text
set-option -g message-bg black #base02
set-option -g message-fg brightred #orange

# pane number display
set-option -g display-panes-active-colour blue #blue
set-option -g display-panes-colour brightred #orange
EOF
