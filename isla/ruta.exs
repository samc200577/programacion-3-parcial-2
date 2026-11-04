defmodule Ruta do
  @moduledoc """
  Módulo que representa una ruta encontrada desde la posición inicial hasta el bote y
  genera las líneas con las que se muestra en pantalla y en `rutas_isla.csv`.

  Campos del struct:
  - `posiciones`: lista de coordenadas `{fila, columna}` en orden de recorrido; la primera
    es la posición inicial y la última es el bote.
  - `costo`: suma de los costos de las posiciones a las que se entra (la inicial no suma).
  """

  defstruct posiciones: [], costo: 0

  @doc """
  Calcula el número de movimientos de una ruta a partir de sus posiciones: siempre es una
  menos que la cantidad de posiciones visitadas.
  """
  def movimientos(%Ruta{posiciones: posiciones}), do: length(posiciones) - 1

  @doc """
  Devuelve el recorrido de la ruta como texto, con las coordenadas unidas por flechas:
  `{1,1} -> {2,1} -> ...`.
  """
  def recorrido(%Ruta{posiciones: posiciones}) do
    Enum.map_join(posiciones, " -> ", &posicion_texto/1)
  end

  @doc """
  Convierte una coordenada `{fila, columna}` en texto sin espacios, por ejemplo `{1,1}`.
  También la usa `ValidacionIsla` para indicar dónde está cada problema.
  """
  def posicion_texto({fila, columna}), do: "{#{fila},#{columna}}"

  @doc """
  Genera las líneas que se muestran en pantalla para la ruta número `numero`: encabezado,
  recorrido, número de movimientos, costo y una línea en blanco de separación.
  """
  def lineas_pantalla(%Ruta{} = ruta, numero) do
    [
      "Ruta #{numero}:",
      recorrido(ruta),
      "Número de movimientos: #{movimientos(ruta)}",
      "Costo: #{ruta.costo}",
      ""
    ]
  end

  @doc """
  Genera la línea de `rutas_isla.csv` para la ruta número `numero`, con el formato
  `ruta;movimientos;costo;recorrido`. Se usa `;` porque las coordenadas tienen comas.
  """
  def linea_csv(%Ruta{} = ruta, numero) do
    "#{numero};#{movimientos(ruta)};#{ruta.costo};#{recorrido(ruta)}"
  end
end
