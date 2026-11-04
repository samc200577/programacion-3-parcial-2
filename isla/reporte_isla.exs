defmodule ReporteIsla do
  @moduledoc """
  Genera las líneas del resumen: total de rutas, ruta(s) más corta(s), ruta de menor
  costo y el mapa con la ruta de menor costo marcada con `*`.
  """

  @doc """
  `numeradas` es la lista de pares `{%Ruta{}, numero}`.
  Devuelve una lista de líneas que se muestran en pantalla y se escriben en el archivo.
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

  defp lineas_mas_corta(numeros, movimientos, por_numero) do
    ["Ruta más corta: #{movimientos} movimientos (#{texto_rutas(numeros)})"] ++
      Enum.map(numeros, fn numero ->
        ruta = Map.fetch!(por_numero, numero)
        "  Ruta #{numero} (costo #{ruta.costo}): #{Ruta.recorrido(ruta)}"
      end)
  end

  defp lineas_menor_costo([numero], costo, por_numero) do
    ruta = Map.fetch!(por_numero, numero)

    [
      "Ruta de menor costo: costo #{costo} (#{Ruta.movimientos(ruta)} movimientos) (ruta #{numero})",
      "  Ruta #{numero}: #{Ruta.recorrido(ruta)}"
    ]
  end

  defp lineas_menor_costo(numeros, costo, por_numero) do
    ["Ruta de menor costo: costo #{costo}, empatada entre #{texto_rutas(numeros)}"] ++
      Enum.map(numeros, fn numero ->
        ruta = Map.fetch!(por_numero, numero)
        "  Ruta #{numero} (#{Ruta.movimientos(ruta)} movimientos): #{Ruta.recorrido(ruta)}"
      end)
  end

  # Se marcan las posiciones intermedias; el inicio y el bote conservan su símbolo.
  defp posiciones_marcadas(%Ruta{posiciones: posiciones}) do
    posiciones
    |> Enum.drop(1)
    |> Enum.drop(-1)
    |> MapSet.new()
  end

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

  defp texto_rutas([numero]), do: "ruta #{numero}"

  defp texto_rutas(numeros) do
    {primeros, [ultimo]} = Enum.split(numeros, -1)
    "rutas #{Enum.join(primeros, ", ")} y #{ultimo}"
  end
end
