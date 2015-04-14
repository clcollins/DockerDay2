#!/bin/bash

if [[ ! $(which mdp) ]] ; then
  echo "This is an 'mdp' - Markdown Presentation"
  echo "Go get mdp from: https://github.com/visit1985/mdp"
  exit 1
fi

exec mdp ./README.md
