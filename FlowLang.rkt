#lang eopl

;Valores denotados: Ref(valores expresados)
;Valores expresado:  enteros, flotantes, complejos, cadenas de caracteres, booleanos (true, false),
;                    nulos, funciones, listas, diccionarios y prototipos.



;***********************************************************************************************************************
;**********************************************    Especificación Léxica   *********************************************
;***********************************************************************************************************************

(define scanner-interpreter
'(
  (white-sp (whitespace) skip)
  (comment ("%" (arbno (not #\newline))) skip)
  (texto ( (arbno (or letter "-" ":")) ) string)
  (identifier (letter (arbno (or letter digit "?"))) symbol)
  (number (digit (arbno digit)) number)
  (number ("-" digit (arbno digit)) number)
  (number (digit (arbno digit) "." digit (arbno digit) ) number )
  (number ("-" digit (arbno digit) "." digit (arbno digit) ) number )

  ))

;Especificación Sintáctica (gramática)

(define grammar-simple-interpreter
  '((program (expression) a-program)
    (expression (number) lit-exp)
    (expression ("\""texto"\"" ) texto-lit)
    (expression ("print" "(" expression ")") print-exp) ;usar internamente el display de racket

    ; --- Declaraciones ---

    (var-item (identifier "=" expression) decl-item)
    (var-list (var-item (arbno "," var-item)) decl-list)
    (expression ("var" var-list ";") var-decl-exp)
    (expression ("const" var-list ";") const-decl-exp)

    ; --- Actualización ---
    (expression (identifier "=" expression) assign-exp)
    
    ; --- Funcion ---
    (expression ("func" "(" (separated-list identifier ",") ")" "{"
                        (arbno expression) "return" expression "}") func-exp)
    ; --- Función sin return (implícito null) ---
    (expression ("func" "(" (separated-list identifier ",") ")" "{"
                        (arbno expression) "}") func-exp-no-return)
    ; --- Función recursiva --- (puede quitarse si se logra implementar recursion en func)
    (expression ("recfunc" identifier "(" (separated-list identifier ",") ")" "{"
                           (arbno expression) "return" expression "}") recfunc-exp)
    
    ; --- invocacion ---
    (expression (identifier "(" (separated-list expression ",") ")") call-exp)
    
    ; --- Secuenciación --- opcional
    (expression ("begin" expression (arbno ";" expression) "end") begin-exp)

    ; --- Condicional ---
    (expression ("if" exp-bool "then" expression "else" (arbno expression) "end") if-exp)

    ; --- complex ---
    (expression ("complex" "(" expression expression "i" ")") complex-exp)
    (expression (complex-primitive "(" (separated-list expression ",") ")") complex-primitive-exp)

    ; --- switch ---
    (expression ("switch" "(" expression ")" "{"
                          (arbno "case" expression ":" "{" expression "}")
                          "default" ":" "{" expression "}"
                          "}") switch-exp)

    ; --- While ---
    (expression ("while" exp-bool "do" expression "done") while-exp)

    ; --- For ---
    (expression ("for" identifier "in" expression "do" expression "done") for-exp)

    ; --- Listas ---
    (expression ("[" (separated-list expression ",") "]") list-exp)

    ; --- Diccionarionarios ---
    (expression ("{" (separated-list identifier ":" expression ",") "}") dict-exp)
    ; --- uso de primitivas sobre diccionarios ---
    (expression (dict-primitive "(" (separated-list expression ",") ")") dict-prim-exp)
    
    ; --- uso de primitivas sobre cadenas ---
    (expression (string-primitive "(" (separated-list expression ",") ")") concat-string-exp)

    ; --- uso de primitivas sobre listas ---
    (expression (list-const-prim) list-const-exp)
    (expression (list-unaria-prim "(" expression ")") list-un-exp)
    (expression (list-binaria-prim "(" expression "," expression ")") list-bin-exp)
    (expression (list-trinaria-primitive "(" expression "," expression "," expression ")") list-tri-exp)

    
    ; --- Clonación ---
    (expression ("clone" "(" expression ")") clone-exp)
    ; --- Prototipos ---
    (expression ("prototipo" identifier "=" "{" (separated-list identifier ":" expression ",") "}") proto-decl-exp)
    ; --- Acceso a propiedad ---
    (expression (expression "." identifier) prop-access-exp)
    ; --- Asignación a propiedad ---
    (expression (expression "." identifier "=" expression) prop-assign-exp)
    

    ; --- Expresiones booleanas ---
    (exp-bool (pred-prim "(" expression "," expression ")") pred-bool-exp)
    (exp-bool (oper-bin-bool "(" exp-bool "," exp-bool ")") bin-bool-exp)
    (exp-bool (oper-un-bool "(" exp-bool ")") un-bool-exp)
    (exp-bool ("false") false-exp)
    (exp-bool ("true") true-exp)
    (exp-bool ("null") null-exp)

    ;;;;;;
    ; --- Primitivos relacionales y booleanos ---
    (pred-prim ("<") less-than-prim)
    (pred-prim (">") greater-than-prim)
    (pred-prim ("<=") less-equal-prim)
    (pred-prim (">=") greater-equal-prim)
    (pred-prim ("==") equal-prim)
    (pred-prim ("<>") not-equal-prim)

    (oper-bin-bool ("and") and-prim)
    (oper-bin-bool ("or")  or-prim)
    (oper-un-bool ("not") not-prim)

    ; --- Primitivos aritméticas ---
    (primitive ("+") add-prim)
    (primitive ("-") substract-prim)
    (primitive ("*") mult-prim)
    (primitive ("/") div-prim)
    (primitive ("%") mod-prim)
    (primitive ("add1") incr-prim)
    (primitive ("sub1") decr-prim)

    ; primitivas para complejos
    (complex-primitive ("sum-complex") sum-complex-prim)
    (complex-primitive ("sub-complex") sub-complex-prim)
    (complex-primitive ("mult-complex") mult-complex-prim)
    (complex-primitive ("div-complex") div-complex-prim)

    ; --- Primitivas sobre cadenas ---
    (string-primitive ("longitud") length-string-prim)
    (string-primitive ("concatenar") concat-string-prim)
    
    ; --- Primitivas sobre listas ---
    (list-const-prim ("vacio") empty-prim) ;crea una lista vacia
    
    (list-unaria-prim ("vacio?") empty?-prim)
    (list-unaria-prim ("lista?") list?-prim)
    (list-unaria-prim ("cabeza") head-prim)
    (list-unaria-prim ("cola") tail-prim)
    
    (list-binaria-prim ("crear-lista") make-list-prim)
    (list-binaria-prim ("append") append-prim)
    (list-binaria-prim ("ref-list") ref-list-prim) ;pregunta por el valor de una lista
    
    (list-trinaria-primitive ("set-list") set-list-prim)

    ; --- Primitivas sobre diccionarios ---
    (dict-primitive ("diccionario?") dict?-prim)
    (dict-primitive ("crear-diccionario") make-dict-prim)
    (dict-primitive ("ref-diccionario") ref-dict-prim)
    (dict-primitive ("set-diccionario") set-dict-prim)
    (dict-primitive ("claves") keys-dict-prim)
    (dict-primitive ("valores") values-dict-prim)

    ))

(sllgen:make-define-datatypes scanner-interpreter grammar-simple-interpreter)

(define show-the-datatypes
  (lambda () (sllgen:list-define-datatypes scanner-interpreter grammar-simple-interpreter)))

;***********************************************************************************************************************
;*******************************************    Parser, Scanner, Interfaz     ******************************************
;***********************************************************************************************************************

;El FrontEnd (Análisis léxico (scanner) y sintáctico (parser) integrados)

(define scan&parse
  (sllgen:make-string-parser scanner-interpreter grammar-simple-interpreter))

;El Analizador Léxico (Scanner)

(define just-scan
  (sllgen:make-string-scanner scanner-interpreter grammar-simple-interpreter))

;El Interpretador (FrontEnd + Evaluación + señal para lectura )

(define interpretador
  (sllgen:make-rep-loop  "--> "
    (lambda (pgm) (eval-program  pgm)) 
    (sllgen:make-stream-parser 
      scanner-spec-simple-interpreter
      grammar-simple-interpreter)))
