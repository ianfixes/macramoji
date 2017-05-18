/*
  extensimoji

  Emoji functional macro language.

  Emoji are slack-style, e.g. :+1:
  Functions take the form :something(): or :()something:
  Inside the parens can be functions or emoji, separated by commas.

  :(:dealwithit(:poop:, :kamina-glasses:):)splosion:

  via https://boston.slack.com/customize/emoji
  Custom emoji names can only contain lower case letters, numbers, dashes and underscores.
*/

%lex
%%

":"          { return ':'; }
"("          { return '('; }
")"          { return ')'; }
","\s?       { return ','; }
[a-z0-9_+-]+ { return 'VAR'; }
<<EOF>>      { return 'EOF'; }
/lex


%left SEP

%%

extensimoji
  : emojifunk EOF
    { return $emojifunk; }
  ;

emojifunk
  : ':' var '(' arg_list ')' ':'
    { $$ = { 'entity': 'funk', 'name': $var, 'args': $arg_list }; }
  | ':' '(' arg_list ')' var ':'
    { $$ = { 'entity': 'funk', 'name': $var, 'args': $arg_list }; }
  ;

expr
  : emoji
    { $$ = $emoji; }
  | emojifunk
    { $$ = $emojifunk; }
  ;

arg_list
  : arg_list ',' expr
    { $$ = $arg_list; $$.push($expr); }
  | expr
    { $$ = [$expr]; }
  ;

emoji
  : ':' var ':'
    { $$ = { 'entity': 'emoji', 'name': $var }; }
  ;

var
  : VAR
    { $$ = yytext; }
  ;

