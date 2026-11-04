defmodule ReporteIsla do
  @moduledoc """
  Módulo encargado de generar las líneas del resumen de la búsqueda: total de rutas,
  ruta o rutas más cortas, ruta de menor costo y el mapa con la ruta de menor costo
  marcada con `*`.

  Las mismas líneas se muestran en pantalla y se escriben en `resumen_isla.txt`.
  """

  @doc """
  Genera las líneas del resumen.

  `numeradas` es la lista de pares `{%Ruta{}, numero}`, `filas` es el mapa de la isla
  (lista de filas de símbolos) y `especiales` son los símbolos de inicio, bote y agua
  (se recibe para mantener la misma información que el resto del programa, aunque el
  resumen no lo necesita).

  Si no hay rutas, el resumen lo indica y muestra el mapa sin marcar.
  """
  def lineas_resumen([], filas, _especiales) do
    ["Número total de rutas: 0", "No existe ninguna ruta hasta el bote", "", "Mapa de la isla:"] ++
      lineas_mapa(filas, MapSet.new())
  end

  def lineas_resumen(numeradas, filas, _especiales) do
    por_numero = Map.new(numeradas, fn {ruta, numero} -> {numero, ruta} end)

    # Util.maximos_en busca el valor máximo; con los valores negados obtenemos el mínimo
    # y todas las rutas empatadas en él.
    {cortas, menos_movimientos} =
      numeradas
      |> Enum.map(fn {ruta, numero} -> {numero, -Ruta.movimientos(ruta)} end)
      |> Util.maximos_en()

    {baratas, menor_costo} =
      numeradas
      |> Enum.map(fn {ruta, numero} -> {numero, -ruta.costo} end)
      |> Util.maximos_en()

    mejor = Map.fetch!(por_numero, hd(baratas))

    ["Número total de rutas: #{length(numeradas)}"] ++
      lineas_mas_corta(cortas, -menos_movimientos, por_numero) ++
      lineas_menor_costo(baratas, -menor_costo, por_numero) ++
      ["", "Mapa con la ruta de menor costo (ruta #{hd(baratas)}) marcada con *:"] ++
      lineas_mapa(filas, posiciones_marcadas(mejor))
  end

  # Genera las líneas de la ruta más corta: una línea con la cantidad de movimientos y los
  # números de las rutas empatadas, y una línea por cada una con su costo y su recorrido.
  # `por_numero` es el mapa numero => %Ruta{}.
  defp lineas_mas_corta(numeros, movimientos, por_numero) do
    ["Ruta más corta: #{movimientos} movimientos (#{texto_rutas(numeros)})"] ++
      Enum.map(numeros, fn numero ->
        ruta = Map.fetch!(por_numero, numero)
        "  Ruta #{numero} (costo #{ruta.costo}): #{Ruta.recorrido(ruta)}"
      end)
  end

  # Genera las líneas de la ruta de menor costo.
  # Si hay una sola, muestra su costo, sus movimientos y su recorrido.
  defp lineas_menor_costo([numero], costo, por_numero) do
    ruta = Map.fetch!(por_numero, numero)

    [
      "Ruta de menor costo: costo #{costo} (#{Ruta.movimientos(ruta)} movimientos) (ruta #{numero})",
      "  Ruta #{numero}: #{Ruta.recorrido(ruta)}"
    ]
  end

  # Si hay empate, indica entre qué rutas y muestra los movimientos y el recorrido de cada una.
  defp lineas_menor_costo(numeros, costo, por_numero) do
    ["Ruta de menor costo: costo #{costo}, empatada entre #{texto_rutas(numeros)}"] ++
      Enum.map(numeros, fn numero ->
        ruta = Map.fetch!(por_numero, numero)
        "  Ruta #{numero} (#{Ruta.movimientos(ruta)} movimientos): #{Ruta.recorrido(ruta)}"
      end)
  end

  # Devuelve un MapSet con las posiciones que se marcan con * en el mapa: las posiciones
  # intermedias de la ruta. El inicio y el bote conservan su símbolo para que se vean.
  defp posiciones_marcadas(%Ruta{posiciones: posiciones}) do
    posiciones
    |> Enum.drop(1)
    |> Enum.drop(-1)
    |> MapSet.new()
  end

  # Genera una línea de texto por cada fila del mapa, con los símbolos separados por un
  # espacio. Las posiciones que están en `marcadas` se reemplazan por *.
  defp lineas_mapa(filas, marcadas) do
    filas
    |> Enum.with_index()
    |> Enum.map(fn {simbolos, fila} ->
      simbolos
      |> Enum.with_index()
      |> Enum.map_join(" ", fn {simbolo, columna} ->
        if MapSet.member?(marcadas, {fila, columna}), do: "*", else: simbolo
      end)
    end)
  end

  # Escribe los números de ruta como texto: "ruta 3" si es una sola,
  # "rutas 1 y 2" o "rutas 1, 2 y 4" si son varias.
  defp texto_rutas([numero]), do: "ruta #{numero}"

  defp texto_rutas(numeros) do
    {primeros, [ultimo]} = Enum.split(numeros, -1)
    "rutas #{Enum.join(primeros, ", ")} y #{ultimo}"
  end
end
