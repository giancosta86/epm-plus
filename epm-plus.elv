use epm
use os
use re
use str

var -domain-config~ = $epm:-domain-config~
var -info~ = $epm:-info~
var -method-handler = $epm:-method-handler
var managed-dir = $epm:managed-dir

var git~ = (external git)

var -patched = $false
var -managed-dir-length = (count $managed-dir)

var -version-separator = @

fn -patched-dest { |pkg|
  str:replace $-version-separator / $pkg |
    put $epm:managed-dir/(all)
}

fn -patched-installed {
  put $managed-dir/*[type:dir][nomatch-ok] | each { |domain-dir|
    var dom = $domain-dir[(+ $-managed-dir-length 1)..]

    var cfg = (-domain-config $dom)

    if $cfg {
      var domain-package-pattern = (
        repeat (+ $cfg[levels] 1) '[^/]+' |
          str:join / |
          put '^'(re:quote $managed-dir/)'('(all)')/$'
      )

      put $managed-dir/$dom/**[nomatch-ok]/ |
        each { |subdir| re:find $domain-package-pattern $subdir } |
        put (all)[groups][1][text] |
        each { |pkg|
          var regular-file-count = (
            put $epm:managed-dir/$pkg/*[type:regular][nomatch-ok] |
              count
          )

          if (> $regular-file-count 0) {
            put $pkg
          } else {
            put $epm:managed-dir/$pkg/*[type:dir][nomatch-ok] | each { |entry|
              str:last-index $entry / |
                assoc $entry (all) $-version-separator |
                put (all)[(+ $-managed-dir-length 1)..]
            }
          }
        }
    }
  }
}

fn -split-package-name-and-version { |pkg|
  var last-version-separator-index = (str:last-index $pkg $-version-separator)

  if (>= $last-version-separator-index 0) {
    put $pkg[..$last-version-separator-index]

    put $pkg[(+ $last-version-separator-index 1)..]
  } else {
    put $pkg $nil
  }
}

fn -get-git-source { |package-name dom-cfg|
  put $dom-cfg[protocol]"://"$package-name
}

fn -patched-git-src { |pkg dom-cfg|
  var package-name _ = (-split-package-name-and-version $pkg)

  -get-git-source $package-name $dom-cfg
}

fn -patched-git-install { |pkg dom-cfg|
  var dest = (-patched-dest $pkg)

  -info 'Installing '$pkg

  os:mkdir-all $dest

  var package-name git-reference = (-split-package-name-and-version $pkg)

  var git-source = (-get-git-source $package-name $dom-cfg)

  git clone $git-source $dest

  if $git-reference {
    tmp pwd = $dest
    git checkout $git-reference
  }
}

fn -patch-git-handler {
  var method-handlers = $epm:-method-handler

  var git-handler = $method-handlers[git]

  var updated-git-handler = (
    put $git-handler |
      assoc (all) src $-patched-git-src~ |
      assoc (all) install $-patched-git-install~
  )

  var updated-method-handlers = (assoc $method-handlers git $updated-git-handler)

  set epm:-method-handler = $updated-method-handlers
}

fn patch-epm {
  if $-patched {
    return
  }

  set epm:dest~ = $-patched-dest~
  set epm:installed~ = $-patched-installed~

  -patch-git-handler

  set -patched = $true
}