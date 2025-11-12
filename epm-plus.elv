use epm
use os
use path
use str

var -info~ = $epm:-info~
var -method-handler = $epm:-method-handler
var managed-dir = $epm:managed-dir

var -reference-separator = '#'

fn dest { |pkg|
  str:replace $-reference-separator $path:separator $pkg |
    path:join $managed-dir (all)
}

fn -patched-git-install { |pkg dom-cfg|
  var dest = (dest $pkg)

  var base-pkg git-reference = (
    str:split $-reference-separator $pkg''$-reference-separator |
      take 2
  )

  if (!=s $git-reference '') {
    -info 'Installing '$base-pkg'@'$git-reference
  } else {
    -info 'Installing '$base-pkg
  }

  os:mkdir-all $dest

  git clone ($-method-handler[git][src] $base-pkg $dom-cfg) $dest

  if (!=s $git-reference '') {
    tmp pwd = $dest
    git switch $git-reference
  }
}

fn patch-epm {
  var method-handlers = $epm:-method-handler

  var git-handler = $method-handlers[git]

  var updated-git-handler = (assoc $git-handler install $-patched-git-install~)

  var updated-method-handlers = (assoc $method-handlers git $updated-git-handler)

  set epm:-method-handler = $updated-method-handlers

  set epm:dest~ = $dest~
}