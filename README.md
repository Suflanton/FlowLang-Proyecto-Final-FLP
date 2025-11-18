
```markdown
# FlowLang - Intérprete con Prototipos

Intérprete desarrollado en Racket usando EOPL que implementa un lenguaje imperativo con tipos de datos avanzados, prototipos y características funcionales.

## Valores Soportados

El lenguaje soporta 10 tipos de valores denotados:
- Enteros: `42`, `-15`
- Flotantes: `3.14`, `-2.5`
- Números Complejos: `complex(3, 4)` representa 3 + 4i
- Cadenas: `"Hola mundo"`
- Booleanos: `true`, `false`
- Null: `null`
- Funciones: Clausuras con soporte recursivo
- Listas: `[1, 2, 3]`
- Diccionarios: `{nombre: "Ana", edad: 25}`
- Prototipos: Objetos con herencia prototípica

## Sintaxis General

### Comentarios
# Comentario de línea
```

### Declaraciones de Variables
```racket
var x = 10, y = 20, z = 30;
const PI = 3.14159;
```

Las declaraciones terminan con `;`. Las constantes no pueden ser modificadas.

### Funciones

Función con nombre (recursiva):
```racket
func factorial(n) {
    if (<(n, 2)) then {
        return 1;
    } else {
        return *(n, factorial(-(n, 1)));
    }
}
```

Función anónima (lambda):
```racket
var suma = lambda(a, b) { 
    return +(a, b);
};
```

Las lambdas pueden contener múltiples expresiones. El return puede omitirse y retorna la última expresión evaluada.

### Estructuras de Control

Condicional if-elif-else:
```racket
if (>(edad, 18)) then {
    print("Mayor de edad")
} elif (==(edad, 18)) then {
    print("Exactamente 18")
} else {
    print("Menor de edad")
}
```

Bucle while:
```racket
var i = 0;
while (<(i, 10)) do
    print(i)
    i = +(i, 1);
done
```

Bucle for:
```racket
var lista = [1, 2, 3, 4, 5];
for elemento in lista do
    print(elemento)
done
```

Switch:
```racket
switch (opcion) {
    case 1: { print("Opción 1") }
    case 2: { print("Opción 2") }
    default: { print("Otra") }
}
```

## Operadores y Primitivas

### Aritméticas
```racket
+(a, b)      # Suma
-(a, b)      # Resta
*(a, b)      # Multiplicación
/(a, b)      # División
%(a, b)      # Módulo
add1(n)      # Incremento
sub1(n)      # Decremento
```

### Relacionales
```racket
<(a, b), >(a, b), <=(a, b), >=(a, b)
==(a, b)     # Igual
<>(a, b)     # Diferente
```

### Booleanas
```racket
and(a, b)    # Conjunción 
or(a, b)     # Disyunción 
not(a)       # Negación
```

## Listas

Crear listas:
```racket
var numeros = [1, 2, 3, 4, 5];
var vacia = vacio();
```

Operaciones:
```racket
cabeza(lista)           # Primer elemento
cola(lista)             # Resto de la lista
append(lst1, lst2)      # Concatenar listas
rlist(lista, indice)    # Acceso por índice
clist(lista, idx, val)  # Modificar elemento (crea nueva lista)
vacio?(lista)           # Verifica si está vacía
lista?(valor)           # Verifica si es lista
```

## Diccionarios

Los diccionarios son colecciones de pares clave-valor. Las claves deben ser identificadores (sin comillas).

Crear diccionarios:
```racket
var persona = {nombre: "Ana", edad: 25, ciudad: "Bogotá"};
var vacio = crear-diccionario();
```

Operaciones:
```racket
ref-diccionario(dict, clave)        # Obtener valor
set-diccionario(dict, clave, valor) # Establecer valor (devuelve nuevo diccionario)
claves(dict)                        # Lista de claves
valores(dict)                       # Lista de valores
diccionario?(valor)                 # Verifica si es diccionario
```

Ejemplo:
```racket
var persona = {nombre: "Juan", edad: 30};
var edad = ref-diccionario(persona, edad);
var persona2 = set-diccionario(persona, edad, 31);
print(persona)   # {nombre: Juan, edad: 30} - sin cambios
print(persona2)  # {nombre: Juan, edad: 31} - nuevo diccionario
```

## Prototipos (POO)

Los prototipos permiten programación orientada a objetos mediante herencia prototípica.

Definir prototipo:
```racket
prototype Vehiculo = {
    marca: "Sin marca",
    modelo: "Sin modelo",
    encender: lambda() { print("Vehículo encendido") }
};
```

Clonar prototipo:
```racket
var carro = clone(Vehiculo);
```

Acceder a propiedades:
```racket
var marca = access carro.marca;
```

Modificar propiedades:
```racket
var carro2 = access carro.marca = "Toyota";
```

Llamar a métodos con this:
```racket
prototype Persona = {
    nombre: "Ana",
    saludar: lambda() {
        print(concat("Hola, soy ", access this.nombre))
    }
};

var p = clone(Persona);
access p.saludar()  # Imprime: Hola, soy Ana
```

Cuando llamas a un método con `access objeto.metodo()`, la palabra clave `this` dentro del método apunta automáticamente al objeto.

## Números Complejos

Crear y operar con números complejos:
```racket
var c1 = complex(3, 4);     # 3 + 4i
var c2 = complex(1, -2);    # 1 - 2i

var suma = sum-complex(c1, c2);
var resta = sub-complex(c1, c2);
var producto = mult-complex(c1, c2);
var division = div-complex(c1, c2);

print(c1)        # (3 + 4i)
print(producto)  # (11 - 2i)
```

## Cadenas

Operaciones sobre cadenas:
```racket
var str1 = "Hola";
var str2 = " Mundo";

var longitud = length(str1);           # 4
var concatenado = concat(str1, str2);  # "Hola Mundo"
```

Nota: No puedes usar `+` para concatenar strings. Debes usar `concat()`.

## Paso de Parámetros

El lenguaje implementa paso híbrido:

Por referencia (se modifican):
- Identificadores simples de listas, diccionarios y prototipos
```racket
func modificar(lista) {
    var nueva = clist(lista, 0, 999);
    lista = nueva;  # Modifica el original
    return None;
}

var L = [1, 2, 3];
modificar(L);
print(L)  # [999, 2, 3] - fue modificado
```

Por valor (no se modifican):
- Números, strings, booleanos
- Expresiones literales
```racket
func cambiar(n) {
    n = 100;
    return None;
}

var x = 5;
cambiar(x);
print(x)  # 5 - sin cambios
```

## Características Especiales

### Return
```racket
func ejemplo(n) {
    if (==(n, 0)) then {
        return 0;
    } else {
        return +(n, 1);
    }
}

# Return sin valor
func vacio() {
    print("Ejecutando")
    return None;  # Retorna void
}
```

### This en métodos
```racket
prototype Contador = {
    cuenta: 0,
    incrementar: lambda() {
        var nueva = +(access this.cuenta, 1);
        access this.cuenta = nueva;
        return this;
    }
};

var c = clone(Contador);
access c.incrementar()
var valor = access c.cuenta;
print(valor)  # 1
```

Tienes razón en cuestionarlo. Déjame verificar cómo funcionan realmente los diccionarios y prototipos con el paso por referencia:

[2 tools called]

Tienes razón, esa sección está INCORRECTA. Los diccionarios son inmutables y cuando se pasan por referencia, reasignar el parámetro NO modifica el original. Aquí está la versión corregida:

```markdown
### Diccionarios (Inmutables)

Los diccionarios siempre crean nuevas copias al modificarse:

```racket
var d1 = {x: 10};
var d2 = set-diccionario(d1, x, 20);
print(d1)  # {x: 10} - original sin cambios
print(d2)  # {x: 20} - nuevo diccionario
```

Incluso cuando se pasan a funciones, reasignar el parámetro NO afecta el original:

```racket
func intentarModificar(dict) {
    var nuevo = set-diccionario(dict, x, 100);
    dict = nuevo;  # Solo cambia la variable local
    return None;
}

var miDict = {x: 5};
intentarModificar(miDict);
print(miDict)  # {x: 5} - SIN cambios
```

Para modificar realmente, debes retornar y reasignar:

```racket
func modificarDict(dict) {
    return set-diccionario(dict, x, 100);
}

var miDict = {x: 5};
miDict = modificarDict(miDict);  # Reasignar el resultado
print(miDict)  # {x: 100} - ahora sí cambió
```

### Prototipos (Mutables cuando se pasan por referencia)

Los prototipos usan vectores internos que son mutables. Cuando se pasan por referencia a funciones y usas `access obj.prop = val`, el objeto original se modifica:

```racket
func cambiarMarca(vehiculo) {
    access vehiculo.marca = "ModificadaDentro";
    return None;
}

prototype Vehiculo = {marca: "Original"};
var carro = clone(Vehiculo);

print(carro)  # {prototype: marca: Original}
cambiarMarca(carro);
print(carro)  # {prototype: marca: ModificadaDentro} - SÍ cambió
```

Sin embargo, si reasignas el parámetro completo, NO afecta el original:

```racket
func intentarReemplazar(vehiculo) {
    prototype Nuevo = {marca: "Nuevo"};
    vehiculo = Nuevo;  # Solo cambia la variable local
    return None;
}

var carro = clone(Vehiculo);
intentarReemplazar(carro);
print(carro)  # Sigue siendo el original - sin cambios
```
```

¿Así está mejor?

## Ejecución

El intérprete se ejecuta desde Racket:
```bash
racket prueba.rkt
```

Esto abre un REPL interactivo donde puedes escribir expresiones:
```racket
--> var x = 10;
--> print(x)
10
--> end
```

O ejecuta el código desde el archivo `program.txt` automáticamente al cargar el intérprete.

## Ejemplos Rápidos

Factorial recursivo:
```racket
func fact(n) {
    if (<(n, 2)) then {
        return 1;
    } else {
        return *(n, fact(-(n, 1)));
    }
}

print(fact(5))  # 120
end
```

Map funcional:
```racket
func map(L, F) {
    if (vacio?(L)) then {
        return vacio;
    } else {
        var primero = F(cabeza(L));
        var resto = map(cola(L), F);
        return append([primero], resto);
    }
}

func doble(n) { return *(n, 2); }

var lista = [1, 2, 3, 4];
var resultado = map(lista, doble);
print(resultado)  # [2, 4, 6, 8]
end
```

Prototipos con herencia:
```racket
prototype Vehiculo = {
    marca: "Generic",
    encender: lambda() { 
        print(concat("Encendiendo ", access this.marca)) 
    }
};

var carro = clone(Vehiculo);
var carro2 = access carro.marca = "Toyota";
access carro2.encender()  # Encendiendo Toyota
end
```

## Limitaciones

- Las claves de diccionarios deben ser identificadores sin comillas: `{nombre: "Ana"}` no `{"nombre": "Ana"}`
- No hay operador `+` para concatenar strings, usar `concat(str1, str2)`
- El acceso a propiedades requiere `access`: `access objeto.propiedad`
- Los métodos con `this` solo funcionan cuando se llaman con `access objeto.metodo()`
- Los prototipos son inmutables (cada modificación crea una copia), excepto cuando se pasan por referencia a funciones

## Autores
- Maria Juliana Saavedra
- Libardo Alejandro Quintero
- Juan David Rincón

```

