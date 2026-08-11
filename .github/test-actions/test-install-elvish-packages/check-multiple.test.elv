use epm

>> 'Installing multiple packages' {
  all [
    primrose
    astral-bridge
  ] |
    each { |package-name|
      epm:is-installed github.com/giancosta86/$package-name |
        should-be $true
    }
}