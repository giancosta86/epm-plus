>> 'Installing from a Git repository' {
  >> 'when requesting no specific reference' {
    >> 'should perform a basic clone from main' {
      fail-test
    }
  }

  >> 'when requesting a specific reference' {
    >> 'should clone that reference' {
      fail-test
    }
  }

  >> 'when installing 2 specific versions' {
    >> 'the 2 directories should coexist' {
      fail-test
    }

    >> 'when not requesting main' {
      >> 'the root directory should be empty' {
        fail-test
      }
    }

    >> 'when requesting main' {
      >> 'the root directory should contain the files from main' {
        fail-test
      }
    }
  }
}