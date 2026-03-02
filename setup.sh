#!/bin/bash
rm -rf $HOME/.zshrc
ln -s $HOME/Documents/backup/zsh/zshrc $HOME/.zshrc
#rm -rf $HOME/.zsh_history
#ln -s $HOME/Documents/backup/zsh/zsh_history $HOME/.zsh_history
#rm -rf $HOME/.zsh_plugins.txt
#ln -s $HOME/Documents/backup/zsh/zsh_plugins.txt $HOME/.zsh_plugins.txt
echo "Done"
