>> 'Git version for Velvet' {
  >> 'when in the main branch' {
    tmp pwd = (get-env velvet-dir)

    git branch --show-current |
      should-be main
  }
}