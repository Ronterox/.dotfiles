" Vim syntax file
" Language: Pine Script
" Maintainer: Ricardo Montserrat
" Latest Revision: 2023-11-15

if exists("b:current_syntax")
  finish
endif

" Case sensitivity
syntax case match

" Pine Script keywords
syntax keyword pinescriptKeyword const var if else switch for while to by return type
syntax keyword pinescriptKeyword true false na null and or not

" Pine Script functions
syntax keyword pinescriptFunction security strategy indicator
syntax keyword pinescriptFunction plot hline barcolor fill strategy
syntax keyword pinescriptFunction hour minute month year long short
syntax match pinescriptFunction "\v<%((ta|strategy|math|input|array)\.)?\h\w*>%(\s*\([^)]*\))@="

" Pine Script types
syntax keyword pinescriptType int float bool string color series line
syntax keyword pinescriptType simple syminfo

" Operators
syntax match pinescriptOperator "\v\*"
syntax match pinescriptOperator "\v/"
syntax match pinescriptOperator "\v\+"
syntax match pinescriptOperator "\v-"
syntax match pinescriptOperator "\v\="
syntax match pinescriptOperator "\v\=\="
syntax match pinescriptOperator "\v\!\="
syntax match pinescriptOperator "\v\>"
syntax match pinescriptOperator "\v\<"
syntax match pinescriptOperator "\v\>\="
syntax match pinescriptOperator "\v\<\="
syntax match pinescriptOperator "\v\&\&"
syntax match pinescriptOperator "\v\|\|"
syntax match pinescriptOperator "\v\:"
syntax match pinescriptOperator "\v\?"

" Comments
syntax match pinescriptComment "//.*$"
syntax region pinescriptComment start="/\*" end="\*/"

" Strings
syntax region pinescriptString start=/\v"/ skip=/\v\\./ end=/\v"/
syntax region pinescriptString start=/\v'/ skip=/\v\\./ end=/\v'/

" Numbers
syntax match pinescriptNumber "\v<\d+>"
syntax match pinescriptNumber "\v<\d+\.\d+>"
syntax match pinescriptNumber "\v<\.\d+>"
syntax match pinescriptNumber "\v<\d+e[+-]?\d+>"
syntax match pinescriptNumber "\v<\d+\.\d+e[+-]?\d+>"

" Built-in variables
syntax keyword pinescriptBuiltin close open high low volume time hl2 hlc3 ohlc4
syntax keyword pinescriptBuiltin bar_index dayofweek timeframe ticker
syntax match pinescriptBuiltin "\vorder\.\h\w*"
syntax match pinescriptBuiltin "\vsyminfo\.\h\w*"
syntax match pinescriptBuiltin "\vstrategy\.\h\w*"
syntax match pinescriptBuiltin "\vcolor\.\h\w*"

" Highlight links
highlight link pinescriptKeyword Keyword
highlight link pinescriptFunction Function
highlight link pinescriptType Type
highlight link pinescriptOperator Operator
highlight link pinescriptComment Comment
highlight link pinescriptString String
highlight link pinescriptNumber Number
highlight link pinescriptBuiltin Identifier

setlocal commentstring=//%s
setlocal comments=://

let b:current_syntax = "pinescript"
