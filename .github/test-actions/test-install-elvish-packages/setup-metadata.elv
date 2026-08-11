use epm

echo 🎭 Setting up a metadata-driven install...

cd (get-env temp-project-dir)

all [
  github.com/giancosta86/ethereal
  github.com/giancosta86/velvet
  github.com/giancosta86/primrose
  github.com/giancosta86/astral-bridge
] |
  each $epm:uninstall~

put [
  &description='Test project'
  &dependencies=[
    github.com/giancosta86/primrose@v1
  ]
  &devDependencies=[
    github.com/giancosta86/velvet@v2
    github.com/giancosta86/astral-bridge
  ]
] |
  to-json > metadata.json