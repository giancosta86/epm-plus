tmp pwd = (get-env velvet-dir)

git branch --show-current |
  should-be main