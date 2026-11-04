defmodule BusquedaReinas do
  @moduledoc """
  Módulo encargado de la búsqueda recursiva y perezosa de las soluciones del problema de
  las N reinas, y de convertir cada solución en las líneas de su tablero.

  Una solución se representa como una lista de columnas: el valor en la posición `i` es
  la columna de la reina de la fila `i` (el mismo formato de `propuestas.txt`). Por
  ejemplo, `[1, 3, 0, 2]` pone la reina de la fila 0 en la columna 1. Como hay una reina
  por fila, nunca hay dos reinas en la misma fila.
  """

  @doc """
  Devuelve un Stream con todas las soluciones para un tablero de `n × n`.

  Nada se calcula hasta que alguien consume el Stream; cada solución se busca justo
  cuando se pide. Por eso `Enum.take(soluciones(20), 1)` termina rápido: solo recorre
  el árbol hasta encontrar la primera solución.
  """
  def soluciones(n) when is_integer(n) and n > 0, do: colocar(n, 0, [])

  # Coloca las reinas desde la fila `fila` hasta la última. `reinas` tiene las columnas
  # de las reinas ya ubicadas, al revés (la de la fila anterior primero).

  # Caso base: ya hay una reina en cada fila (fila = n). Se invierte `reinas` para dejar
  # la fila 0 al inicio y se devuelve una lista con esa única solución.
  defp colocar(n, n, reinas), do: [Enum.reverse(reinas)]

  # Caso recursivo: probar cada columna de la fila actual. Las columnas atacadas se
  # descartan (backtracking) y cada columna segura abre una nueva llamada recursiva.
  # Stream.flat_map une, de forma perezosa, los Streams de soluciones de cada rama.
  defp colocar(n, fila, reinas) do
    0..(n - 1)
    |> Stream.filter(fn columna -> segura?(columna, reinas, 1) end)
    |> Stream.flat_map(fn columna -> colocar(n, fila + 1, [columna | reinas]) end)
  end

  # Verifica si una reina nueva en `columna` puede ubicarse sin que la ataquen las que ya
  # están en `reinas`. `distancia` es cuántas filas hay entre la nueva reina y la reina que
  # se compara (1 para la fila anterior). Se ataca si está en la misma columna, o en la
  # misma diagonal (la diferencia de columnas es igual a la distancia entre filas).
  # Devuelve true con la lista vacía (no queda ninguna reina con la cual compararla).
  defp segura?(_columna, [], _distancia), do: true

  defp segura?(columna, [otra | resto], distancia) do
    otra != columna and abs(otra - columna) != distancia and
      segura?(columna, resto, distancia + 1)
  end

  @doc """
  Cuenta las soluciones para `n` consumiendo el Stream completo. Lo usa la secuencia
  infinita para calcular cada término.
  """
  def contar(n), do: n |> soluciones() |> Enum.count()

  @doc """
  Genera las líneas del tablero de una solución: una línea por fila, con `Q` donde hay
  una reina y `.` en las demás casillas, separadas por un espacio.
  """
  def tablero(solucion) do
    n = length(solucion)

    Enum.map(solucion, fn columna_reina ->
      Enum.map_join(0..(n - 1), " ", fn columna ->
        if columna == columna_reina, do: "Q", else: "."
      end)
    end)
  end
end
