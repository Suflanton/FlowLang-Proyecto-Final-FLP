Aquí tienes un `README.md` completo y detallado para el repositorio de tu interpretador, basado en todo el código Racket, las especificaciones de la gramática y los programas de ejemplo que has proporcionado.

-----

# 🌊 FlowLang - Interpretador

**"Deja que el código fluya."**

Este repositorio contiene la implementación de un interpretador para **FlowLang**, un lenguaje de programación dinámico, de propósito general y basado en prototipos. El interpretador está construido desde cero en Racket utilizando la librería `#lang eopl`.

Este proyecto es el resultado del curso **Fundamentos de Lenguajes de Programación**.

-----

## ✨ Características Principales

  * **Tipado Dinámico:** Las variables no tienen un tipo fijo y pueden cambiar durante la ejecución.
  * **Basado en Prototipos:** Utiliza un modelo de objetos similar a JavaScript (pre-ES6), basado en `prototype`, `clone` y `this`, en lugar de un sistema de clases.
  * **Paso de Parámetros Híbrido:**
      * **Por Valor:** Para tipos primitivos (Números, Cadenas, Booleanos, Nulos).
      * **Por Referencia:** Para estructuras mutables (Listas, Diccionarios y Prototipos).
  * **Funciones de Primera Clase:** Las funciones (`func`) y lambdas (`lambda`) pueden ser asignadas a variables y pasadas como argumentos.
  * **Gestión de Entornos:** Mantiene un entorno mutable para el estado del programa.
  * **Estructuras de Datos Nativas:** Soporte para Listas (`[...]`), Diccionarios (`{...}`) y Números Complejos (`complex(...)`).
  * **Conjunto Completo de Primitivas:** Incluye operaciones aritméticas, booleanas, y de manipulación para listas, diccionarios y cadenas.

-----

## 📦 Tipos de Datos

FlowLang maneja un conjunto de valores expresados que se dividen en dos categorías:

### Primitivos (Inmutables)

  * **Integer/Float:** `10`, `3.14`, `-5`
  * **Boolean:** `true`, `false`
  * **String:** `"Hola Mundo"`
  * **Complex:** `complex(5, 3)` (Representa `5 + 3i`)
  * **Null:** `null` (Representa la ausencia de valor o el retorno de una función sin `return`).

### Estructuras (Mutables)

  * **List:** `[1, "hola", true]`
  * **Dictionary:** `{ nombre: "Juan", edad: 25 }`
  * **Prototype:** `prototype MiProto = { ... };`
  * **Function:** `func miFuncion(a) { ... }`

-----

## 🔗 Variables, Ámbito y Asignación

### `var` y `const`

El lenguaje usa `var` para variables mutables y `const` para variables inmutables. Ambas declaraciones requieren un punto y coma (`;`) al final.

```flow
var x = 10;
const PI = 3.14159;

x = 20;       # Válido
print(x);     # Imprime 20

PI = 3.0;     # Inválido: Lanza un error de asignación
```

Las asignaciones a variables ya declaradas (`x = 20`) no llevan punto y coma.

### Paso por Valor vs. Referencia

Este es un concepto central en FlowLang.

  * **Paso por Valor:** Ocurre con tipos primitivos. Al pasar un número o una cadena a una función, se pasa una *copia*. Si la función modifica el parámetro, la variable original fuera de la función no se ve afectada.

    ```flow
    func testValor(n) {
        n = 100; # Modifica la copia local
        return null
    }

    var y = 50;
    testValor(y);
    print(y); # Imprime 50, no 100
    ```

  * **Paso por Referencia:** Ocurre con Listas, Diccionarios y Prototipos. Al pasar un objeto, se pasa una *referencia* al objeto original en memoria. Las modificaciones al *contenido* del objeto dentro de la función se reflejan fuera de ella. La forma más clara de ver esto es con `this` en prototipos.

    ```flow
    prototype Auto = {
        marca: "N/A",
        setMarca: lambda(m) {
            access this.marca = m # 'this' es una referencia al objeto original
            return null
        }
    };

    var miAuto = clone(Auto);
    access miAuto.setMarca("Honda"); # Pasa la referencia de miAuto a 'this'
    print(miAuto); # Imprime {prototype: marca: "Honda", ...}
    ```

-----

## 🔄 Estructuras de Control e Iteración

### `if / elif / else`

Permite la ejecución condicional. El bloque `then` es obligatorio. `elif` y `else` son opcionales.

```flow
func factorial(n) {
    if (<(n, 0)) then {
        return 0
    }
    elif (==(n, 0)) then {
        return 1
    }
    else {
        return *(n, factorial(sub1(n)))
    }
}
```

### `switch`

Evalúa una expresión y la compara con múltiples casos. Requiere un bloque `default`.

```flow
switch (dia) {
    case 1: { print("Lunes") }
    case 2: { print("Martes") }
    default: { print("Otro dia") }
}
```

### `while`

Ejecuta un bloque de código (`do ... done`) mientras una condición sea `true`.

```flow
var i = 0;
while <(i, 5) do
    print(i);
    i = add1(i);
done
```

### `for`

Itera sobre los elementos de una lista.

```flow
var miLista = [10, 20, 30];
for elemento in miLista do
    print(elemento);
done
```

-----

## 🧬 Modelo de Prototipos (OOP)

FlowLang no usa clases. La herencia y el comportamiento se logran clonando objetos existentes (prototipos).

### 1\. `prototype` (Declaración)

Define un objeto base. Esta declaración debe terminar en punto y coma (`;`).

```flow
prototype Vehiculo = {
    marca: "Sin marca",
    getMarca: lambda() {
        return access this.marca
    }
};
```

### 2\. `clone` (Herencia)

Crea un nuevo objeto que hereda las propiedades del prototipo padre.

```flow
var miAuto = clone(Vehiculo);
```

### 3\. `access` (Interacción)

Es la palabra clave universal para interactuar con las propiedades de un prototipo.

  * **Obtener propiedad:** `access miAuto.marca`
  * **Asignar propiedad:** `access miAuto.marca = "Toyota"`
  * **Llamar método:** `access miAuto.getMarca()`

### 4\. `this` (Contexto)

Dentro de una función `lambda` en un prototipo, `this` se refiere al objeto que *recibió* la llamada al método. Esto permite que los métodos operen sobre el estado de la instancia específica.

```flow
prototype Contador = {
    valor: 0,
    incrementar: lambda() {
        # 'this' se refiere a 'c1' o 'c2'
        access this.valor = add1(access this.valor);
        return null
    }
};

var c1 = clone(Contador);
var c2 = clone(Contador);

access c1.incrementar();
access c1.incrementar();

print(access c1.valor); # Imprime 2
print(access c2.valor); # Imprime 0
```

-----

## 🛠️ Primitivas (Funciones Nativas)

El lenguaje incluye un amplio conjunto de primitivas.

| Categoría | Primitiva | Uso |
| :--- | :--- | :--- |
| **Aritmética** | `+`, `-`, `*`, `/`, `%` | `+(10, 5)` |
| | `add1`, `sub1` | `add1(10)` |
| **Complejos** | `complex` | `complex(3, 4)` (Crea `3+4i`) |
| | `sum-complex` | `sum-complex(c1, c2)` |
| | `sub-complex` | `sub-complex(c1, c2)` |
| | `mult-complex` | `mult-complex(c1, c2)` |
| | `div-complex` | `div-complex(c1, c2)` |
| **Booleanas** | `<`, `>`, `<=`, `>=`, `==`, `<>` | `<(10, 5)` |
| | `and`, `or`, `not` | `and(true, false)` |
| **Cadenas** | `length` | `length("hola")` (Devuelve 4) |
| | `concat` | `concat("a", "b")` (Devuelve "ab") |
| **Listas** | `vacio` | `vacio` (Constante `[]`) |
| | `vacio?` | `vacio?([1])` (Devuelve `false`) |
| | `lista?` | `lista?("a")` (Devuelve `false`) |
| | `cabeza` | `cabeza([1, 2])` (Devuelve `1`) |
| | `cola` | `cola([1, 2])` (Devuelve `[2]`) |
| | `append` | `append([1], [2])` (Devuelve `[1, 2]`) |
| | `rlist` | `rlist([5, 6, 7], 1)` (Devuelve `6`) |
| | `clist` | `clist([5, 6, 7], 1, 9)` (Devuelve `[5, 9, 7]`) |
| **Diccionarios** | `crear-diccionario` | `crear-diccionario()` (Devuelve `{}`) |
| | `diccionario?` | `diccionario?({})` (Devuelve `true`) |
| | `ref-diccionario` | `ref-diccionario({a: 1}, a)` (Devuelve `1`) |
| | `set-diccionario` | `set-diccionario({a: 1}, a, 2)` |
| | `claves` | `claves({a: 1, b: 2})` (Devuelve `[a, b]`) |
| | `valores` | `valores({a: 1, b: 2})` (Devuelve `[1, 2]`) |
| **I/O** | `print` | `print("Hola")` |

-----

## 📜 Gramática y Sintaxis

La sintaxis de FlowLang está diseñada para ser clara y declarativa.

| Construcción | Ejemplo de Sintaxis Concreta |
| :--- | :--- |
| **Declaración `var`** | `var x = 10, y = "hola";` |
| **Declaración `const`** | `const Z = [1, 2, 3];` |
| **Asignación** | `x = 20` |
| **Declaración `func`** | `func miSuma(a, b) { return +(a, b) }` |
| **Declaración `lambda`** | `lambda(x) { return add1(x) }` |
| **Declaración `prototype`**| `prototype MiProto = { a: 1 };` |
| **Llamada a función** | `miSuma(5, 3)` |
| **Primitiva** | `+(5, 3)` |
| **Acceso Prototipo** | `access miProto.a` |
| **Asignación Prototipo** | `access miProto.a = 2` |
| **Llamada Método** | `access miProto.miMetodo(1)` |

-----

## 🚀 Cómo Ejecutar

Hay dos formas de ejecutar código FlowLang:

### 1\. REPL (Modo Interactivo)

Simplemente ejecuta el archivo `.rkt` principal en DrRacket. Se iniciará el REPL `(interpretador)`:

```racket
; Carga e inicia el REPL
(interpretador)
```

```
--> var x = 10;
--> print(x)
10
--> 
```

### 2\. Ejecutar un Archivo `.txt`

El intérprete está configurado para leer y ejecutar un archivo llamado `program.txt` ubicado en el mismo directorio.

```racket
; Lee el archivo
(define file
  (file->string "program.txt"))

; Lo convierte en un Árbol de Sintaxis Abstracta (AST)
(define AST-program-txt
  (scan&parse file))

; Evalúa el programa completo
(eval-program AST-program-txt)
```

Simplemente escribe tu código FlowLang en `program.txt` y ejecuta el archivo Racket. Los resultados se imprimirán en la consola.

-----

## 💡 Ejemplos de Código

### Ejemplo 1: Factorial Recursivo (con `if/elif/else`)

```flow
# PROGRAMA: REGISTRO DE FACTORIALES
 
# Función factorial recursiva
func factorial(n) {
    if (<(n, 0)) then {
        return 0
    }
    elif (==(n, 0)) then {
        return 1
    }
    elif (==(n, 1)) then {
        return 1
    }
    else {
        return *(n, factorial(sub1(n)))
    }
}
 
# Función que calcula factoriales de una lista
func calcularFactoriales(lista) {
    if (vacio?(lista)) then {
        return vacio
    }
    else {
        var primero = cabeza(lista);
        var resto = cola(lista);
        var factPrimero = factorial(primero);
        var factResto = calcularFactoriales(resto);
        return append([factPrimero], factResto)
    }
}
 
# PRUEBA 
var lista1 = [1, 2, 3, 4, 7];
var factoriales1 = calcularFactoriales(lista1);
var registro1 = {numeros: lista1, factoriales: factoriales1};
 
print("PRUEBA 1")
print(registro1)

# Salida: {numeros: [1, 2, 3, 4, 7], factoriales: [1, 2, 6, 24, 5040]}
end
```

### Ejemplo 2: Prototipos, Herencia y `this`

```flow
# PROGRAMA: SIMULACIÓN DE POO CON 'this' 
 
# Prototipo base VEHICULO
prototype Vehiculo = {
    marca: "Sin marca",
    modelo: "Sin modelo",
    
    setMarca: lambda(nuevaMarca) {
        access this.marca = nuevaMarca
        return this 
    },
    
    setModelo: lambda(nuevoModelo) {
        access this.modelo = nuevoModelo
        return this
    }
};
 
# Prototipo MOTO que hereda de VEHICULO
var Moto = clone(Vehiculo);
 
# Añadir propiedades y métodos específicos de Moto
Moto = access Moto.cilindrada = 0
 
Moto = access Moto.setCilindrada = lambda(nuevaCilindrada) {
    access this.cilindrada = nuevaCilindrada
    return this
}
 
# --- Creación de 2 MOTOS ---
 
# MOTO 1
var moto1 = clone(Moto);
print("--- MOTO 1 (ANTES) ---")
print(moto1) # Imprime valores por defecto
 
access moto1.setMarca("Honda")
access moto1.setModelo("CBR")
access moto1.setCilindrada(1000)
 
# MOTO 2
var moto2 = clone(Moto);
print("--- MOTO 2 (ANTES) ---")
print(moto2) # Imprime valores por defecto
 
access moto2.setMarca("Yamaha")
access moto2.setModelo("R6")
access moto2.setCilindrada(600)
 
 
# --- Verificación (DESPUÉS) ---
print("--- Verificando estado final ---")
 
print("MOTO 1 (Final)")
print(moto1) # {prototype: marca: "Honda", ...}
 
print("MOTO 2 (Final)")
print(moto2) # {prototype: marca: "Yamaha", ...}
 
end
```

### Ejemplo 3: Funciones como Ciudadanos de Primera Clase (`map`)

```flow
# -----------------------------------------------------------------
# 1. Función Auxiliar (La función "F" que map aplicará)
# -----------------------------------------------------------------
func incrementar(n) {
   return add1(n)
}
 
# -----------------------------------------------------------------
# 2. Implementación de la Función "map"
# -----------------------------------------------------------------
# map(L, F)
# L: La lista a procesar.
# F: La función unaria a aplicar a cada elemento de L.
 
func map(L, F) {
   
   # --- Caso Base ---
   if (vacio?(L)) then {
     return vacio
   } else {
     
     # --- Caso Recursivo ---
     
     # 1. Aplicamos la función F al primer elemento (la cabeza) de L.
     var cabeza-mapeada = F(cabeza(L));
     
     # 2. Llamamos recursivamente a 'map' sobre el resto de la lista (la cola).
     var cola-mapeada = map(cola(L), F);
     
     # 3. "Cons": Unimos la cabeza mapeada con la cola mapeada.
     var lista-cabeza = [ cabeza-mapeada ];
     
     return append(lista-cabeza, cola-mapeada)
   }
}
 
# -----------------------------------------------------------------
# 3. Demostración de Uso
# -----------------------------------------------------------------
 
# Creamos una lista de prueba.
var mi-lista = [10, 20, 30, 40];
 
# Llamamos a map, pasando nuestra lista y la función 'incrementar'.
# El resultado esperado es [11, 21, 31, 41]
var lista-resultado = map(mi-lista, incrementar);
 
# Imprimimos el resultado final en la consola.
print(lista-resultado)
 
end
```
