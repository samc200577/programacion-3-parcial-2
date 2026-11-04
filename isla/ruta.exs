defmodule Ruta do
  @moduledoc """
  Ruta encontrada desde la posición inicial hasta el bote.

  `posiciones` va en orden de recorrido (la primera es la posición inicial) y
  `costo` es la suma de los costos de las posiciones a las que se entra.
  """

  defstruct posiciones: [], costo: 0

  @doc "Número de movimientos: una posición menos que las visitadas."
  def movimientos(%Ruta{posiciones: posiciones}), do: length(posiciones) - 1

  @doc "Recorrido como texto: `{1,1} -> {2,1} -> ...`."
  def recorrido(%Ruta{posiciones: posiciones}) do
    Enum.map_join(posiciones, " -> ", &posicion_texto/1)
  end

  @doc "Coordenada `{fila, columna}` como texto, sin espacios: `{1,1}`."
  def posicion_texto({fila, columna}), do: "{#{fila},#{columna}}"

  @doc "Líneas que se muestran en pantalla para la ruta número `numero`."
  def lineas_pantalla(%Ruta{} = ruta, numero) do
    [
      "Ruta #{numero}:",
      recorrido(ruta),
      "Número de movimientos: #{movimientos(ruta)}",
      "Costo: #{ruta.costo}",
      ""
    ]
  end

  @doc "Línea de `rutas_isla.csv`: `ruta;movimientos;costo;recorrido`."
  def linea_csv(%Ruta{} = ruta, numero) do
    "#{numero};#{movimientos(ruta)};#{ruta.costo};#{recorrido(ruta)}"
  end
end
