/*

MIT license

Author: Ken Domino, October 2023

Based on previous work of: Kazunori Sakamoto, Alexander Alexeev

*/

// $antlr-format alignTrailingComments true, columnLimit 150, minEmptyLines 1, maxEmptyLinesToKeep 1, reflowComments false, useTab false
// $antlr-format allowShortRulesOnASingleLine false, allowShortBlocksOnASingleLine true, alignSemicolons hanging, alignColons hanging

parser grammar LuaParser;

options {
    tokenVocab = LuaLexer;
}

start_
    : chunk EOF
    ;

chunk
    : block
    ;

block
    : stat* retstat?
    ;

stat
    : ';'
    | varlist '=' explist
    | compound // cfxlua
    | functioncall
    | label
    | 'break'
    | 'goto' identifier
    | 'while' exp 'do' block 'end'
    | 'repeat' block 'until' exp
    | 'if' exp 'then' block ('elseif' exp 'then' block)* ('else' block)? 'end'
    | 'for' identifier '=' exp ',' exp (',' exp)? 'do' block 'end'
    | 'for' namelist 'in' explist 'do' block 'end'
    | 'do' block 'end'
    | decorator* 'function' funcname funcbody
    | decorator* 'local' 'function' identifier funcbody
    | 'local' attnamelist ('=' explist)?
    | 'local' attnamelist 'in' prefixexp // cfxlua
    | 'defer' block 'end' // cfxlua
    | 'try' block 'catch' identifier 'then' block 'end'
    | 'throw' exp
    | class
    ;

attnamelist
    : identifier attrib (',' identifier attrib)*
    ;

attrib
    : ('<' identifier '>')?
    ;

retstat
    : ('return' explist? | 'break' | 'continue') ';'?
    ;

label
    : '::' identifier '::'
    ;

funcname
    : identifier ('.' identifier)* (':' identifier)?
    ;

varlist
    : var (',' var)*
    ;

namelist
    : identifier (',' identifier)*
    ;

decorator
    : '@' var decoratorbody
    ;

decoratorbody
    : ('(' explist? ')')?
    ;

newcall
    : 'new' functioncall
    ;

explist
    : exp (',' exp)*
    ;

exp
    : 'nil'
    | 'false'
    | 'true'
    | number
    | string
    | '...'
    | newcall
    | anonfunc
    | tablecomprehension
    | functiondef
    | prefixexp
    | tableconstructor
    | <assoc = right> exp ('^') exp
    | ('not' | '#' | '-' | '~') exp
    | exp ('*' | '/' | '%' | '//') exp
    | exp ('+' | '-') exp
    | <assoc = right> exp ('..') exp
    | exp ('<' | '>' | '<=' | '>=' | '~=' | '!=' | '==') exp
    | exp ('and' | 'or') exp
    | exp ('&' | '|' | '~' | '<<' | '>>') exp
    | exp 'in' exp
    | exp 'not' 'in' exp
    | exp '?' exp ':' exp
    ;

tablecomprehension
    : '{' exp (',' exp)? 'for' namelist 'in' explist ('if' exp)? '}'
    ;

anonfunc
    : '('? identifier ')'? 'do' exp
    | '(' parlist ')' 'do' block 'end'
    | '(' parlist ')' 'do' exp
    ;

indexed_member
    : '[' exp ']'
    | '.' identifier
    | '?''.' identifier
    ; 

// var ::=  Name | prefixexp '[' exp ']' | prefixexp '.' Name 
var
    : identifier
    | prefixexp (indexed_member)
    ;

// prefixexp ::= var | functioncall | '(' exp ')'
prefixexp
    : identifier (indexed_member)*
    | functioncall (indexed_member)*
    | '(' exp ')' (indexed_member)*
    ;

// functioncall ::=  prefixexp args | prefixexp ':' Name args;
functioncall
    : identifier (indexed_member)* args
    | functioncall (indexed_member)* args
    | '(' exp ')' (indexed_member)* args
    | identifier (indexed_member)* ':' identifier args
    | functioncall (indexed_member)* ':' identifier args
    | '(' exp ')' (indexed_member)* ':' identifier args
    ;

compound
    : var ('+=' | '-=' | '*=' | '/=' | '<<=' | '>>=' | '&=' | '|=' | '^=' ) exp
    ;

args
    : '(' explist? ')'
    | tableconstructor
    | string
    ;

functiondef
    : 'function' funcbody
    ;

funcbody
    : '(' parlist ')' block 'end'
    ;

class
    : 'class' identifier ('extends' identifier)? tableconstructor
    ;

partype
    : (':' identifier ('|' identifier)*)?
    ;

defaultvalue
    : '=' exp
    | // Required to preserve index position
    ;

extendedpar
    : identifier partype defaultvalue
    ;

extendedparlist
    : extendedpar (',' extendedpar)*
    ;

/* lparser.c says "is 'parlist' not empty?"
 * That code does so by checking la(1) == ')'.
 * This means that parlist can derive empty.
 */
parlist
    : extendedparlist (',' '...')?
    | '...'
    |
    ;

tableconstructor
    : '{' fieldlist? '}'
    ;

fieldlist
    : field (fieldsep field)* fieldsep?
    ;

field
    : '[' exp ']' '=' exp
    | '.' identifier // cfxlua (setconstructor)
    | identifier '=' exp
    | exp
    ;

fieldsep
    : ','
    | ';'
    ;

// Added keyword can be used also as identifiers for backwards compatibility
identifier
    : NAME
    | NEW
    ;

number
    : (INT)+
    | HEX
    | FLOAT
    | HEX_FLOAT
    ;

// String interpolation is done in `enterString()` inside `generator.ts`
string
    : NORMALSTRING
    | CHARSTRING
    | JENKINSHASHSTRING
    | LONGSTRING
    ;