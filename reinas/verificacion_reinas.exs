defmodule VerificacionReinas do
  @moduledoc """
  Verifica tableros propuestos por otros, usando solo funciones recursivas propias
  (sin `Enum`, `Stream` ni comprensiones `for`).

  Cada tablero es una lista de columnas: el valor en la posición `i` es la columna
  de la reina de la fila `i`, y N es la cantidad de valores.
  """

  @doc """
  Verifica una línea de texto como `"1 3 0 2"` y devuelve el resultado como texto:
  `"válida"` o `"inválida: ..."` con todos los problemas encontrados.
  """
  def verificar_linea(texto) do
    case convertir(String.split(texto), []) do
      {:ok, columnas} -> verificar(columnas)
      {:error, motivo} -> "inválida: #{motivo}"
    end
  end

  @doc """
  Verifica una lista de columnas.

  Si alguna columna queda fuera del tablero se reporta eso; si no, se reportan todos
  los pares de reinas que se atacan (misma columna o misma diagonal).
  """
  def verificar(columnas) do
    n = contar(columnas)
    reinas = numerar(columnas, 0)

    case fuera_del_tablero(reinas, n) do
      [] ->
        case pares_en_conflicto(reinas) do
          [] -> "válida"
          conflictos -> "inválida: " <> unir(conflictos)
        end

      problemas ->
        "inválida: " <> unir(problemas)
    end
  end

  # --- Conversión del texto a enteros ---

  defp convertir([], acumulado), do: {:ok, invertir(acumulado, [])}

  defp convertir([valor | resto], acumulado) do
    case Integer.parse(valor) do
      {columna, ""} -> convertir(resto, [columna | acumulado])
      _ -> {:error, "el valor #{valor} no es un número entero"}
    end
  end

  # --- Columnas fuera del tablero ---

  defp fuera_del_tablero([], _n), do: []

  defp fuera_del_tablero([{_fila, columna} | resto], n) when columna < 0 or columna >= n do
    ["la columna #{columna} está fuera de un tablero de #{n} × #{n}" | fuera_del_tablero(resto, n)]
  end

  defp fuera_del_tablero([_reina | resto], n), do: fuera_del_tablero(resto, n)

  # --- Pares de reinas que se atacan ---

  # Compara cada reina con todas las que están en filas posteriores.
  defp pares_en_conflicto([]), do: []

  defp pares_en_conflicto([reina | resto]) do
    comparar(reina, resto) ++ pares_en_conflicto(resto)
  end

  defp comparar(_reina, []), do: []

  defp comparar({f1, c1} = reina, [{f2, c2} = otra | resto]) do
    cond do
      c1 == c2 ->
        ["reinas #{texto(reina)} y #{texto(otra)} en la misma columna" | comparar(reina, resto)]

      abs(c1 - c2) == abs(f1 - f2) ->
        ["reinas #{texto(reina)} y #{texto(otra)} en la misma diagonal" | comparar(reina, resto)]

      true ->
        comparar(reina, resto)
    end
  end

  # --- Funciones auxiliares recursivas ---

  defp contar([]), do: 0
  defp contar([_ | resto]), do: 1 + contar(resto)

  # [1, 3, 0, 2] -> [{0, 1}, {1, 3}, {2, 0}, {3, 2}]
  defp numerar([], _fila), do: []
  defp numerar([columna | resto], fila), do: [{fila, columna} | numerar(resto, fila + 1)]

  defp invertir([], acumulado), do: acumulado
  defp invertir([cabeza | resto], acumulado), do: invertir(resto, [cabeza | acumulado])

  defp unir([ultimo]), do: ultimo
  defp unir([primero | resto]), do: primero <> "; " <> unir(resto)

  defp texto({fila, columna}), do: "{#{fila},#{columna}}"
end
