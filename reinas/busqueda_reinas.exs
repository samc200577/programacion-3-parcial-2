defmodule BusquedaReinas do
  @moduledoc """
  Búsqueda recursiva y perezosa de las soluciones del problema de las N reinas.

  Una solución se representa como una lista de columnas: el valor en la posición
  `i` es la columna de la reina de la fila `i` (el mismo formato de `propuestas.txt`).
  Como hay una reina por fila, nunca hay dos reinas en la misma fila.
  """

  @doc """
  Devuelve un Stream con todas las soluciones para un tablero de `n × n`.

  Nada se calcula hasta que alguien consume el Stream; cada solución se busca
  justo cuando se pide la siguiente.
  """
  def soluciones(n) when is_integer(n) and n > 0, do: colocar(n, 0, [])

  # Caso base: ya hay una reina en cada fila. `reinas` está al revés (la última fila
  # primero), así que se invierte para dejar la fila 0 al inicio.
  defp colocar(n, n, reinas), do: [Enum.reverse(reinas)]

  # Caso recursivo: probar cada columna de la fila actual. Las columnas atacadas se
  # descartan (backtracking) y cada columna segura abre una nueva llamada recursiva.
  # Stream.flat_map une, de forma perezosa, los Streams de soluciones de cada rama.
  defp colocar(n, fila, reinas) do
    0..(n - 1)
    |> Stream.filter(fn columna -> segura?(columna, reinas, 1) end)
    |> Stream.flat_map(fn columna -> colocar(n, fila + 1, [columna | reinas]) end)
  end

  # Verifica la nueva reina contra las ya ubicadas. `distancia` es cuántas filas
  # hay entre la nueva reina y la reina que se compara (1 para la fila anterior).
  defp segura?(_columna, [], _distancia), do: true

  defp segura?(columna, [otra | resto], distancia) do
    otra != columna and abs(otra - columna) != distancia and
      segura?(columna, resto, distancia + 1)
  end

  @doc "Cuenta las soluciones para `n` consumiendo el Stream completo."
  def contar(n), do: n |> soluciones() |> Enum.count()

  @doc """
  Líneas del tablero de una solución: `Q` donde hay reina y `.` en las demás casillas.
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
