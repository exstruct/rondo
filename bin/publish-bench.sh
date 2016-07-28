#!/bin/bash

if [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_BRANCH" == "master" ] && [ "$MIX_ENV" == "bench" ]; then

  echo -e "Publishing benchmarks...\n"

  cp -R bench/snapshots $HOME/snapshots

  cd $HOME
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "travis-ci"
  git clone --quiet --branch=gh-pages https://${GITHUB_TOKEN}@github.com/exstruct/rondo gh-pages > /dev/null

  cd gh-pages
  mkdir -p ./bench/snapshots/$TRAVIS_ELIXIR_VERSION
  cp $HOME/snapshots/* ./bench/snapshots/$TRAVIS_ELIXIR_VERSION
  git add -f .
  git commit -m "travis benchmarks build $TRAVIS_BUILD_NUMBER"
  git push -q origin gh-pages > /dev/null

  echo -e "Published!\n"
fi
