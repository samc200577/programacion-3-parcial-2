defmodule BusquedaIsla do
  @moduledoc """
  Búsqueda recursiva (backtracking) de todas las rutas desde la posición inicial
  hasta el bote.

  La persona se mueve arriba, abajo, izquierda o derecha y no puede pasar dos
  veces por la misma posición dentro de una ruta.
  """

  # Orden en que se prueban los movimientos: abajo, derecha, arriba, izquierda.
  @direcciones [{1, 0}, {0, 1}, {-1, 0}, {0, -1}]

  @doc """
  Convierte las filas de símbolos en un mapa `{fila, columna} => %Terreno{}`.
  """
  def construir_mapa(filas, terrenos) do
    for {simbolos, fila} <- Enum.with_index(filas),
        {simbolo, columna} <- Enum.with_index(simbolos),
        into: %{} do
      {{fila, columna}, Map.fetch!(terrenos, simbolo)}
    end
  end

  @doc "Primera posición del mapa que contiene el símbolo indicado."
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
  Devuelve la lista de todas las rutas (`%Ruta{}`) de `inicio` a `bote`.
  """
  def buscar(mapa, inicio, bote) do
    estado = %{mapa: mapa, bote: bote}
    explorar(inicio, MapSet.new([inicio]), [inicio], 0, estado)
  end

  # Caso base: se llegó al bote. `camino` está al revés (la última posición primero).
  defp explorar(posicion, _visitadas, camino, costo, %{bote: posicion}) do
    [%Ruta{posiciones: Enum.reverse(camino), costo: costo}]
  end

  # Caso recursivo: probar las cuatro direcciones desde la posición actual.
  defp explorar(posicion, visitadas, camino, costo, estado) do
    probar_direcciones(@direcciones, posicion, visitadas, camino, costo, estado)
  end

  defp probar_direcciones([], _posicion, _visitadas, _camino, _costo, _estado), do: []

  defp probar_direcciones([{df, dc} | resto], {fila, columna} = posicion, visitadas, camino, costo, estado) do
    siguiente = {fila + df, columna + dc}
    terreno = Map.get(estado.mapa, siguiente)

    avanzar(terreno, siguiente, visitadas, camino, costo, estado) ++
      probar_direcciones(resto, posicion, visitadas, camino, costo, estado)
  end

  # Fuera del mapa: se descarta.
  defp avanzar(nil, _siguiente, _visitadas, _camino, _costo, _estado), do: []

  # Terreno no transitable (árbol, agua...): se descarta con pattern matching sobre el struct.
  defp avanzar(%Terreno{transitable: false}, _siguiente, _visitadas, _camino, _costo, _estado), do: []

  # Terreno transitable: se entra si no se había visitado en esta ruta.
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
