%{ open Ast %}
%token SEMICOLON
%token LEFTBRACE LEFTPAREN LEFTBRAC RIGHTBRACE RIGHTPAREN RIGHTBRAC COMMA
%token ADDOP SUBOP MULOP DIVOP MODOP
%token SWAP CONCAT TYPEASSIGNMENT LINEBUFFER
%token EQ NEQ LT GT LEQ GEQ
%token NOT AND OR
%token ASSIGN
%token IF ELIF ELSE WHILELOOP FORLOOP BREAK CONTINUE VOID NULL
%token EOF
%token IMPORT FUNCTION RETURN MAIN
%token CONTINUE
%token BREAK
%token <string> ID
%token IDTEST
%token <string> STRING
%token <int> INT
%token <float> FLOAT
%token <bool> BOOL
%token INTD BOOLD STRINGD FLOATD PDFD PAGED LINED LISTD TUPLED IMAGED MAPD
%left ASSIGN
%left OR
%left AND
%left EQ NEQ
%nonassoc LT LEQ GT GEQ
%left ADDOP SUBOP
%left CONCAT
%left LINEBUFFER
%left MULOP DIVOP MODOP
%nonassoc TYPEASSIGNMENT
%right NOT
%left LEFTBRAC RIGHTBRACK
%left LEFTPAREN RIGHTPAREN
%start program
%type <Ast.program> program
%%

program:
  import_decl_list main_func_decl_option func_decl_list EOF  { { ilist = List.rev $1 ; mainf = $2 ; declf = List.rev $3} }

main_func_decl_option:
  MAIN LEFTPAREN RIGHTPAREN body { { body = $4 }  }

decl:
  ID TYPEASSIGNMENT data_type   { Vdecl(Ast.IdTest($1),$3) }
  | ID TYPEASSIGNMENT LISTD recr_data_type { ListDecl(Ast.IdTest($1), $4) }
  | ID TYPEASSIGNMENT sp_data_type    { ObjectCreate(Ast.IdTest($1), $3, []) }
  | ID TYPEASSIGNMENT MAPD data_type COMMA recr_data_type { MapDecl(Ast.IdTest($1),$4,$6) }

import_decl_list:
                                   { [] }
  | import_decl_list import_decl { $2::$1 }

func_decl_list:
                                    { [] }
  | func_decl_list func_decl        { $2::$1 }

func_decl :
  ID LEFTPAREN decl_list RIGHTPAREN TYPEASSIGNMENT recr_data_type body {
    { rtype = $6 ; name = $1; formals = $3 ; body = $7; }
  }

import_decl:
	IMPORT LEFTPAREN STRING RIGHTPAREN SEMICOLON { Import($3) }

stmt_list:
   /* nothing */  { [] }
 | stmt_list stmt { $2 :: $1 }

decl_list:
   /* nothing */  { [] }
 | decl { [$1] }
 | decl COMMA decl_list { $1 :: $3 }

expr_list:
   /* nothing */  { [] }
  | expr { [$1] }
  | expr COMMA expr_list {$1 :: $3 }

body:
   LEFTBRACE stmt_list RIGHTBRACE { List.rev $2 }

function_call:
     ID LEFTPAREN expr_list RIGHTPAREN                     { ($1, $3) }

stmt:
  | assign_stmt SEMICOLON                                           { $1 }
  | FORLOOP LEFTPAREN assign_stmt SEMICOLON expr_stmt SEMICOLON assign_stmt RIGHTPAREN body { For($3, $5, $7, $9) }
  | RETURN expr SEMICOLON                                           { Ret($2) }
  | function_call  SEMICOLON                                        { CallStmt(fst $1,snd $1) }
  | v_decl                                                          { ($1) }
  | WHILELOOP LEFTPAREN expr_stmt RIGHTPAREN body                   { While($3, $5) }
  | ID TYPEASSIGNMENT sp_data_type LEFTPAREN expr_list RIGHTPAREN SEMICOLON  { ObjectCreate(Ast.IdTest($1), $3, $5) }
  | ID TYPEASSIGNMENT LISTD data_type LEFTPAREN expr_list RIGHTPAREN SEMICOLON  { ListInit(Ast.IdTest($1), $4, $6) }
  | IF LEFTPAREN expr_stmt RIGHTPAREN body elifs else_opt           {If({condition = $3; body = $5} :: $6, $7)}
  | ID ADDOP ASSIGN expr COMMA expr SEMICOLON                       { MapAdd(Ast.IdTest($1), $4, $6) }
  | ID SUBOP ASSIGN expr SEMICOLON                                  { MapRemove(Ast.IdTest($1), $4) }
  | ID ADDOP ASSIGN expr SEMICOLON                                  { ListAdd(Ast.IdTest($1), $4) }
  | ID SUBOP ASSIGN LEFTBRAC expr RIGHTBRAC SEMICOLON               { ListRemove(Ast.IdTest($1), $5) }
  | controlstmt SEMICOLON                                           { ControlStmt($1) }

controlstmt:
  | CONTINUE            { "Continue" }
  | BREAK               {  "Break" }

elifs:
  | {[]}
  | ELIF LEFTPAREN expr_stmt RIGHTPAREN body elifs { {condition = $3; body = $5} :: $6 }

else_opt:
  | {None}
  | ELSE body {Some($2)}

recr_data_type:
  | sp_data_type                                                               { (Ast.TType($1)) }
  | data_type                                                                  { (Ast.TType($1)) }
  | LISTD recr_data_type                                                       { (Ast.RType($2)) }

v_decl :
| decl SEMICOLON                           { ($1) }

assign_stmt:
  ID ASSIGN expr                                                  { Assign(Ast.IdTest($1), $3) }
| ID TYPEASSIGNMENT data_type ASSIGN expr                         { InitAssign(Ast.IdTest($1),$3,$5) }
| list_access ASSIGN expr                                         { ListAssign(ListAccess(fst $1, snd $1), $3) }

expr_stmt:
  expr EQ     expr                                                { Binop($1, Equal,   $3) }
| expr NEQ    expr                                                { Binop($1, Neq,     $3) }
| expr LT     expr                                                { Binop($1, Less,    $3) }
| expr LEQ    expr                                                { Binop($1, Leq,     $3) }
| expr GT     expr                                                { Binop($1, Greater, $3) }
| expr GEQ    expr                                                { Binop($1, Geq,     $3) }
| expr AND expr                                                   { Binop($1, And, $3)}
| expr OR expr                                                    { Binop($1, Or, $3)}


data_type:
STRINGD                                                             { String }
| INTD                                                              { Int }
| FLOATD                                                            { Float }
| BOOLD                                                             { Bool }
| PDFD                                                              { Pdf }
| PAGED                                                             { Page }

sp_data_type:
LINED { Line }
| TUPLED { Tuple }
| IMAGED { Image }

expr:
STRING               { LitString($1) }
| INT                { LitInt($1) }
| FLOAT              { LitFloat($1)}
| BOOL               { LitBool($1) }
| ID		             { Iden(Ast.IdTest($1)) }
| list_access        { ListAccess(fst $1,snd $1) }
| ID TYPEASSIGNMENT ASSIGN expr { MapAccess(Ast.IdTest($1), $4) }
| expr ADDOP expr    { Binop($1, Add, $3) }
| expr SUBOP expr    { Binop($1, Sub, $3) }
| expr MULOP expr    { Binop($1, Mul, $3) }
| expr DIVOP expr    { Binop($1, Div, $3) }
| expr CONCAT expr   { Binop($1, Concat,  $3) }
| expr MODOP expr    { Binop($1, Mod,     $3) }
| LEFTPAREN expr RIGHTPAREN { $2 }
| expr_stmt          { $1 }
| NOT  expr          { Uop(Not,$2) }
| SUBOP expr         { Uop(Neg,$2) }
| expr LINEBUFFER    { Uop(LineBuffer,$1) }
| function_call     {CallExpr(fst $1,snd $1)}

list_access:
ID LEFTBRAC expr RIGHTBRAC { (Ast.IdTest($1), $3) }
