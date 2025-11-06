#lang eopl
; require racket/file
; require file-> string funcion
;Valores denotados: Ref(valores expresados)
;Valores expresado:  enteros, flotantes, complejos, cadenas de caracteres, booleanos (true, false),
;                    nulos, funciones, listas, diccionarios y prototipos.



;***********************************************************************************************************************
;**********************************************    Especificación Léxica   *********************************************
;***********************************************************************************************************************

(define scanner-interpreter
'(
  (identifier (letter (arbno (or letter digit "?" "-" "_" ":"))) symbol)
  (white-sp (whitespace) skip)
  (comment ("%" (arbno (not #\newline))) skip)
  (number (digit (arbno digit)) number)
  (number ("-" digit (arbno digit)) number)
  (number (digit (arbno digit) "." digit (arbno digit) ) number )
  (number ("-" digit (arbno digit) "." digit (arbno digit) ) number )

  ))

;Especificación Sintáctica (gramática)

(define grammar-simple-interpreter
  '((program ((arbno expression) "end") a-program)
    (expression (number) lit-exp)
    (expression ("\'"identifier"\'" ) texto-lit)
    (expression ("print" "(" expression ")") print-exp) ;usar internamente el display de racket
    (expression (primitive "(" (separated-list expression ",")")") primapp-exp)
    ; --- Declaraciones ---

    
    (var-item (identifier "=" expression) decl-item)
    (var-list (var-item (arbno "," var-item)) decl-list)
    (expression ("var" var-list ";") var-decl-exp)
    (expression ("const" var-list ";") const-decl-exp)

    
    ;---- Llamado de valor de variable también va a identifier exp ------
    ; --- Actualización de valor de variable (Va a identifier exp)-------
    
    
    ; --- Funcion ---
    (expression ("func" "(" (separated-list identifier ",") ")" "{"
                        (arbno expression) opt-return "}") func-exp)

    (opt-return ("return" expression) with-return)
    (opt-return () no-return)
    
    ; --- Función sin return (implícito null) ---
    ;(expression ("func" "(" (separated-list identifier ",") ")" "{"
     ;                   (arbno expression) "}") func-exp-no-return)
    
    ; --- Función recursiva --- (puede quitarse si se logra implementar recursion en func)
    (expression ("recfunc" identifier "(" (separated-list identifier ",") ")" "{"
                           (arbno expression) "return" expression "}") recfunc-exp)
    
    ; --- invocacion de funcion va a identifier exp ---

    ;----- identifier exp (Para invocar funciones, actualizar valores y poner el valor de variable)---------

    (expression (identifier identifier-suffix) identifier-exp)
    ;------- Devolver el valor de una variable -------;
    (identifier-suffix ()
                       val-var-suffix)
    ;-------- Actualizar el valor de una variable---------;
    (identifier-suffix ("=" expression)
                       assign-suffix)
    ;-------- Llamar (evaluar) una función con parámetros ----------;
    (identifier-suffix ("(" (separated-list expression ",") ")")
                       call-suffix)
    
    
    
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
    (expression ("prototype" identifier "=" "{" (separated-list identifier ":" expression ",") "}") proto-decl-exp)
    ; ------- Expresión de atributo (Para acceder o modificar atributo en prototipo) ----------
    (expression ("access" expression "." identifier property-suffix) prop-property-exp)
    ; --- Acceso a propiedad ---
    (property-suffix () prop-access-suffix)
    ; --- Asignación a propiedad ---
    (property-suffix ("=" expression) prop-assign-suffix)
    

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


;***********************************************************************************************************************
;*******************************************    Parser, Scanner, Interfaz     ******************************************
;***********************************************************************************************************************

(sllgen:make-define-datatypes scanner-interpreter grammar-simple-interpreter)

(define show-the-datatypes
  (lambda () (sllgen:list-define-datatypes scanner-interpreter grammar-simple-interpreter)))

;*******************************************************************************************
;Parser, Scanner, Interfaz

;El FrontEnd (Análisis léxico (scanner) y sintáctico (parser) integrados)

(define scan&parse
  (sllgen:make-string-parser scanner-interpreter grammar-simple-interpreter))

;El Analizador Léxico (Scanner)

(define just-scan
  (sllgen:make-string-scanner scanner-interpreter grammar-simple-interpreter))

;El Interpretador (FrontEnd + Evaluación + señal para lectura )

(define interpretador
  (sllgen:make-rep-loop "--> "
    (lambda (pgm) (eval-program pgm))
    (sllgen:make-stream-parser
      scanner-interpreter        ; <-- El nombre correcto
      grammar-simple-interpreter)))

;***********************************************************************************************************************
;*************************************    Valores especiales, referencia y blanco   ************************************
;***********************************************************************************************************************
;Procedimientos
(define-datatype special-val special-val?
  (void-val)
  (null-val)
)

(define-datatype procval procval?
  (closure
   (ids (list-of symbol?))
   (body expression?)
   (env environment?)))


(define-datatype target target?
  ; Añade el flag 'mutable?' al 'direct-target'
  (direct-target (expval expval?) (mutable? boolean?))
  (indirect-target (ref ref-to-direct-target?)))

(define-datatype reference reference?
  (a-ref (position integer?) (vec vector?)))

;***********************************************************************************************************************
;**************************************************    Ambientes    ***************************************************
;***********************************************************************************************************************
;definición del tipo de dato ambiente
(define-datatype environment environment?
  (empty-env-record)
  (extended-env-record
   (syms (list-of symbol?))
   (vec vector?)
   (env environment?)))

(define scheme-value? (lambda (v) #t))

;empty-env:      -> enviroment
;función que crea un ambiente vacío
(define empty-env  
  (lambda ()
    (empty-env-record)))       ;llamado al constructor de ambiente vacío 


;extend-env: <list-of symbols> <list-of numbers> enviroment -> enviroment
;función que crea un ambiente extendido
(define extend-env
  (lambda (syms vals env)
    (extended-env-record syms (list->vector vals) env)))

;extend-env-recursively: <list-of symbols> <list-of <list-of symbols>> <list-of expressions> environment -> environment
;función que crea un ambiente extendido para procedimientos recursivos
(define extend-env-recursively
  (lambda (proc-names idss bodies old-env)
    (let ((len (length proc-names)))
      (let ((vec (make-vector len)))
        (let ((env (extended-env-record proc-names vec old-env)))
          (for-each
            (lambda (pos ids body)
              (vector-set! vec pos (direct-target (closure ids body env))))
            (iota len) idss bodies)
          env)))))

;iota: number -> list
;función que retorna una lista de los números desde 0 hasta end
(define iota
  (lambda (end)
    (let loop ((next 0))
      (if (>= next end) '()
        (cons next (loop (+ 1 next)))))))

;función que busca un símbolo en un ambiente
(define apply-env
  (lambda (env sym)
    ;(begin
     ; (display env)
      ;(display "jajajaj ")
      (deref (apply-env-ref env sym))))
    ;)
(define apply-env-ref
  (lambda (env sym)
    (cases environment env
      (empty-env-record ()
                        (eopl:error 'apply-env-ref "No binding for ~s" sym))
      (extended-env-record (syms vals env)
                           (let ((pos (rib-find-position sym syms)))
                             (if (number? pos)
                                 (a-ref pos vals)
                                 (apply-env-ref env sym)))))))
;***********************************************************************************************************************
;**************************************************    Blancos y referencias    ***************************************************
;***********************************************************************************************************************

(define expval?
  (lambda (x)
    (or (number? x) (procval? x))))

(define ref-to-direct-target?
  (lambda (x)
    (and (reference? x)
         (cases reference x
           (a-ref (pos vec)
                  (cases target (vector-ref vec pos)
                    ; Coincide con 2 campos
                    (direct-target (v mutable?) #t) 
                    (indirect-target (v) #f)))))))

(define deref
  (lambda (ref)
    (cases target (primitive-deref ref)
      (direct-target (expval mutable?) expval)
      (indirect-target (ref1)
                       (cases target (primitive-deref ref1)
                         (direct-target (expval mutable?) expval)
                         (indirect-target (p)
                                          (eopl:error 'deref
                                                      "Illegal reference: ~s" ref1)))))))

(define primitive-deref
  (lambda (ref)
    (cases reference ref
      (a-ref (pos vec)
             (vector-ref vec pos)))))

(define setref!
  (lambda (ref expval)
    (let
        ((ref (cases target (primitive-deref ref)
                (direct-target (expval1 mutable?) ref)
                (indirect-target (ref1) ref1))))
      (primitive-setref! ref (direct-target expval)))))

(define primitive-setref!
  (lambda (ref val)
    (cases reference ref
      (a-ref (pos vec)
             (vector-set! vec pos val)))))

;***********************************************************************************************************************
;**************************************************    Funciones auxiliares    ***************************************************
;***********************************************************************************************************************
; funciones auxiliares para encontrar la posición de un símbolo
; en la lista de símbolos de un ambiente

(define rib-find-position 
  (lambda (sym los)
    (list-find-position sym los)))

(define list-find-position
  (lambda (sym los)
    (list-index (lambda (sym1) (eqv? sym1 sym)) los)))

(define list-index
  (lambda (pred ls)
    (cond
      ((null? ls) #f)
      ((pred (car ls)) 0)
      (else (let ((list-index-r (list-index pred (cdr ls))))
              (if (number? list-index-r)
                (+ list-index-r 1)
                #f))))))
;***********************************************************************************************************************
;**************************************************    Interprete    ***************************************************
;***********************************************************************************************************************

(define init-env
  (lambda ()
    (extend-env
     '(x y z)
     (list (direct-target 1 #t)
           (direct-target 5 #t)
           (direct-target 10 #t))
     (empty-env))))

; El punto de entrada principal del intérprete.
(define eval-program
  (lambda (pgm)
    (cases program pgm
      
      ; 'exps-list' es la lista que viene de (arbno expression)
      (a-program (exps-list)
        (eval-sequence exps-list (init-env)))
      
      )))

; Función auxiliar para evaluar listas de expresiones secuencialmente.
(define eval-sequence
  (lambda (exps env)
    (if (null? exps)
        (void-val) ; Caso base: no hay más expresiones.
        
        (let ((exp1 (car exps)))
          (cases expression exp1
            
            ; CASO 1: 'var' es una DECLARACIÓN (Mutable)
            (var-decl-exp (var-list-ast)
              (let ((new-env (eval-declarations var-list-ast env #t))) ; <-- ¡ARREGLO: Pasa #t!
                (eval-sequence (cdr exps) new-env)))
            
            ; CASO 2: 'const' es una DECLARACIÓN (Inmutable)
            (const-decl-exp (var-list-ast)
              (let ((new-env (eval-declarations var-list-ast env #f))) ; <-- ¡ARREGLO: Pasa #f!
                (eval-sequence (cdr exps) new-env)))
            
            ; CASO 3: Es una EXPRESIÓN normal (print, +, if, etc.).
            (else
              ; Llama al 'Especialista' (eval-expression)
              (let ((val1 (eval-expression exp1 env)))
                
                ; Si es la última expresión, devuelve su valor
                (if (null? (cdr exps))
                    val1
                    
                    ; Si no, ignora el valor y sigue con el 'env' VIEJO
                    (eval-sequence (cdr exps) env) 
                    ))))))))

; Esta función procesa la lista de (var-item) y devuelve un nuevo ambiente
(define eval-declarations
  (lambda (var-list-ast env is-mutable?) ; <-- Acepta el flag
    (cases var-list var-list-ast
      (decl-list (item1 rest-items)
        (let ((all-items (cons item1 rest-items)))
          (let loop ((item-list all-items) (current-env env))
            (if (null? item-list)
                current-env ; Devuelve el ambiente final
                (cases var-item (car item-list)
                  (decl-item (id exp)
                    (let ((val (eval-expression exp current-env)))
                      (let ((next-env 
                             (extend-env
                              (list id)
                              (list (direct-target val is-mutable?)) ; <-- ¡Usa el flag!
                              current-env)))
                        (loop (cdr item-list) next-env))))))))))))

(define eval-expression
  (lambda (exp env)
    1))


;; Ejecutamos el interpretador

(interpretador)