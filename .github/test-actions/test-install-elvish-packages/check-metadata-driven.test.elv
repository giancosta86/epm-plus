use epm
use github.com/giancosta86/epm-plus/epm-plus

epm-plus:patch-epm

>> 'After performing a metadata-driven install' {
  all [
    github.com/giancosta86/primrose@v1
    github.com/giancosta86/velvet@v2
    github.com/giancosta86/astral-bridge
  ] |
    each { |package|
      epm:is-installed $package |
        should-be $true
  }
}