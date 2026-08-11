use path

path:join (get-env velvet-dir) $expected-tag |
  cd (all)

>> 'Git version for Velvet' {
  >> 'when at a specific tag' {
    var expected-tag = (get-env expected-tag)

    git describe --tags --always |
      should-be $expected-tag
  }
}
