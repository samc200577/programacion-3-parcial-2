defmodule VerificacionReinas do
  @moduledoc """
  Módulo encargado de verificar tableros propuestos por otros, usando solo funciones
  recursivas propias (sin `Enum`, `Stream` ni comprensiones `for`).

  Cada tablero es una lista de columnas: el valor en la posición `i` es la columna de la
  reina de la fila `i`, y N es la cantidad de valores. Un tablero es inválido si tiene
  valores que no son enteros, columnas fuera del tablero o reinas que se atacan.
  """

  @doc """
  Verifica una línea de texto como `"1 3 0 2"` y devuelve el resultado como texto:
  `"válida"`, o `"inválida: ..."` con todos los problemas encontrados.

  Primero convierte cada valor a entero; si alguno no lo es, la propuesta es inválida y
  no se sigue revisando.
  """
  def verificar_linea(texto) do
    case convertir(String.split(texto), []) do
      {:ok, columnas} -> verificar(columnas)
      {:error, motivo} -> "inválida: #{motivo}"
    end
  end

  @doc """
  Verifica una lista de columnas y devuelve `"válida"` o `"inválida: ..."`.

  Si alguna columna queda fuera del tablero, se reportan esas columnas; si no, se reportan
  todos los pares de reinas que se atacan (misma columna o misma diagonal), separados por `;`.
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

  # Convierte la lista de textos en una lista de enteros con Integer.parse.
  # Devuelve {:ok, columnas} o {:error, motivo} con el primer valor que no es un entero.
  # Los enteros se acumulan al revés, así que se invierten al terminar.
  defp convertir([], acumulado), do: {:ok, invertir(acumulado, [])}

  defp convertir([valor | resto], acumulado) do
    case Integer.parse(valor) do
      {columna, ""} -> convertir(resto, [columna | acumulado])
      _ -> {:error, "el valor #{valor} no es un número entero"}
    end
  end

  # --- Columnas fuera del tablero ---

  # Recorre las reinas y devuelve un mensaje por cada columna que queda fuera de un tablero
  # de n × n, es decir, menor que 0 o mayor o igual que n (se revisa con un guard).
  defp fuera_del_tablero([], _n), do: []

  defp fuera_del_tablero([{_fila, columna} | resto], n) when columna < 0 or columna >= n do
    ["la columna #{columna} está fuera de un tablero de #{n} × #{n}" | fuera_del_tablero(resto, n)]
  end

  defp fuera_del_tablero([_reina | resto], n), do: fuera_del_tablero(resto, n)

  # --- Pares de reinas que se atacan ---

  # Compara cada reina con todas las que están en filas posteriores, así cada par se
  # revisa una sola vez. Une con ++ los conflictos de cada reina; con la lista vacía devuelve [].
  defp pares_en_conflicto([]), do: []

  defp pares_en_conflicto([reina | resto]) do
    comparar(reina, resto) ++ pares_en_conflicto(resto)
  end

  # Compara `reina` con cada una de las reinas de la lista y devuelve un mensaje por cada
  # par que se ataca: misma columna si c1 = c2, misma diagonal si |c1 − c2| = |f1 − f2|.
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

  # Cuenta los elementos de una lista (reemplaza a length/1).
  defp contar([]), do: 0
  defp contar([_ | resto]), do: 1 + contar(resto)

  # Asocia a cada columna su número de fila, empezando en `fila`
  # (reemplaza a Enum.with_index/1): [1, 3, 0, 2] -> [{0, 1}, {1, 3}, {2, 0}, {3, 2}].
  defp numerar([], _fila), do: []
  defp numerar([columna | resto], fila), do: [{fila, columna} | numerar(resto, fila + 1)]

  # Invierte una lista pasando cada elemento al inicio del acumulador
  # (reemplaza a Enum.reverse/1). Se llama con el acumulador vacío: invertir(lista, []).
  defp invertir([], acumulado), do: acumulado
  defp invertir([cabeza | resto], acumulado), do: invertir(resto, [cabeza | acumulado])

  # Une una lista de mensajes separándolos con "; " (reemplaza a Enum.join/2).
  defp unir([ultimo]), do: ultimo
  defp unir([primero | resto]), do: primero <> "; " <> unir(resto)

  # Convierte la posición de una reina {fila, columna} en texto sin espacios: {0,1}.
  defp texto({fila, columna}), do: "{#{fila},#{columna}}"
end
