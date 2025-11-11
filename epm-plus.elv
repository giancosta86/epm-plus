use epm
use str

var -original-git-install~ = $nil

fn -patched-git-install { |pkg dom-cfg|
  var actual-pkg git-reference = (str:split '#' $pkg'#' | take 2)

  -original-git-install $actual-pkg $dom-cfg

  if (!=s $git-reference '') {
    tmp pwd = (epm:dest $actual-pkg)
    git switch $git-reference
  }
}

fn patch-epm {
  if $-original-git-install~ {
    return
  }

  var method-handlers = $epm:-method-handler

  var git-handler = $method-handlers[git]

  set -original-git-install~ = $git-handler[install]

  var updated-git-handler = (assoc $git-handler install $-patched-git-install~)

  var updated-method-handlers = (assoc $method-handlers git $updated-git-handler)

  set epm:-method-handler = $updated-method-handlers
}