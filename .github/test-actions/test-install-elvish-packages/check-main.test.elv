cd (get-env velvet-dir)

>> 'Git version for Velvet' {
  >> 'when in the main branch' {
    git branch --show-current |
      should-be main
  }
}