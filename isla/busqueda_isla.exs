defmodule BusquedaIsla do
  @moduledoc """
  Módulo encargado de la búsqueda recursiva (backtracking) de todas las rutas desde la
  posición inicial hasta el bote.

  La persona se mueve abajo, derecha, arriba o izquierda y no puede pasar dos veces por
  la misma posición dentro de una ruta. Las posiciones fuera del mapa y los terrenos no
  transitables se descartan con pattern matching sobre el struct `%Terreno{}`.
  """

  # Desplazamientos {fila, columna} en el orden en que se prueban:
  # abajo, derecha, arriba, izquierda.
  @direcciones [{1, 0}, {0, 1}, {-1, 0}, {0, -1}]

  @doc """
  Convierte las filas de símbolos en un mapa `{fila, columna} => %Terreno{}`, para
  consultar el terreno de cualquier posición con `Map.get/2`.

  Se llama después de la validación, así que todos los símbolos existen en `terrenos`.
  """
  def construir_mapa(filas, terrenos) do
    for {simbolos, fila} <- Enum.with_index(filas),
        {simbolo, columna} <- Enum.with_index(simbolos),
        into: %{} do
      {{fila, columna}, Map.fetch!(terrenos, simbolo)}
    end
  end

  @doc """
  Devuelve la primera posición `{fila, columna}` del mapa que contiene el símbolo indicado,
  o `nil` si no aparece. Se usa para ubicar el inicio y el bote.
  """
  def ubicar(filas, simbolo) do
    filas
    |> Enum.with_index()
    |> Enum.find_value(fn {simbolos, fila} ->
      case Enum.find_index(simbolos, &(&1 == simbolo)) do
        nil -> nil
        columna -> {fila, columna}
      end
    end)
  end

  @doc """
  Busca todas las rutas posibles de `inicio` a `bote` dentro de `mapa`.

  Devuelve la lista de rutas (`%Ruta{}`) en el orden en que se encuentran; si no hay
  ninguna, devuelve `[]`. La búsqueda empieza con la posición inicial ya visitada y con
  costo 0, porque la posición inicial no suma.
  """
  def buscar(mapa, inicio, bote) do
    estado = %{mapa: mapa, bote: bote}
    explorar(inicio, MapSet.new([inicio]), [inicio], 0, estado)
  end

  # Explora desde `posicion`. Recibe:
  # - visitadas: MapSet con las posiciones de la ruta actual (para no repetirlas);
  # - camino: posiciones de la ruta actual al revés (la última primero);
  # - costo: costo acumulado de la ruta actual;
  # - estado: datos que no cambian durante la búsqueda (mapa y posición del bote).
  # Devuelve la lista de rutas que se pueden completar desde aquí.

  # Caso base: la posición actual es el bote (pattern matching con %{bote: posicion}).
  # Se invierte el camino para dejar la posición inicial al principio.
  defp explorar(posicion, _visitadas, camino, costo, %{bote: posicion}) do
    [%Ruta{posiciones: Enum.reverse(camino), costo: costo}]
  end

  # Caso recursivo: probar las cuatro direcciones desde la posición actual.
  defp explorar(posicion, visitadas, camino, costo, estado) do
    probar_direcciones(@direcciones, posicion, visitadas, camino, costo, estado)
  end

  # Recorre recursivamente la lista de direcciones. Para cada una calcula la posición
  # siguiente, consulta su terreno y deja que avanzar/6 decida si se puede entrar.
  # Une con ++ las rutas encontradas en cada dirección; con la lista vacía devuelve [].
  defp probar_direcciones([], _posicion, _visitadas, _camino, _costo, _estado), do: []

  defp probar_direcciones([{df, dc} | resto], {fila, columna} = posicion, visitadas, camino, costo, estado) do
    siguiente = {fila + df, columna + dc}
    terreno = Map.get(estado.mapa, siguiente)

    avanzar(terreno, siguiente, visitadas, camino, costo, estado) ++
      probar_direcciones(resto, posicion, visitadas, camino, costo, estado)
  end

  # Decide si se puede entrar a la posición `siguiente` según su terreno.

  # Fuera del mapa (Map.get devolvió nil): se descarta.
  defp avanzar(nil, _siguiente, _visitadas, _camino, _costo, _estado), do: []

  # Terreno no transitable (árbol, agua...): se descarta con pattern matching sobre el struct.
  defp avanzar(%Terreno{transitable: false}, _siguiente, _visitadas, _camino, _costo, _estado), do: []

  # Terreno transitable: si la posición ya está en la ruta actual se descarta; si no, se
  # entra, se suma el costo del terreno y se sigue explorando desde ella (llamada recursiva).
  defp avanzar(%Terreno{transitable: true, costo: costo_terreno}, siguiente, visitadas, camino, costo, estado) do
    if MapSet.member?(visitadas, siguiente) do
      []
    else
      explorar(
        siguiente,
        MapSet.put(visitadas, siguiente),
        [siguiente | camino],
        costo + costo_terreno,
        estado
      )
    end
  end
end
