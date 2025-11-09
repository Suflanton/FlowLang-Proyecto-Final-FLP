#lang eopl
(require racket/file)
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
    (expression ("@ENV") environment-exp)
    (expression (number) lit-exp)
    (expression ("\""identifier"\"" ) text-lit)
    (expression ("print" "(" expression ")") print-exp) ;usar internamente el display de racket
    (expression (primitive "(" (separated-list expression ",")")") primapp-exp)
    
    ; --- Declaraciones ---
    (expression ("var" (separated-list identifier "=" expression ",") ";") var-decl-exp)
    (expression ("const" (separated-list identifier "=" expression ",") ";") const-decl-exp)

    
    ;---- Llamado de valor de variable también va a identifier exp ------
    ; --- Actualización de valor de variable (Va a identifier exp)-------
    
    
    ; --- Funcion ---
    (expression ("func" identifier "(" (separated-list identifier ",") ")" "{"
                        (arbno expression)"}") func-exp)
    ; --- Funcion anónima ----
    (expression ("lambda"  "(" (separated-list identifier ",") ")" "{"
                        expression "}") lambda-exp)
    
    ;------ Retorno para función (Sirve como una detención de un flujo de secuencias, más o menos como un break)----------
    
    (expression ("return" opt-return-val) return-exp) ; <-- Nueva regla principal
    
    (opt-return-val (expression) with-return-val)   ; <-- Variante 1: Había un valor
    (opt-return-val ("") no-return-val)

    
    ; --- Función sin return (implícito null) ---
    ;(expression ("func" "(" (separated-list identifier ",") ")" "{"
     ;                   (arbno expression) "}") func-exp-no-return)
    
    ; --- Función recursiva --- (puede quitarse si se logra implementar recursion en func)
    ;(expression ("recfunc" identifier "(" (separated-list identifier ",") ")" "{"
    ;                       (arbno expression) "return" expression "}") recfunc-exp)
    
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
    (expression ("if" "(" expression ")" "then" "{" (arbno expression) "}"
             (arbno "elif" "(" expression ")" "then" "{" (arbno expression) "}")
             "else" "{" (arbno expression)
             "}")
            if-exp)

    ; --- complex ---
    (expression ("complex" "(" expression expression "i" ")") complex-exp)
    (expression (complex-primitive "(" (separated-list expression ",") ")") complex-primitive-exp)

    ; --- switch ---
    (expression ("switch" "(" expression ")" "{"
                          (arbno "case" expression ":" "{" expression "}")
                          "default" ":" "{" expression "}"
                          "}") switch-exp)

    ; --- While ---
    (expression ("while" expression "do" expression "done") while-exp)

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
    (expression (pred-prim "(" expression "," expression ")") pred-bool-exp)
    (expression (oper-bin-bool "(" expression "," expression ")") bin-bool-exp)
    (expression (oper-un-bool "(" expression ")") un-bool-exp)
    (expression ("false") false-exp)
    (expression ("true") true-exp)
    (expression ("null") null-exp)

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

(define null-val?
  (lambda (v)
    (cases special-val v
      (null-val () #t)
      (else #f))))

(define void-val?
  (lambda (v)
    (cases special-val v
      (void-val () #t)
      (else #f))))

(define-datatype procval procval?
  (closure
   (ids (list-of symbol?))
   (body (list-of expression?))
   (env environment?)))


(define-datatype target target?
  ; Añade el flag 'mutable?' al 'direct-target'
  (direct-target (expval expval?) (mutable? boolean?))
  (indirect-target (ref ref-to-direct-target?)))

(define-datatype reference reference?
  (a-ref (position integer?) (vec vector?)))

(define-datatype return-value return-value?
  (a-return-value (val expval?)))

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
              (vector-set! vec pos (direct-target (closure ids body env) #f)))
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
    (or (number? x) 
        (string? x) 
        (boolean? x)
        (special-val? x)
        (procval? x))))

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
  (lambda (ref expval) ; ref=llave, expval=nuevo valor (ej. 10)
    (let* (
           ; 1. Resuelve la indirección para encontrar la llave final
           (final-ref (cases target (primitive-deref ref)
                        (direct-target (v mut?) ref)
                        (indirect-target (ref1) ref1)))
           
           ; 2. Obtiene el casillero (target) final
           ; --- ¡VARIABLE RENOMBRADA! ---
           (target-val (primitive-deref final-ref)))
      
      ; 3. ¡EL CHEQUEO DE SEGURIDAD!
      ; --- ¡ARREGLADO! ---
      ;      (cases TIPO VARIABLE ...)
      (cases target target-val
        (direct-target (old-val mutable?)
          (if (eq? mutable? #t)
              ; 4a. SÍ ES MUTABLE:
              (primitive-setref! final-ref (direct-target expval #t))
              
              ; 4b. NO ES MUTABLE:
              (eopl:error 'setref! "Asignación inválida: No se puede modificar una constante.")))
        
        (indirect-target (r) (eopl:error 'setref! "Error de referencia inesperado"))
        ))))

(define primitive-setref!
  (lambda (ref val)
    (cases reference ref
      (a-ref (pos vec)
             (vector-set! vec pos val)))))

;***********************************************************************************************************************
;************************************    Funciones auxiliares para ambiente    *****************************************
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
;************************************    Funciones auxiliares para interpretador    ************************************
;***********************************************************************************************************************

(define eval-primapp-exp-rands
  (lambda (rands env)
    (map (lambda (x) (eval-expression x env)) rands)))


; --- Función auxiliar para desempaquetar números ---
; Toma un 'expval' y devuelve un número crudo, o lanza un error.
(define ensure-number
  (lambda (val prim-name)
    (if (number? val)
        val
        (eopl:error 'apply-primitive "Error en ~s: se esperaba un número, pero se recibió ~s"
                    prim-name val))))

; ---  apply-primitive---
(define apply-primitive
  (lambda (prim args)
    (cases primitive prim
      
      (add-prim ()
        (if (= (length args) 2)
            (let ((n1 (ensure-number (car args) '+))
                  (n2 (ensure-number (cadr args) '+)))
              (+ n1 n2))
            (eopl:error 'apply-primitive "Error en +: se esperaban 2 argumentos, se recibieron ~s" (length args))))
            
      (substract-prim ()
        (if (= (length args) 2)
            (let ((n1 (ensure-number (car args) '-))
                  (n2 (ensure-number (cadr args) '-)))
              (- n1 n2))
            (eopl:error 'apply-primitive "Error en -: se esperaban 2 argumentos, se recibieron ~s" (length args))))

      (mult-prim ()
        (if (= (length args) 2)
            (let ((n1 (ensure-number (car args) '*))
                  (n2 (ensure-number (cadr args) '*)))
              (* n1 n2))
            (eopl:error 'apply-primitive "Error en *: se esperaban 2 argumentos, se recibieron ~s" (length args))))
      
      ; --- ¡CASO AÑADIDO 1: div-prim! ---
      (div-prim ()
        (if (= (length args) 2)
            (let ((n1 (ensure-number (car args) '/))
                  (n2 (ensure-number (cadr args) '/)))
              (if (zero? n2) ; Chequeo de división por cero
                  (eopl:error 'apply-primitive "Error en /: División por cero.")
                  (/ n1 n2)))
            (eopl:error 'apply-primitive "Error en /: se esperaban 2 argumentos, se recibieron ~s" (length args))))
            
      ; --- ¡CASO AÑADIDO 2: mod-prim! ---
      (mod-prim ()
        (if (= (length args) 2)
            (let ((n1 (ensure-number (car args) '%))
                  (n2 (ensure-number (cadr args) '%)))
              (if (zero? n2) ; Chequeo de división por cero
                  (eopl:error 'apply-primitive "Error en %: División por cero.")
                  (modulo n1 n2)))
            (eopl:error 'apply-primitive "Error en %: se esperaban 2 argumentos, se recibieron ~s" (length args))))
            
      (incr-prim ()
        (if (= (length args) 1)
            (let ((n1 (ensure-number (car args) 'add1)))
              (+ n1 1))
            (eopl:error 'apply-primitive "Error en add1: se esperaba 1 argumento, se recibió ~s" (length args))))
            
      (decr-prim ()
        (if (= (length args) 1)
            (let ((n1 (ensure-number (car args) 'sub1)))
              (- n1 1))
            (eopl:error 'apply-primitive "Error en sub1: se esperaba 1 argumento, se recibió ~s" (length args))))
      
      )))


; --- Especialista para 'if-exp' (Tu lógica recursiva) ---
(define eval-if-exp
  (lambda (all-tests all-bodies else-body env)
    
    ; 1. "si no quedan condiciones, haga eval sequence de las lineas del else"
    (if (null? all-tests)
        (eval-sequence else-body env)
        
        ; 2. "si quedan condiciones..."
        (let ((test1 (car all-tests))
              (body1 (car all-bodies)))
          
          ; 3. "...verifique si es verdadera"
          (if (true-value? (eval-expression test1 env))
              
              ; 4. "si lo es, mande a evalsquence las lineas de ejecucion"
              (eval-sequence body1 env)
              
              ; 5. "si no es verdadera, haga recursion con el cdr..."
              (eval-if-exp (cdr all-tests) (cdr all-bodies) else-body env)
              )))))

; --- Ayudante para "Truthiness" ---
; Define qué valores (expvals) se consideran FALSOS.
(define false-value?
  (lambda (val)
    (cond
      ; 1. El booleano #f de Racket (de un predicado como < o ==)
      ((boolean? val) (not val))
      
      ; 2. Tu (null-val) (de la expresión 'null')
      ((and (special-val? val)(null-val? val)) #t)
      
      ; 3. Tu (void-val) (del 'print' o fin de secuencia)
      ((and (special-val? val) (void-val? val)) #t)
      
      ; 4. El número 0
      ((and (number? val) (zero? val)) #t)
      
      
      ; 5. ¡Todo lo demás se considera Verdadero!
      (else #f)
      )))

; --- Función de Condición ---
; Devuelve #t si un valor es "Truthy".
(define true-value?
  (lambda (val)
    (not (false-value? val))))

(define (apply-predicate prim val1 val2)
  (cases pred-prim prim
    
    ; --- Casos Numéricos (¡Usan ensure-number!) ---
    (less-than-prim () (< (ensure-number val1 '<) (ensure-number val2 '<)))
    (greater-than-prim () (> (ensure-number val1 '>) (ensure-number val2 '>)))
    (less-equal-prim () (<= (ensure-number val1 '<=) (ensure-number val2 '<=)))
    (greater-equal-prim () (>= (ensure-number val1 '>=) (ensure-number val2 '>=)))
    
    ; --- Casos de Igualdad (Pueden comparar cualquier tipo) ---
    (equal-prim () (equal? val1 val2))
    (not-equal-prim () (not (equal? val1 val2)))
    ))


; --- Ayudante para 'and' y 'or' (con cortocircuito) ---
(define (apply-bool-bin-op op exp1 exp2 env)
  (cases oper-bin-bool op
    
    (and-prim ()
      ; 1. Evalúa el primer operando
      (let ((val1 (eval-expression exp1 env)))
        ; 2. Si el primero es FALSO, devuelve ese valor falso y NO evalúa el segundo
        (if (true-value? val1)
            (eval-expression exp2 env) ; Si es verdadero, devuelve el resultado del segundo
            val1))) ; Cortocircuito: devuelve el valor "falsy"
            
    (or-prim ()
      ; 1. Evalúa el primer operando
      (let ((val1 (eval-expression exp1 env)))
        ; 2. Si el primero es VERDADERO, devuelve ese valor verdadero y NO evalúa el segundo
        (if (true-value? val1)
            val1 ; Cortocircuito: devuelve el valor "truthy"
            (eval-expression exp2 env)))) ; Si es falso, devuelve el resultado del segundo
    ))

; --- Ayudante para 'not' ---
(define (apply-bool-un-op op exp1 env)
  (cases oper-un-bool op
    (not-prim ()
      ; 'not' siempre devuelve un booleano estricto
      (if (true-value? (eval-expression exp1 env))
          #f
          #t))
    ))


(define eval-rands
  (lambda (rands env)
    (map (lambda (x) (eval-rand x env)) rands)))

(define eval-rand
  (lambda (rand env)
    (cases expression rand
      
      ; --- CASO 1: El argumento es un identificador (ej. f(x)) ---
      (identifier-exp (id suffix)
        
        ; --- ¡AQUÍ ESTÁ EL CAMBIO! ---
        ; Usamos 'cases' para determinar el tipo de sufijo
        (cases identifier-suffix suffix
          
          ; --- 1a. Es 'x' (simple). Pasa por REFERENCIA ---
          (val-var-suffix ()
            ; --- Lógica de Paso-por-Referencia ---
            (indirect-target
             (let ((ref (apply-env-ref env id)))
               ; Resuelve la cadena para encontrar la referencia FINAL
               (cases target (primitive-deref ref)
                 (direct-target (expval mutable?) ref)
                 (indirect-target (ref1) ref1)))))
          
          ; --- 1b. Es 'x(1)' o 'x=5' (complejo). Pasa por VALOR ---
          (else
           ; 'rand' es la expresión COMPLETA (ej. 'x(1)')
           (let ((val (eval-expression rand env)))
             ; --- Lógica de Paso-por-Valor ---
             (direct-target val #t)))
          
          )) ; fin cases identifier-suffix
      
      ; --- CASO 2: Es cualquier otra cosa (ej. f(5) o f(x+2)) ---
      (else
       (let ((val (eval-expression rand env)))
         ; --- Lógica de Paso-por-Valor ---
         (direct-target val #t))) ; #t = parámetro mutable local
      
      ))) ; fin cases expression
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

(define eval-sequence
  (lambda (exps env)
    (if (null? exps)
        (void-val)
        (let ((exp1 (car exps)))
          (cases expression exp1
            
            ; --- CASO VAR (Sin cambios) ---
            (var-decl-exp (ids-list exps-list)
              (let ((new-env (eval-declarations ids-list exps-list env #t)))
                (eval-sequence (cdr exps) new-env)))
            
            ; --- CASO CONST (Sin cambios) ---
            (const-decl-exp (ids-list exps-list)
              (let ((new-env (eval-declarations ids-list exps-list env #f)))
                (eval-sequence (cdr exps) new-env)))

            ; --- CASO FUNCION (Recursiva o normal) ---
            (func-exp (proc-name id-list body-exps)
            (let ((new-env 
                    (extend-env-recursively
                     (list proc-name)
                     (list id-list)
                     (list body-exps) ; <-- Pasa el 'body-exps' (lista) directo
                     env)))
              (eval-sequence (cdr exps) new-env)))
          
          (else
           ; --- ¡LÓGICA DE PROPAGACIÓN DE 'RETURN'! ---
           (let ((val1 (eval-expression exp1 env)))
             
             ; 1. ¿Es un paquete de retorno?
             (if (return-value? val1)
                 val1 ; <-- ¡ALTO! Pasa el paquete hacia arriba
                 
                 ; 2. No es un retorno, continúa normal
                 (if (null? (cdr exps))
                     val1
                     (eval-sequence (cdr exps) env)))))
            


            )))))

; Esta función procesa DOS listas paralelas (ids y exps)
(define eval-declarations
  (lambda (ids-list exps-list env is-mutable?)
    
    (let loop ((ids ids-list) 
               (exps exps-list) 
               (current-env env))
      
      (if (null? ids)
          current-env ; Devuelve el ambiente final
          
          (let ((id (car ids))
                (exp (car exps)))
            
            ; --- ¡LÓGICA "TONTA" (SIMPLIFICADA)! ---
            ; Ya NO hay un 'cases' aquí.
            (let ((val (eval-expression exp current-env)))
              (let ((next-env 
                     (extend-env
                      (list id)
                      (list (direct-target val is-mutable?)) 
                      current-env)))
                (loop (cdr ids) (cdr exps) next-env)))
            )))))



(define eval-expression
  (lambda (exp env)
   (cases expression exp
      (environment-exp () env)
      (lit-exp (datum) datum)
      (text-lit (text) text)
      (true-exp () #t)
      (false-exp () #f)
      (null-exp () null-val)
      (print-exp (printable)
                 (begin
                   (display (eval-expression printable env))
                   (newline)))
      (identifier-exp (id suffix)
                      (eval-identifier-suffix id suffix env))
      (primapp-exp (prim rands)
                   (let ((args (eval-primapp-exp-rands rands env)))
                     (apply-primitive prim args)))
     
     (if-exp (test1 then-body elif-tests elif-bodies else-body)
        (let ((all-tests (cons test1 elif-tests))
              
              ; 2. Crea la lista de TODOS los cuerpos
              (all-bodies (cons then-body elif-bodies)))
          
          ; 3. Llama al nuevo especialista con las listas completas
          (eval-if-exp all-tests all-bodies else-body env)
          ))

     (pred-bool-exp (prim exp1 exp2)
      (apply-predicate prim 
                       (eval-expression exp1 env) 
                       (eval-expression exp2 env)))
                       
    (bin-bool-exp (op exp1 exp2)
      (apply-bool-bin-op op exp1 exp2 env))

    (un-bool-exp (op exp1)
      (apply-bool-un-op op exp1 env))

     (lambda-exp (id-list body-exp)
          ; 2. ¡Crea una clausura no recursiva porque es una funcion que no se guarda en una variable entonces es no recursiva
          (closure id-list (list body-exp) env))

     (return-exp (opt-val)
                 (eval-return-exp opt-val env))

     (else 1))))

(define eval-return-exp
  (lambda (opt-AST env)
    (cases opt-return-val opt-AST
        
        ; 2a. Si era 'return 5;'
        (with-return-val (exp1)
          (let ((val (eval-expression exp1 env)))
            (a-return-value val))) ; <-- Envuelve el valor
            
        ; 2b. Si era 'return;'
        (no-return-val ()
          (a-return-value (void-val))) ; <-- Envuelve 'void'
        
        )))



(define (apply-procedure proc arg-targets)
  (cases procval proc
    (closure (ids body saved-env)
      (if (= (length ids) (length arg-targets))
          (let ((new-env (extend-env ids arg-targets saved-env)))
            
            ; 1. Llama a eval-sequence (que podría devolver un paquete)
            (let ((result (eval-sequence body new-env)))
              
              ; 2. ¡Atrapa el paquete!
              (if (return-value? result)
                  ; 3a. Desenuelve el valor
                  (cases return-value result
                    (a-return-value (val) val))
                  ; 3b. No hubo 'return', devuelve el valor de la última exp
                  result 
                  )))
          (eopl:error 'apply-procedure "Error de aridad: la función esperaba ~s args, recibió ~s"
                        (length ids) (length arg-targets))))))



(define eval-identifier-suffix
  (lambda (id suffix env)
    (cases identifier-suffix suffix
      (val-var-suffix () (apply-env env id))
      
      (assign-suffix (exp1)
        (let ((val (eval-expression exp1 env)))
          ; 1. Obtiene la referencia (la llave)
          (let ((ref (apply-env-ref env id)))
            ; 2. Llama a setref! (el guardia de seguridad)
            (setref! ref val))
            val)) ; La asignación devuelve el valor asignado

      ; --- Caso 3: Llamar a una función ---
      (call-suffix (rands)
        ; 1. Busca la clausura
        (let ((proc (apply-env env id))) 
          (if (procval? proc)
              ; 2. ¡Llama al NUEVO ayudante híbrido!
              (let ((arg-targets (eval-rands rands env)))
                ; 3. Pasa esos 'targets' a apply-procedure
                (apply-procedure proc arg-targets))
              (eopl:error 'eval-identifier-suffix 
                "Intento de llamar a algo que no es una función: ~s" id))))
      (else 'faltan_casos)
      )))


;;--------------------------------- Ejecutamos el interpretador --------------------------------------------------------

(interpretador)



;***********************************************************************************************************************
;************************************    Ejecución del programa mediante un txt    *************************************
;***********************************************************************************************************************

(define file
  (file->string "program.txt"))

(define AST-program-txt
  (scan&parse file))

(eval-program AST-program-txt)