" Case sensitivity
syntax case match

" Pine Script keywords
syntax keyword monkeyKeyword let fn true false if else return null

" Pine Script functions
syntax match monkeyFunction "\v<%(\w+)?\h\w*>%(\s*\([^)]*\))@="

" Pine Script types
syntax keyword monkeyType int float string array

" Operators
syntax match monkeyOperator "\v\*"
syntax match monkeyOperator "\v/"
syntax match monkeyOperator "\v\+"
syntax match monkeyOperator "\v-"
syntax match monkeyOperator "\v\="
syntax match monkeyOperator "\v\=\="
syntax match monkeyOperator "\v\!\="
syntax match monkeyOperator "\v\>"
syntax match monkeyOperator "\v\<"
syntax match monkeyOperator "\v\>\="
syntax match monkeyOperator "\v\<\="
syntax match monkeyOperator "\v\&\&"
syntax match monkeyOperator "\v\|\|"
syntax match monkeyOperator "\v\:"
syntax match monkeyOperator "\v\?"

" Comments
syntax match monkeyComment "//.*$"
syntax region monkeyComment start="/\*" end="\*/"

" Strings
syntax region monkeyString start=/\v"/ skip=/\v\\./ end=/\v"/

" Numbers
syntax match monkeyNumber "\v<\d+>"
syntax match monkeyNumber "\v<\d+\.\d+>"
syntax match monkeyNumber "\v<\.\d+>"
syntax match monkeyNumber "\v<\d+e[+-]?\d+>"
syntax match monkeyNumber "\v<\d+\.\d+e[+-]?\d+>"

" Built-in variables
syntax keyword monkeyBuiltin len first last push
"syntax match monkeyBuiltin "\vorder\.\h\w*"

" Highlight links
highlight link monkeyKeyword Keyword
highlight link monkeyFunction Function
highlight link monkeyType Type
highlight link monkeyOperator Operator
highlight link monkeyComment Comment
highlight link monkeyString String
highlight link monkeyNumber Number
highlight link monkeyBuiltin Identifier

setlocal commentstring=//%s
setlocal comments=://

let b:current_syntax = "monkey"
