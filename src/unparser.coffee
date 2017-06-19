# turn a parsed tree back into a string, for better error messages
unparse = (tree) ->
  return ":#{tree.name}:" if tree.entity == 'emoji'
  args = tree.args.map (x) -> unparse(x)
  argStr = args.join(', ')
  switch tree.is
    when 'prefix' then "#{tree.name}(#{argStr})"
    when 'suffix' then "(#{argStr})#{tree.name}"
    else JSON.stringify tree  # basically give up

# turn a parsed tree back into a string, for better error messages
unparseEnglish = (tree) ->
  return "#{tree.name}" if tree.entity == 'emoji'
  args = tree.args.map (x) -> unparseEnglish(x)
  argStr = args.join('-')
  switch tree.is
    when 'prefix' then "#{tree.name}-#{argStr}"
    when 'suffix' then "#{argStr}-#{tree.name}"
    else JSON.stringify tree  # basically give up


module.exports =
  unparse: unparse
  unparseEnglish: unparseEnglish
