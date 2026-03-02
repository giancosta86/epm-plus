use epm
use os
use path
use str
use ./epm-plus
use github.com/giancosta86/ethereal/v1/fake-git

var test-package = 'github.com/giancosta86/epm-plus-test'

var test-source-url = 'https://'$test-package

var test-package-root = (path:join $epm:managed-dir (str:split / $test-package))

var test-package-components = [(str:split / $test-package)]

var git~ = (fake-git:create-command [
  &$test-source-url=[
    &main=[
      &'main.elv'='#This is a placeholder for the actual source code'
    ]

    &'v1.0.0'=[
      &'alpha.elv'='
        fn f {
          put 90
        }
      '
    ]

    &'v2.0.0'=[
      &'metadata.json'='
      {
        "description": "Test package with dependencies",

        "maintainers": ["Gianluca Costa <gianluca@gianlucacosta.info>"],

        "homepage": "'$test-source-url'",

        "dependencies": ["'$test-package'@v1.0.0"]
      }
      '

      &'alpha.elv'='
        use ../v1.0.0/alpha v1

        fn f {
          / (v1:f) 18
        }
      '

      &'beta.elv'='
        use '$test-package'/v1.0.0/alpha v1
        use ./alpha

        fn g {
          + (v1:f) (alpha:f)
        }
      '
    ]

    &'v3.0.0'=[
      &'special.elv'='Only used as an additional standalone version'
    ]
  ]
])

set epm-plus:git~ = $git~

epm-plus:patch-epm

var within-test-install~ = (
  var active-blocks = 0

  fn remove-package-root-if-no-active-blocks {
    if (== $active-blocks 0) {
      os:remove-all $test-package-root
    }
  }

  put { |&reference=$nil block|
    remove-package-root-if-no-active-blocks

    set active-blocks = (+ $active-blocks 1)

    defer {
      set active-blocks = (- $active-blocks 1)

      remove-package-root-if-no-active-blocks
    }

    var reference-suffix = (
      if $reference {
        put '@'$reference
      } else {
        put ''
      }
    )

    epm:install $test-package''$reference-suffix

    {
      tmp pwd = (path:join $test-package-root (coalesce $reference ''))
      $block
    }
  }
)

fn get-test-package-entries {
  epm:list |
    keep-if { |entry| str:has-prefix $entry $test-package } |
    order
}

>> 'Splitting package name and version' {
  >> 'without version' {
    epm-plus:-split-package-name-and-version $test-package |
      should-emit [
        $test-package
        $nil
      ]
  }

  >> 'with version' {
    epm-plus:-split-package-name-and-version $test-package@v1.0.0 |
      should-emit [
        $test-package
        'v1.0.0'
      ]
  }
}

>> 'Computing the destination directory of a package' {
  >> 'without version' {
    epm:dest $test-package |
      should-be $test-package-root
  }

  >> 'with version' {
    epm:dest $test-package@v2.0.0 |
      should-be (path:join $test-package-root v2.0.0)
  }
}

>> 'Installing from a Git repository' {
  >> 'when requesting no specific reference' {
    >> 'should perform a basic clone from main' {
      within-test-install {
        put main.elv |
          should-be-regular
      }
    }
  }

  >> 'when requesting a standalone reference' {
    within-test-install &reference=v1.0.0 {
      >> 'should Git-checkout that reference' {
        put main.elv |
          should-not-be-regular

        put alpha.elv |
          should-be-regular
      }

      >> 'should not include the reference in the metadata src field' {
        epm:metadata $test-package@v1.0.0 |
          put (all)[src] |
          should-be $test-source-url
      }
    }
  }

  >> 'when installing a reference depending on another' {
    within-test-install &reference=v2.0.0 {
      >> 'should install both versions, each in its own directory' {
        all [
          alpha.elv
          beta.elv
        ] |
          should-be-regular

        var test1-dest = (path:join $test-package-root v1.0.0)

        put $test1-dest |
          should-be-dir

        path:join $test1-dest alpha.elv |
          should-be-regular
      }

      >> 'both package versions should be available and callable' {
        var v1: = (use-mod $test-package/v1.0.0/alpha)

        var alpha: = (use-mod $test-package/v2.0.0/alpha)
        var beta: = (use-mod $test-package/v2.0.0/beta)

        v1:f |
          should-be 90

        alpha:f |
          should-be 5

        beta:g |
          should-be 95
      }
    }
  }
}

>> 'Getting all the dependencies from metadata' {
  >> 'should list both dependencies and dev dependencies' {
    var metadata = [
      &dependencies=[
        alpha
        beta
        gamma
      ]

      &devDependencies=[
        delta
        epsilon
      ]
    ]

    epm-plus:-get-all-dependencies $metadata |
      should-emit [
        alpha
        beta
        gamma
        delta
        epsilon
      ]
  }
}

>> 'Listing Git packages' {
  >> 'when only the package without reference is installed' {
    >> 'should list just the package name' {
      within-test-install {
        get-test-package-entries |
          should-emit [
            $test-package
          ]
      }
    }
  }

  >> 'when only a single reference is installed' {
    >> 'should list the reference' {
      within-test-install &reference=v1.0.0 {
        get-test-package-entries |
          should-emit [
            $test-package@v1.0.0
          ]
      }
    }
  }

  >> 'when a reference installs another as a dependency' {
    >> 'should list both references' {
      within-test-install &reference=v2.0.0 {
        get-test-package-entries |
          should-emit [
            $test-package@v1.0.0
            $test-package@v2.0.0
          ]
      }
    }
  }

  >> 'when the base version and a reference are installed' {
    >> 'should list just the package name' {
      within-test-install {
        within-test-install &reference=v1.0.0 {
          get-test-package-entries |
            should-emit [
              $test-package
            ]
        }
      }
    }
  }
}

>> 'Uninstalling a Git package' {
  >> 'when the Git reference is specified' {
    >> 'the references it depends on should remain' {
      within-test-install &reference=v2.0.0 {
        cd ..

        epm:uninstall $test-package@v2.0.0

        put v2.0.0 |
          should-not-be-dir

        put v1.0.0 |
          should-be-dir
      }
    }

    >> 'when removing the dependencies, too' {
      >> 'the package should no more be listed' {
        within-test-install &reference=v2.0.0 {
          cd ..

          epm:uninstall $test-package@v2.0.0
          epm:uninstall $test-package@v1.0.0

          get-test-package-entries |
            should-emit []
        }
      }
    }
  }

  >> 'when no Git reference is specified' {
    >> 'the entire package root should be deleted' {
      within-test-install &reference=v2.0.0 {
        all $test-package-components[..-1] |
          path:join $epm:managed-dir (all) |
          cd (all)

        epm:uninstall $test-package

        put $test-package-components[-1] |
          should-not-be-dir
      }
    }
  }
}

>> 'Installing without passing packages' {
  var no-packages-error = 'You must specify at least one package.'

  >> 'when the metadata descriptor is missing' {
    fs:with-temp-dir { |temp-dir|
      cd $temp-dir

      epm:install |
        should-contain $no-packages-error
    }
  }

  >> 'when the metadata descriptor is present' {
    fs:with-temp-dir { |temp-dir|
      cd $temp-dir

      var metadata = [
        &description='Yet another package'
        &dependencies=[$test-package@v1.0.0]
        &devDependencies=[$test-package@v3.0.0]
      ]

      var all-dependencies = [(epm-plus:-get-all-dependencies $metadata)]

      put $metadata |
        to-json > metadata.json

      var packages-before-install = [(epm:list)]

      all $metadata[dependencies] | each { |dependency|
        if (has-value $packages-before-install $dependency) {
          fail 'Dependency '$dependency' already installed! The test would be pointless!'
        }
      }

      all $metadata[devDependencies] | each { |dev-dependency|
        if (has-value $packages-before-install $dev-dependency) {
          fail 'Dev dependency '$dev-dependency' already installed! The test would be pointless!'
        }
      }

      var install-output = (epm:install | slurp)

      defer {
        all $metadata[dependencies] | each $epm:uninstall~

        all $metadata[devDependencies] | each $epm:uninstall~
      }

      var packages-after-install = [(epm:list)]

      >> 'should display no error for lack of packages' {
        put $install-output |
          should-not-contain $no-packages-error
      }

      >> 'should make the dependencies available' {
        all $metadata[dependencies] | each { |dependency|
          put $packages-after-install |
            should-contain $dependency
        }
      }

      >> 'should make the dev dependencies available' {
        all $metadata[devDependencies] | each { |dev-dependency|
          put $packages-after-install |
            should-contain $dev-dependency
        }
      }
    }
  }
}

>> 'Creating link' {
  fs:with-temp-dir { |temp-dir|
    git clone $test-source-url $temp-dir

    cd $temp-dir

    git checkout v2.0.0

    >> 'by default' {
      epm-plus:link

      path:join $epm:managed-dir (all $test-package-components) v2 |
        cd (all)

      put $pwd |
        should-be $temp-dir
    }

    >> 'when requesting a full-version link' {
      epm-plus:link &full-version

      path:join $epm:managed-dir (all $test-package-components) v2.0.0 |
        cd (all)

      put $pwd |
        should-be $temp-dir
    }
  }
}