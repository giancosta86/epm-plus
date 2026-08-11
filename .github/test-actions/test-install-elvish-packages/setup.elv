use epm
use os
use github.com/giancosta86/gauntlet/v1/env

echo 🎭 Setting up the environment variables for the tests...

env:map [
  &velvet-dir=(epm:metadata 'github.com/giancosta86/velvet')[dst]

  &expected-tag=v3.6.0

  &temp-project-directory=(os:temp-dir)
]