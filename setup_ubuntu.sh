#!/usr/bin/env bash

function killService() {
    service=$1
    sudo systemctl stop $service
    sudo systemctl kill --kill-who=all $service

    # Wait until the status of the service is either exited or killed.
    while ! (sudo systemctl status "$service" | grep -q "Active: inactive")
    do
        sleep 10
    done
}

function enableTimers() {
    sudo systemctl enable apt-daily.timer
    sudo systemctl enable apt-daily-upgrade.timer
}

function disableTimers() {
    sudo systemctl disable apt-daily.timer
    sudo systemctl disable apt-daily-upgrade.timer
}

function killServices() {
    killService unattended-upgrades.service
    killService apt-daily.service
    killService apt-daily-upgrade.service
}

echo == setup /etc/sudoer ==
sudo -i -u root bash << EOF
echo 1. set timeout to -1
sed -i "s/\tenv_reset/\ttimestamp_timeout=-1, env_reset/g" /etc/sudoers
echo 2. set no need password
sed -i "s/sudo\tALL=(ALL:ALL) /sudo\tALL=(ALL) NOPASSWD:/g" /etc/sudoers
EOF

echo == apt install necessary packages ==
disableTimers
killServices
sudo -i -u root bash << EOF
DEBIAN_FRONTEND=noninteractive apt install -y make gcc libncurses5-dev python3-dev liblua5.3-dev lua5.3 python cmake python-dev zlib1g-dev libclang-7-dev
ln -s /usr/include/lua5.3 /usr/include/lua
ln -s /usr/lib/x86_64-linux-gnu/liblua5.3.so /usr/local/lib/liblua.so
echo == setup vim ==
echo 0. remove system vim
apt remove -y --purge vim vim-runtime vim-tiny vim-common
EOF
enableTimers

mkdir -p ~/git/hub
cd ~/git/hub
echo 1. get vim
git clone https://github.com/vim/vim.git
echo 2. build vim
cd vim
./configure --with-features=huge --enable-multibyte --enable-python3interp=yes --enable-luainterp=yes --enable-cscope --with-python3-config-dir=/usr/lib/python3.6/config-3.6m-x86_64-linux-gnu/
sudo make install
echo 3. get ~/.vimrc
wget https://raw.githubusercontent.com/meiwenhua/configs/master/vimrc -O ~/.vimrc
echo 4. clone vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
echo 5. install plugin
vim +'silent! PluginInstall' +qall
echo 6. install YCM
cd ~/.vim/bundle/YouCompleteMe/
./install.py --clang-completer
echo 7. install color_coded
cd ~/.vim/bundle/color_coded
mkdir -p build && cd build
rm -f CMakeCache.txt
cmake ..
make && make install && make clean && make clean_clang
