use epm
use os
use path
use str
use ./epm-plus
use github.com/giancosta86/ethereal/v1/fake-git

var test-source-url = 'https://github.com/giancosta86/epm-plus-test'

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

        "homepage": "https://github.com/giancosta86/epm-plus-test",

        "dependencies": ["github.com/giancosta86/epm-plus-test@v1.0.0"]
      }
      '

      &'alpha.elv'='
        use ../v1.0.0/alpha v1

        fn f {
          / (v1:f) 18
        }
      '

      &'beta.elv'='
        use github.com/giancosta86/epm-plus-test/v1.0.0/alpha v1
        use ./alpha

        fn g {
          + (v1:f) (alpha:f)
        }
      '
    ]
  ]
])

set epm-plus:git~ = $git~

epm-plus:patch-epm

var within-test-install~ = (
  var test-root = (path:join $epm:managed-dir github.com giancosta86 epm-plus-test)

  var active-blocks = 0

  put { |&reference=$nil block|
    if (== $active-blocks 0) {
      os:remove-all $test-root
    }

    set active-blocks = (+ $active-blocks 1)

    defer {
      set active-blocks = (- $active-blocks 1)

      if (== $active-blocks 0) {
        os:remove-all $test-root
      }
    }

    var pkg = (
      if $reference {
        put github.com/giancosta86/epm-plus-test@$reference
      } else {
        put github.com/giancosta86/epm-plus-test
      }
    )

    epm:install $pkg

    {
      tmp pwd = (epm:dest $pkg)
      $block
    }
  }
)

fn get-test-package-list {
  epm:list |
    keep-if { |entry| str:has-prefix $entry github.com/giancosta86/epm-plus-test } |
    order |
    put [(all)]
}

>> 'In epm-plus' {
  >> 'splitting package name and version' {
    >> 'without version' {
      epm-plus:-split-package-name-and-version 'github.com/giancosta86/epm-plus-test' |
        put [(all)] |
        should-be [
          'github.com/giancosta86/epm-plus-test'
          $nil
        ]
    }

    >> 'with version' {
      epm-plus:-split-package-name-and-version 'github.com/giancosta86/epm-plus-test@v1.0.0' |
        put [(all)] |
        should-be [
          'github.com/giancosta86/epm-plus-test'
          'v1.0.0'
        ]
    }
  }

  >> 'computing the destination directory of a package' {
    >> 'without version' {
      epm:dest github.com/giancosta86/epm-plus-test |
        should-be (path:join $epm:managed-dir github.com giancosta86 epm-plus-test)
    }

    >> 'with version' {
      epm:dest github.com/giancosta86/epm-plus-test@v2.0.0 |
        should-be (path:join $epm:managed-dir github.com giancosta86 epm-plus-test v2.0.0)
    }
  }

  >> 'installing from a Git repository' {
    >> 'when requesting no specific reference' {
      >> 'should perform a basic clone from main' {
        within-test-install {
          os:is-regular main.elv |
            should-be $true
        }
      }
    }

    >> 'when requesting a standalone reference' {
      within-test-install &reference=v1.0.0 {
        >> 'should clone that reference' {
          os:is-regular main.elv |
            should-be $false

          os:is-regular alpha.elv |
            should-be $true
        }

        >> 'should not include the reference in the metadata src field' {
          epm:metadata github.com/giancosta86/epm-plus-test@v1.0.0 |
            put (all)[src] |
            should-be https://github.com/giancosta86/epm-plus-test
        }
      }
    }

    >> 'when installing a reference depending on another' {
      within-test-install &reference=v2.0.0 {
        >> 'the 2 reference directories should coexist' {
          os:is-regular alpha.elv |
            should-be $true

          os:is-regular beta.elv |
            should-be $true

          var test1-dest = (epm:dest github.com/giancosta86/epm-plus-test@v1.0.0)

          os:is-dir $test1-dest |
            should-be $true

          path:join $test1-dest alpha.elv |
            os:is-regular (all) |
            should-be $true
        }

        >> 'one reference scripts should be callable from the other' {
          use github.com/giancosta86/epm-plus-test/v1.0.0/alpha v1

          use github.com/giancosta86/epm-plus-test/v2.0.0/alpha
          use github.com/giancosta86/epm-plus-test/v2.0.0/beta

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

  >> 'getting all the dependencies from metadata' {
    >> 'should list both dependencies and dev dependencies' {
      var metadata = [
        &dependencies=[alpha beta gamma]
        &devDependencies=[delta epsilon]
      ]

      epm-plus:-get-all-dependencies $metadata |
        should-be [alpha beta gamma delta epsilon]
    }
  }

  >> 'listing Git packages' {
    >> 'when only the base reference is installed' {
      >> 'should list just the package name' {
        within-test-install {
          get-test-package-list |
            should-be [
              github.com/giancosta86/epm-plus-test
            ]
        }
      }
    }

    >> 'when a single reference is installed' {
      >> 'should list the package name with the reference' {
        within-test-install &reference=v1.0.0 {
          get-test-package-list |
            should-be [
              github.com/giancosta86/epm-plus-test@v1.0.0
            ]
        }
      }
    }

    >> 'when a reference installs another as a dependency' {
      >> 'should list both full packages' {
        within-test-install &reference=v2.0.0 {
          get-test-package-list |
            should-be [
              github.com/giancosta86/epm-plus-test@v1.0.0
              github.com/giancosta86/epm-plus-test@v2.0.0
            ]
        }
      }
    }

    >> 'when the base version and a reference are installed' {
      >> 'should list just the package name' {
        within-test-install {
          within-test-install &reference=v1.0.0 {
            get-test-package-list |
              should-be [
                github.com/giancosta86/epm-plus-test
              ]
          }
        }
      }
    }
  }

  >> 'uninstalling a Git package' {
    >> 'when the Git reference is specified' {
      >> 'the other references should remain' {
        within-test-install &reference=v2.0.0 {
          cd ..

          epm:uninstall github.com/giancosta86/epm-plus-test@v2.0.0

          os:is-dir v2.0.0 |
            should-be $false

          os:is-dir v1.0.0 |
            should-be $true
        }
      }

      >> 'when removing the other reference, too' {
        >> 'the package should no more be listed' {
          within-test-install &reference=v2.0.0 {
            cd ..

            epm:uninstall github.com/giancosta86/epm-plus-test@v1.0.0
            epm:uninstall github.com/giancosta86/epm-plus-test@v2.0.0

            get-test-package-list |
              should-be []
          }
        }
      }
    }

    >> 'when no Git reference is specified' {
      >> 'the entire package directory should be deleted' {
        within-test-install &reference=v2.0.0 {
          cd (path:join $epm:managed-dir github.com giancosta86)

          epm:uninstall github.com/giancosta86/epm-plus-test

          os:is-dir epm-plus-test |
            should-be $false
        }
      }
    }
  }

  >> 'installing without passing packages' {
    var temp-dir = (os:temp-dir)

    cd $temp-dir

    defer {
      cd (path:dir $temp-dir)
      os:remove-all $temp-dir
    }

    >> 'when the metadata descriptor is missing' {
      >> 'should display an error' {
        epm:install |
          str:contains (all) 'You must specify at least one package.' |
            should-be $true
      }
    }

    >> 'when the metadata descriptor is present' {
      var metadata = [
        &description='Test package'
        &dependencies=['github.com/giancosta86/epm-plus-test@v2.0.0']
        &devDependencies=['github.com/giancosta86/epm-plus-test@v1.0.0']
      ]

      var all-dependencies = (epm-plus:-get-all-dependencies $metadata)

      put $metadata |
        to-json > metadata.json

      var pre-install-packages = [(epm:list)]

      all $metadata[dependencies] | each { |dependency|
        if (has-value $pre-install-packages $dependency) {
          fail 'Dependency '$dependency' already installed! The test would be pointless!'
        }
      }

      all $metadata[devDependencies] | each { |dev-dependency|
        if (has-value $pre-install-packages $dev-dependency) {
          fail 'Dev dependency '$dev-dependency' already installed! The test would be pointless!'
        }
      }

      var install-output = (epm:install | slurp)

      defer {
        all $metadata[dependencies] | each { |dependency|
          epm:uninstall $dependency
        }

        all $metadata[devDependencies] | each { |dev-dependency|
          epm:uninstall $dev-dependency
        }
      }

      var post-install-packages = [(epm:list)]

      >> 'should display no error' {
        put $install-output |
          str:contains (all) 'You must specify at least one package.' |
            should-be $false
      }

      >> 'should make the dependencies available' {
        all $metadata[dependencies] | each { |dependency|
          has-value $post-install-packages $dependency |
            should-be $true
        }
      }

      >> 'should make the dev dependencies available' {
        all $metadata[devDependencies] | each { |dev-dependency|
          has-value $post-install-packages $dev-dependency |
            should-be $true
        }
      }
    }
  }

  >> 'creating link' {
    >> 'by default' {
      fs:with-temp-dir { |temp-dir|
        git clone $test-source-url $temp-dir

        cd $temp-dir

        git checkout v2.0.0

        epm-plus:link

        cd

        path:join $epm:managed-dir github.com giancosta86 epm-plus-test v2 |
          cd (all)

        put $pwd |
          should-be $temp-dir
      }
    }

    >> 'when requesting the full version' {
      fs:with-temp-dir { |temp-dir|
        git clone $test-source-url $temp-dir

        cd $temp-dir

        git checkout v2.0.0

        epm-plus:link &full-version

        cd

        path:join $epm:managed-dir github.com giancosta86 epm-plus-test v2.0.0 |
          cd (all)

        put $pwd |
          should-be $temp-dir
      }
    }
  }
}