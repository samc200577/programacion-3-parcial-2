defmodule ValidacionIsla do
  @moduledoc """
  Módulo encargado de la validación previa del mapa de la isla, hecha solo con funciones
  recursivas propias (sin `Enum`, `Stream` ni comprensiones `for`).

  Revisa que:
  - todas las filas tengan el mismo número de posiciones que la fila 0;
  - todos los símbolos aparezcan en `terrenos.csv`;
  - haya exactamente una posición inicial y exactamente un bote;
  - todo el borde del mapa sea agua.

  Si alguna condición falla, se reportan todos los problemas encontrados, no solo el primero.
  """

  @doc """
  Valida `filas`, que es la lista de filas del mapa (cada fila es una lista de símbolos).

  `terrenos` es el mapa `simbolo => %Terreno{}` y `especiales` indica qué símbolo
  representa el inicio, el bote y el agua (`%{inicio: "P", bote: "B", agua: "~"}`),
  valores que también salen de `terrenos.csv`.

  Devuelve `:ok` si el mapa es válido, o `{:error, problemas}` con la lista de todos los
  problemas encontrados, en este orden: filas con otro ancho, problemas de cada posición
  (símbolos desconocidos y borde sin agua), cantidad de inicios y cantidad de botes.
  """
  def validar([], _terrenos, _especiales), do: {:error, ["El mapa está vacío"]}

  def validar([primera | _] = filas, terrenos, especiales) do
    contexto = %{
      ancho: contar(primera),
      alto: contar(filas),
      terrenos: terrenos,
      especiales: especiales
    }

    # El recorrido devuelve los problemas y las posiciones de inicio y bote en orden inverso.
    {problemas_posiciones, inicios, botes} = revisar_filas(filas, 0, contexto, {[], [], []})

    problemas =
      revisar_anchos(filas, 0, contexto.ancho) ++
        invertir(problemas_posiciones, []) ++
        revisar_cantidad(invertir(inicios, []), "posición inicial", "posiciones iniciales", especiales.inicio) ++
        revisar_cantidad(invertir(botes, []), "bote", "botes", especiales.bote)

    if problemas == [], do: :ok, else: {:error, problemas}
  end

  # --- Filas con distinto número de posiciones ---

  # Recorre las filas y compara la cantidad de posiciones de cada una con `esperado`
  # (el ancho de la fila 0). Devuelve un mensaje por cada fila que no coincide.
  # `indice` es el número de la fila actual, que empieza en 0.
  defp revisar_anchos([], _indice, _esperado), do: []

  defp revisar_anchos([fila | resto], indice, esperado) do
    cantidad = contar(fila)

    if cantidad == esperado do
      revisar_anchos(resto, indice + 1, esperado)
    else
      ["Fila #{indice}: tiene #{cantidad} posiciones; se esperaban #{esperado}"
       | revisar_anchos(resto, indice + 1, esperado)]
    end
  end

  # --- Recorrido de filas y columnas ---

  # Recorre las filas del mapa una por una y, para cada una, revisa sus columnas.
  # `acumulado` es la tupla {problemas, inicios, botes}, que se va pasando de fila en fila.
  # La última columna se calcula para cada fila, porque las filas pueden tener otro ancho.
  defp revisar_filas([], _fila, _contexto, acumulado), do: acumulado

  defp revisar_filas([simbolos | resto], fila, contexto, acumulado) do
    ultima_columna = contar(simbolos) - 1
    acumulado = revisar_columnas(simbolos, fila, 0, ultima_columna, contexto, acumulado)
    revisar_filas(resto, fila + 1, contexto, acumulado)
  end

  # Revisa cada posición de una fila:
  # - si el símbolo no existe en terrenos.csv, agrega un problema;
  # - si la posición está en el borde y no es agua, agrega un problema;
  # - si es el inicio o el bote, guarda su posición para contarlos después.
  # Los problemas y las posiciones se agregan al inicio de cada lista (quedan al revés).
  defp revisar_columnas([], _fila, _columna, _ultima, _contexto, acumulado), do: acumulado

  defp revisar_columnas([simbolo | resto], fila, columna, ultima, contexto, {problemas, inicios, botes}) do
    posicion = {fila, columna}
    especiales = contexto.especiales

    problemas =
      if Map.has_key?(contexto.terrenos, simbolo) do
        problemas
      else
        ["Posición #{Ruta.posicion_texto(posicion)}: el símbolo #{simbolo} no aparece en terrenos.csv"
         | problemas]
      end

    borde? = fila == 0 or fila == contexto.alto - 1 or columna == 0 or columna == ultima

    problemas =
      if borde? and simbolo != especiales.agua do
        ["Posición #{Ruta.posicion_texto(posicion)}: el borde debe ser agua y contiene #{simbolo}"
         | problemas]
      else
        problemas
      end

    inicios = if simbolo == especiales.inicio, do: [posicion | inicios], else: inicios
    botes = if simbolo == especiales.bote, do: [posicion | botes], else: botes

    revisar_columnas(resto, fila, columna + 1, ultima, contexto, {problemas, inicios, botes})
  end

  # --- Exactamente una posición inicial y un bote ---

  # Revisa que la lista de posiciones tenga exactamente un elemento, usando pattern matching:
  # - un elemento: correcto, no hay problemas;
  # - lista vacía: "No hay <singular> <símbolo>";
  # - varios elementos: "Hay N <plural> <símbolo>: <posiciones>".
  defp revisar_cantidad([_unica], _singular, _plural, _simbolo), do: []
  defp revisar_cantidad([], singular, _plural, simbolo), do: ["No hay #{singular} #{simbolo}"]

  defp revisar_cantidad(posiciones, _singular, plural, simbolo) do
    ["Hay #{contar(posiciones)} #{plural} #{simbolo}: #{unir_posiciones(posiciones)}"]
  end

  # --- Funciones auxiliares recursivas ---

  @doc """
  Cuenta los elementos de una lista de forma recursiva (reemplaza a `length/1`).
  """
  def contar([]), do: 0
  def contar([_ | resto]), do: 1 + contar(resto)

  # Invierte una lista pasando cada elemento al inicio del acumulador
  # (reemplaza a Enum.reverse/1). Se llama con el acumulador vacío: invertir(lista, []).
  defp invertir([], acumulado), do: acumulado
  defp invertir([cabeza | resto], acumulado), do: invertir(resto, [cabeza | acumulado])

  # Une una lista de posiciones como texto, separadas por comas y con "y" antes de la última
  # (reemplaza a Enum.join/2). Ejemplos: "{1,1} y {4,3}" o "{1,1}, {2,2} y {4,3}".
  defp unir_posiciones([ultima]), do: Ruta.posicion_texto(ultima)
  defp unir_posiciones([a, b]), do: "#{Ruta.posicion_texto(a)} y #{Ruta.posicion_texto(b)}"
  defp unir_posiciones([a | resto]), do: "#{Ruta.posicion_texto(a)}, #{unir_posiciones(resto)}"
end
