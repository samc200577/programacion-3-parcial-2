defmodule Terreno do
  @moduledoc """
  Módulo que representa un tipo de terreno de la isla, tal como se define en
  `terrenos.csv`, y que convierte cada línea de ese archivo en un `%Terreno{}`.

  Ningún símbolo ni costo está escrito en el código: todo sale del archivo.

  Campos del struct:
  - `simbolo`: carácter con el que aparece en el mapa (por ejemplo `"C"`).
  - `nombre`: descripción del terreno (por ejemplo `"camino"`).
  - `transitable`: `true` si la persona puede pasar por él.
  - `costo`: lo que suma a la ruta entrar a una posición con este terreno.
  """

  defstruct simbolo: nil, nombre: nil, transitable: false, costo: 0

  @doc """
  Convierte una línea con el formato `simbolo,nombre,transitable,costo` en un `%Terreno{}`.

  Devuelve `{:ok, %Terreno{}}` si la línea es válida, o `{:error, motivo}` si le faltan
  campos, si `transitable` no es `si`/`no` o si el costo no es un entero mayor o igual a cero.
  """
  def parse(linea) do
    case linea |> String.split(",") |> Enum.map(&String.trim/1) do
      [simbolo, nombre, transitable, costo] when simbolo != "" and nombre != "" ->
        with {:ok, transitable} <- parse_transitable(transitable),
             {:ok, costo} <- parse_costo(costo) do
          {:ok, %Terreno{simbolo: simbolo, nombre: nombre, transitable: transitable, costo: costo}}
        end

      _ ->
        {:error, "se esperaban 4 campos: simbolo,nombre,transitable,costo"}
    end
  end

  # Convierte el campo transitable ("si", "sí" o "no", sin importar mayúsculas) en un booleano.
  # Devuelve {:ok, true}, {:ok, false} o {:error, motivo}.
  defp parse_transitable(texto) do
    case String.downcase(texto) do
      valor when valor in ["si", "sí"] -> {:ok, true}
      "no" -> {:ok, false}
      _ -> {:error, "transitable debe ser si o no"}
    end
  end

  # Convierte el campo costo en un entero mayor o igual a cero.
  # Devuelve {:ok, costo} o {:error, motivo} si el texto no es un entero válido.
  defp parse_costo(texto) do
    case Integer.parse(texto) do
      {costo, ""} when costo >= 0 -> {:ok, costo}
      _ -> {:error, "el costo debe ser un entero mayor o igual a cero"}
    end
  end
end
