use epm
use os
use github.com/giancosta86/gauntlet/v1/env

echo 🎭 Setting up the environment variables for the tests...

var velvet-dir = (epm:metadata 'github.com/giancosta86/velvet')[dst]

if (os:is-dir $velvet-dir) {
  fail 'The Velvet directory must not already exist!'
}

env:map [
  &velvet-dir=$velvet-dir

  &expected-tag=v3.6.0

  &temp-project-directory=(os:temp-dir)
]