unparse_helper = (tree) ->
  return ":#{tree.name}:" if tree.entity == 'emoji'
  args = tree.args.map (x) -> unparse_helper(x)
  argStr = args.join(', ')
  switch tree.is
    when 'prefix' then "#{tree.name}(#{argStr})"
    when 'suffix' then "(#{argStr})#{tree.name}"
    else JSON.stringify tree

unparse = (tree) ->
  ":#{unparse_helper(tree)}:"

module.exports =
  unparse: unparse
