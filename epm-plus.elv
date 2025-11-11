use epm
use os
use path
use str

var dest~ = $epm:dest~
var -info~ = $epm:-info~
var -method-handler = $epm:-method-handler

fn -patched-git-install { |pkg dom-cfg|
  var actual-pkg git-reference = (str:split '#' $pkg'#' | take 2)

  var base-dest = (dest $actual-pkg)

  var dest = (
    if (!=s $git-reference '') {
      path:join $base-dest $git-reference
    } else {
      put $base-dest
    }
  )

  -info "Installing "$pkg

  os:mkdir-all $dest

  git clone ($-method-handler[git][src] $actual-pkg $dom-cfg) $dest

  if (!=s $git-reference '') {
    -info 'Switching to reference '$git-reference

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
}