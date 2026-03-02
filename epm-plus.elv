use epm
use os
use path
use re
use str

var -original-install~ = $epm:install~
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

fn -get-all-dependencies { |metadata|
  if (has-key $metadata dependencies) {
    all $metadata[dependencies]
  }

  if (has-key $metadata devDependencies) {
    all $metadata[devDependencies]
  }
}

fn -patched-install { |&silent-if-installed=$false @pkgs|
  var actual-packages = (
    if (not-eq $pkgs []) {
      put $pkgs
    } else {
      if (os:is-regular metadata.json) {
        from-json < metadata.json |
          put [(-get-all-dependencies (all))]
      } else {
        put []
      }
    }
  )

  -original-install &silent-if-installed=$silent-if-installed $@actual-packages
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
  set epm:install~ = $-patched-install~
  set epm:installed~ = $-patched-installed~

  -patch-git-handler

  set -patched = $true
}

#
# When run inside a project directory also hosting a cloned Git repository, creates a symlink to it within `$epm:managed-dir`, thus simulating package installation while using up-to-date scripts.
#
# More in detail, the **package path** is provided by the *Git origin url*, whereas the **version** is provided by the current *Git reference* (usually a branch).
#
# By default, the symlink is named like the **major** version (e.g.: **v2**) - but the full version (e.g.: **v2.7.1**) can be used instead, via the `full-version` flag.
#
fn link { |&full-version=$false|
  var full-origin-url = (
    try {
      git remote get-url origin 2>$os:dev-null
    } catch {
      fail 'Not in a Git repository!'
    }
  )

  var origin-url = (
    put $full-origin-url |
      str:trim-prefix (all) 'git@' |
      str:trim-prefix (all) 'https://' |
      str:trim-suffix (all) '.git'
  )

  var package-subdir = (str:replace ':' '/' $origin-url)

  var package-dir = (path:join $epm:managed-dir $package-subdir)

  var reference = (
    try {
      git rev-parse --abbrev-ref HEAD 2>$os:dev-null
    } catch {
      fail 'Cannot retrieve the current Git reference!'
    }
  )

  var link-name = (
    if $full-version {
      put $reference
    } else {
      put [(str:split . $reference)][0]
    }
  )

  var link-path = (path:join $package-dir $link-name)

  os:mkdir-all $package-dir

  os:symlink $pwd $link-path
}