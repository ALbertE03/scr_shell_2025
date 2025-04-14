# Documentación Detallada del Proyecto de Shell

## Introducción
Este proyecto implementa una shell personalizada en Python, diseñada para ejecutar comandos, manejar redirecciones de entrada/salida, y soportar tuberías. El objetivo es proporcionar una experiencia de línea de comandos similar a las shells tradicionales, permitiendo a los usuarios interactuar con el sistema operativo de manera eficiente.

## Arquitectura del Proyecto
El proyecto está compuesto por varios componentes clave, cada uno con responsabilidades específicas:
- **Lexer**: Analiza la entrada del usuario y la convierte en tokens, que son las unidades básicas de sintaxis.
- **Parser**: Interpreta los tokens y construye un árbol de sintaxis abstracta (AST), que representa la estructura lógica de los comandos.
- **AST (Árbol de Sintaxis Abstracta)**: Representa la estructura de los comandos y tuberías, permitiendo su ejecución ordenada.
- **Ejecutor de Comandos**: Ejecuta los comandos basados en el AST, gestionando la ejecución de procesos y la redirección de flujos.
- **Shell Principal**: Maneja el bucle principal de la shell, incluyendo la entrada del usuario, el manejo de señales, y la gestión del historial de comandos.

## Desglose Detallado por Archivos y Funciones

### shell.py

#### `main_loop()`
- **Propósito**: Función principal que inicia el bucle de la shell, procesa la entrada del usuario y maneja excepciones.
- **Funcionamiento**: 
  1. Crea una instancia de `CommandExecutor`
  2. Entra en un bucle infinito que:
     - Muestra el prompt
     - Lee la entrada del usuario
     - Maneja expansión de historial
     - Tokeniza, parsea y ejecuta comandos
     - Captura y maneja excepciones
- **Ejemplo de uso**:
  ```
  Entrada: ls -l
  Proceso: 
  1. Se muestra el prompt "$ "
  2. El usuario ingresa "ls -l"
  3. Se tokeniza en ['ls', '-l']
  4. Se crea un AST Command(['ls', '-l'], [], False)
  5. Se ejecuta el comando, mostrando el listado detallado del directorio actual
  ```
### ast_tree.py

#### Clase `Command`
- **Propósito**: Representa un comando con sus argumentos, redirecciones y estado de ejecución.

#### `__init__(self, args: List[str], redirects: List[Tuple[str, str]] = None, background: bool = False) -> None`
- **Propósito**: Inicializa un objeto `Command`.
- **Parámetros**:
  - `args`: Lista de argumentos del comando (el primero es el comando).
  - `redirects`: Lista de tuplas (tipo, archivo) para redirecciones.
  - `background`: Indica si el comando debe ejecutarse en segundo plano.
- **Ejemplo**:
  ```python
  # Comando simple
  cmd1 = Command(['ls', '-l'], [], False)
  
  # Comando con redirección de salida
  cmd2 = Command(['echo', 'hola'], [('OUT', 'salida.txt')], False)
  
  # Comando en segundo plano
  cmd3 = Command(['sleep', '10'], [], True)
  ```

#### `__repr__(self) -> str`
- **Propósito**: Representación en cadena del objeto `Command`.
- **Retorno**: Cadena que representa el objeto.
- **Ejemplo**:
  ```
  Objeto: Command(['ls', '-l'], [], False)
  __repr__: "Command(['ls', '-l'], [], False)"
  ```

#### Clase `Pipe`
- **Propósito**: Representa una tubería entre dos comandos.

#### `__init__(self, left: Command, right: Command) -> None`
- **Propósito**: Inicializa un objeto `Pipe`.
- **Parámetros**:
  - `left`: Comando a la izquierda de la tubería.
  - `right`: Comando a la derecha de la tubería.
- **Ejemplo**:
  ```python
  # cat archivo.txt | grep palabra
  pipe = Pipe(
      Command(['cat', 'archivo.txt'], [], False),
      Command(['grep', 'palabra'], [], False)
  )
  ```

### Lexer.py

#### Clase `ShellLexer`
- **Propósito**: Convertir la entrada del usuario en tokens para facilitar el análisis sintáctico.

#### `__init__(self)`
- **Propósito**: Inicializa el lexer con estados vacíos.
- **Atributos inicializados**:
  - `self.tokens`: Lista de tokens generados.
  - `self.current_token`: Token actual en construcción.
  - `self.in_quote`: Indica si se está dentro de comillas.
  - `self.quote_char`: Carácter de comilla actual ('`"`' o '`'`').

#### `tokenize(self, line: str) -> List[str]`
- **Propósito**: Analiza una línea y la divide en tokens.
- **Parámetros**: 
  - `line`: La línea de entrada a tokenizar.
- **Retorno**: Lista de tokens.
- **Algoritmo**:
  1. Recorre cada carácter de la línea.
  2. Maneja comillas para agrupar texto.
  3. Identifica caracteres especiales (`|`, `<`, `>`, `&`).
  4. Separa la entrada en tokens.
- **Ejemplo de uso**:
  ```
  Entrada: echo "Hola Mundo" > salida.txt
  Salida: ['echo', '"Hola Mundo"', '>', 'salida.txt']
  
  Entrada: ls -la | grep ".txt" | sort
  Salida: ['ls', '-la', '|', 'grep', '".txt"', '|', 'sort']
  ```

#### `add_token(self)`
- **Propósito**: Agrega el token actual a la lista de tokens si no está vacío.
- **Funcionamiento**: Si `self.current_token` no está vacío, lo agrega a `self.tokens` y reinicia `self.current_token`.
- **Ejemplo**:
  ```
  Estado antes: self.current_token = "echo", self.tokens = []
  Después de add_token(): self.tokens = ["echo"], self.current_token = ""
  ```

### Parser.py

#### Clase `ShellParser`
- **Propósito**: Analiza los tokens y construye un árbol de sintaxis abstracta (AST).

#### `__init__(self, tokens: List[str]) -> None`
- **Propósito**: Inicializa el parser con tokens.
- **Parámetros**:
  - `tokens`: Lista de tokens generados por el lexer.
- **Inicialización**:
  - `self.tokens`: Almacena los tokens.
  - `self.pos`: Posición actual en la lista de tokens.

#### `parse(self) -> Command`
- **Propósito**: Punto de entrada para analizar los tokens.
- **Retorno**: Un objeto `Command` o `Pipe` que representa el comando completo.
- **Algoritmo**:
  1. Llama a `parse_pipe()` para construir el AST.
  2. Verifica si el comando debe ejecutarse en segundo plano (`&`).
- **Ejemplo de uso**:
  ```
  Entrada: ['ls', '-l', '&']
  Proceso:
  1. parse_pipe() devuelve Command(['ls', '-l'], [], False)
  2. Detecta '&' y marca el comando como background
  Salida: Command(['ls', '-l'], [], True)
  
  Entrada: ['cat', 'archivo.txt', '|', 'grep', 'palabra']
  Proceso:
  1. parse_pipe() crea una estructura Pipe
  Salida: Pipe(izq=(Command(['cat', 'archivo.txt'], [], False)), der=(Command(['grep', 'palabra'], [], False)))
  ```

#### `_mark_pipe_background(self, pipe_node) -> None`
- **Propósito**: Marca el último comando de una tubería para ejecutarse en segundo plano.
- **Parámetros**:
  - `pipe_node`: Nodo de tipo `Pipe` a marcar.
- **Algoritmo**: Recorre recursivamente la estructura de tuberías hasta llegar al último comando, que marca como background.
- **Ejemplo**:
  ```
  Entrada: Pipe(izq=(Command(['ls'], [], False)), der=(Command(['grep', 'txt'], [], False)))
  Después de _mark_pipe_background():
  Pipe(izq=(Command(['ls'], [], False)), der=(Command(['grep', 'txt'], [], True)))
  ```

#### `parse_pipe(self) -> Command`
- **Propósito**: Construye una estructura de tuberías si hay operador `|`.
- **Retorno**: Un objeto `Command` o `Pipe`.
- **Algoritmo**:
  1. Llama a `parse_redirect()` para obtener el comando izquierdo.
  2. Si encuentra `|`, construye un `Pipe` con el comando izquierdo y otro comando (derecho).
- **Ejemplo**:
  ```
  Entrada: ['ls', '|', 'grep', 'txt']
  Proceso:
  1. parse_redirect() devuelve Command(['ls'], [], False)
  2. Encuentra '|', obtiene otro comando Command(['grep', 'txt'], [], False)
  Salida: Pipe(izq=(Command(['ls'], [], False)), der=(Command(['grep', 'txt'], [], False)))
  ```

#### `parse_redirect(self) -> Command`
- **Propósito**: Construye un comando con sus argumentos y redirecciones.
- **Retorno**: Un objeto `Command`.
- **Algoritmo**:
  1. Recopila argumentos del comando.
  2. Identifica redirecciones (`<`, `>`, `>>`).
  3. Crea un objeto `Command` con los argumentos y redirecciones.
- **Ejemplo**:
  ```
  Entrada: ['echo', 'hola', '>', 'salida.txt']
  Proceso:
  1. Recopila 'echo', 'hola' como argumentos
  2. Encuentra '>' y 'salida.txt', lo agrega como redirección
  Salida: Command(['echo', 'hola'], [('OUT', 'salida.txt')], False)
  ```

#### `peek(self) -> str`
- **Propósito**: Muestra el token actual sin avanzar la posición.
- **Retorno**: El token actual o cadena vacía si llegó al final.
- **Ejemplo**:
  ```
  Estado: self.tokens = ['ls', '-l'], self.pos = 0
  Llamada: peek()
  Resultado: 'ls'
  ```

#### `consume(self, expected: str) -> str`
- **Propósito**: Consume el token actual si coincide con el esperado.
- **Parámetros**:
  - `expected`: Token esperado.
- **Retorno**: El token consumido.
- **Excepción**: `SyntaxError` si el token actual no coincide con el esperado.
- **Ejemplo**:
  ```
  Estado: self.tokens = ['|', 'grep'], self.pos = 0
  Llamada: consume('|')
  Resultado: '|', self.pos = 1
  
  Estado: self.tokens = ['ls', '-l'], self.pos = 0
  Llamada: consume('|')
  Resultado: SyntaxError("Expected '|', got 'ls'")
  ```

#### `consume_any(self) -> str`
- **Propósito**: Consume cualquier token actual.
- **Retorno**: El token consumido.
- **Excepción**: `SyntaxError` si no hay más tokens.
- **Ejemplo**:
  ```
  Estado: self.tokens = ['ls', '-l'], self.pos = 0
  Llamada: consume_any()
  Resultado: 'ls', self.pos = 1
  
  Estado: self.tokens = [], self.pos = 0
  Llamada: consume_any()
  Resultado: SyntaxError("Unexpected end of input")
  ```



#### `__repr__(self) -> str`
- **Propósito**: Representación en cadena del objeto `Pipe`.
- **Retorno**: Cadena que representa el objeto.
- **Ejemplo**:
  ```
  Objeto: Pipe(Command(['cat', 'archivo.txt'], [], False), Command(['grep', 'palabra'], [], False))
  __repr__: "Pipe(izq=(Command(['cat', 'archivo.txt'], [], False)), der=(Command(['grep', 'palabra'], [], False)))"
  ```

### executer.py

#### Clase `CommandExecutor`
- **Propósito**: Ejecuta comandos basados en el AST.

#### `__init__(self) -> None`
- **Propósito**: Inicializa el ejecutor de comandos.
- **Inicialización**:
  - `self.env`: Copia del entorno actual.
  - `self.last_return_code`: Código de retorno del último comando.
  - `self.jobs`: Diccionario de trabajos en segundo plano.
  - `self.current_job_id`: ID para el próximo trabajo.
  - `self.history`: Cola de historial de comandos.
  - `self.alias`: Diccionario de alias de comandos.
- **Ejemplo**:
  ```python
  executor = CommandExecutor()
  # Inicializado con env=os.environ.copy(), last_return_code=0, jobs={}, current_job_id=1, history=deque(maxlen=50), alias={}
  ```

#### `_handle_sigchld(self, signum, frame) -> None`
- **Propósito**: Maneja señales SIGCHLD para recoger procesos hijos terminados.
- **Algoritmo**:
  1. Usa `os.waitpid` para recoger procesos hijos.
  2. Actualiza el estado de los trabajos.
  3. Muestra mensajes sobre trabajos terminados.
- **Ejemplo**:
  ```
  Escenario: Un proceso en segundo plano (pid=1234) finaliza
  Acción: Se llama a _handle_sigchld automáticamente
  Resultado: Se elimina el trabajo del diccionario de jobs y se muestra "[1]    done       sleep 10"
  ```

#### `execute(self, node) -> int`
- **Propósito**: Ejecuta un nodo del AST.
- **Parámetros**:
  - `node`: Nodo del AST a ejecutar.
- **Retorno**: Código de retorno del comando ejecutado.
- **Algoritmo**:
  1. Dependiendo del tipo de nodo, llama a `_execute_command` o `_execute_pipe`.
- **Ejemplo**:
  ```
  Entrada: Command(['ls', '-l'], [], False)
  Proceso: Llama a _execute_command con el comando
  Salida: 0 (código de salida exitoso)
  
  Entrada: Pipe(Command(['cat', 'archivo.txt'], [], False), Command(['grep', 'palabra'], [], False))
  Proceso: Llama a _execute_pipe con la tubería
  Salida: Código de salida del último comando en la tubería
  ```

#### `_ast_to_string(self, node) -> str`
- **Propósito**: Convierte un nodo del AST a su representación en cadena.
- **Parámetros**:
  - `node`: Nodo del AST.
- **Retorno**: Representación en cadena del nodo.
- **Ejemplo**:
  ```
  Entrada: Command(['ls', '-l'], [('OUT', 'lista.txt')], False)
  Salida: "ls -l > lista.txt"
  
  Entrada: Pipe(Command(['cat', 'archivo.txt'], [], False), Command(['grep', 'palabra'], [], False))
  Salida: "cat archivo.txt | grep palabra"
  ```

#### `_execute_command(self, cmd: Command) -> int`
- **Propósito**: Ejecuta un comando simple.
- **Parámetros**:
  - `cmd`: Objeto `Command` a ejecutar.
- **Retorno**: Código de retorno del comando.
- **Algoritmo**:
  1. Verifica si es un comando interno (cd, exit, etc.).
  2. Si no, llama a `_spawn_process` para crear un proceso.
- **Ejemplo**:
  ```
  Entrada: Command(['cd', '/home'], [], False)
  Proceso: Llama a _builtin_cd con ['/home']
  Salida: 0 (código de éxito)
  
  Entrada: Command(['ls', '-l'], [], False)
  Proceso: Llama a _spawn_process para ejecutar 'ls -l'
  Salida: Código de retorno del proceso
  ```

#### `_spawn_process(self, args: List[str], redirects: List[Tuple[str, str]], background: bool) -> int`
- **Propósito**: Crea un nuevo proceso para ejecutar un comando.
- **Parámetros**:
  - `args`: Lista de argumentos del comando.
  - `redirects`: Lista de redirecciones.
  - `background`: Indica si debe ejecutarse en segundo plano.
- **Retorno**: Código de retorno del proceso.
- **Algoritmo**:
  1. Configura redirecciones de entrada/salida.
  2. Crea un proceso con `subprocess.Popen`.
  3. Si es en segundo plano, agrega a `self.jobs`.
  4. Si no, espera a que termine.
- **Ejemplo**:
  ```
  Entrada: _spawn_process(['ls', '-l'], [], False)
  Proceso: Ejecuta 'ls -l' en primer plano
  Salida: 0 (código de éxito)
  
  Entrada: _spawn_process(['sleep', '10'], [], True)
  Proceso: Ejecuta 'sleep 10' en segundo plano
  Salida: 0 (inmediatamente, mientras el proceso continúa)
  ```

#### `_execute_pipe(self, pipe_node: Pipe) -> int`
- **Propósito**: Ejecuta una tubería de comandos.
- **Parámetros**:
  - `pipe_node`: Objeto `Pipe` a ejecutar.
- **Retorno**: Código de retorno del último comando.
- **Algoritmo**:
  1. Aplana la tubería en una lista de comandos.
  2. Configura los procesos con las redirecciones apropiadas.
  3. Conecta la salida de cada proceso con la entrada del siguiente.
  4. Espera a que todos los procesos terminen.
- **Ejemplo**:
  ```
  Entrada: Pipe(Command(['cat', 'archivo.txt'], [], False), Command(['grep', 'palabra'], [], False))
  Proceso:
  1. Ejecuta 'cat archivo.txt' con salida a pipe
  2. Ejecuta 'grep palabra' con entrada desde pipe
  3. Espera a que ambos procesos terminen
  Salida: Código de retorno de 'grep palabra'
  ```

#### `_flatten_pipes(self, node, result: List[Command]) -> None`
- **Propósito**: Convierte una estructura de tuberías en una lista plana de comandos.
- **Parámetros**:
  - `node`: Nodo del AST.
  - `result`: Lista para almacenar los comandos.
- **Algoritmo**: Recorre recursivamente la estructura de tuberías, agregando comandos a la lista.
- **Ejemplo**:
  ```
  Entrada: Pipe(Command(['ls'], [], False), Pipe(Command(['grep', 'txt'], [], False), Command(['sort'], [], False)))
  Proceso: Recorre recursivamente la estructura
  Resultado: [Command(['ls'], [], False), Command(['grep', 'txt'], [], False), Command(['sort'], [], False)]
  ```

#### `_builtin_cd(self, args: List[str]) -> int`
- **Propósito**: Implementa el comando `cd` para cambiar de directorio.
- **Parámetros**:
  - `args`: Argumentos del comando.
- **Retorno**: 0 si éxito, 1 si error.
- **Algoritmo**:
  1. Sin argumentos, cambia al directorio home.
  2. Con `cd -`, cambia al directorio anterior.
  3. Con argumento, cambia al directorio especificado.
- **Ejemplo**:
  ```
  Entrada: _builtin_cd([])
  Proceso: Cambia al directorio home (~)
  Salida: 0
  
  Entrada: _builtin_cd(['-'])
  Proceso: Cambia al directorio anterior
  Salida: 0
  
  Entrada: _builtin_cd(['/home'])
  Proceso: Cambia al directorio /home
  Salida: 0
  ```

#### `add_to_history(self, command: str) -> None`
- **Propósito**: Agrega un comando al historial.
- **Parámetros**:
  - `command`: Comando a agregar.
- **Algoritmo**:
  1. Ignora comandos que empiezan con espacio.
  2. Elimina espacios al inicio y final.
  3. Agrega el comando si no está vacío y no es igual al último.
- **Ejemplo**:
  ```
  Estado inicial: self.history = deque(['ls', 'cd /home'])
  Entrada: add_to_history('echo hola')
  Resultado: self.history = deque(['ls', 'cd /home', 'echo hola'])
  
  Entrada: add_to_history('echo hola')  # Repetido
  Resultado: No cambia
  ```

#### `get_history_command(self, arg: str) -> Optional[str]`
- **Propósito**: Recupera un comando del historial basado en una referencia.
- **Parámetros**:
  - `arg`: Referencia de historial.
- **Retorno**: Comando recuperado o None.
- **Algoritmo**:
  1. Para `!!`, devuelve el último comando.
  2. Para `!n`, devuelve el comando n-ésimo.
  3. Para `!cadena`, devuelve el último comando que comienza con esa cadena.
- **Ejemplo**:
  ```
  Estado: self.history = deque(['ls', 'cd /home', 'echo hola'])
  
  Entrada: get_history_command('!!')
  Salida: 'echo hola'
  
  Entrada: get_history_command('!2')
  Salida: 'cd /home'
  
  Entrada: get_history_command('!e')
  Salida: 'echo hola'
  ```

## Manejo de Errores y Señales
El proyecto maneja errores comunes como `SyntaxError` y `FileNotFoundError`, y señales como `SIGINT` para interrumpir procesos en ejecución. Ejemplo: Si un archivo especificado en un comando no existe, se informa al usuario con un mensaje de error claro.

## Historial de Comandos
El historial de comandos permite recuperar y ejecutar comandos previos usando referencias como `!!` para el último comando y `!n` para un comando específico por número. Ejemplo: `!3` ejecuta el tercer comando en el historial.

## Ejemplos de Uso
- Ejecutar un comando simple: `ls` muestra el contenido del directorio actual.
- Redirigir salida a un archivo: `echo "Hola" > saludo.txt` guarda "Hola" en el archivo `saludo.txt`.
- Usar tuberías: `cat archivo.txt | grep "palabra"` filtra las líneas de `archivo.txt` que contienen "palabra".


