defmodule Terreno do
  @moduledoc """
  Tipo de terreno de la isla, tal como se define en `terrenos.csv`.

  Ningún símbolo ni costo está escrito en el código: todo sale del archivo.
  """

  defstruct simbolo: nil, nombre: nil, transitable: false, costo: 0

  @doc """
  Convierte una línea `simbolo,nombre,transitable,costo` en un `%Terreno{}`.

  Devuelve `{:ok, %Terreno{}}` o `{:error, motivo}`.
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

  defp parse_transitable(texto) do
    case String.downcase(texto) do
      valor when valor in ["si", "sí"] -> {:ok, true}
      "no" -> {:ok, false}
      _ -> {:error, "transitable debe ser si o no"}
    end
  end

  defp parse_costo(texto) do
    case Integer.parse(texto) do
      {costo, ""} when costo >= 0 -> {:ok, costo}
      _ -> {:error, "el costo debe ser un entero mayor o igual a cero"}
    end
  end
end
