defmodule SecuenciaReinas do
  @moduledoc """
  Módulo encargado de la secuencia infinita N = 1, 2, 3, ... del problema de las N reinas,
  transformada en tuplas `{n, soluciones, tiempo_ms}`.

  Cada término se calcula solo cuando se consume, y la secuencia se corta cuando un
  cálculo tarda más que el límite indicado.
  """

  # Valores de la secuencia A000170 de la OEIS (número de soluciones para N = 1, 2, ...).
  # Solo se usan para comparar los resultados en pantalla.
  @oeis_a000170 [1, 0, 0, 2, 10, 4, 40, 92, 352, 724, 2680, 14200, 73712, 365596, 2279184,
                 14772512, 95815104, 666090624]

  @doc """
  Devuelve el Stream infinito de tuplas `{n, soluciones, tiempo_ms}`.

  Cada término se calcula solo cuando se consume: se cuentan las soluciones de N con la
  búsqueda recursiva de `BusquedaReinas` y se mide cuánto tardó.
  """
  def terminos do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(&medir/1)
  end

  @doc """
  Toma los términos de la secuencia mientras cada cálculo tarde menos de `limite_ms`.

  El término que supera el límite se calcula completo (no se interrumpe), pero
  `Stream.take_while/2` lo descarta y detiene la secuencia. `al_calcular` es una función
  que se llama con cada término calculado, incluido el que se descarta, para poder
  mostrarlo en pantalla.
  """
  def mientras_tarde_menos_de(limite_ms, al_calcular \\ fn _termino -> :ok end) do
    terminos()
    |> Stream.each(al_calcular)
    |> Stream.take_while(fn {_n, _soluciones, tiempo_ms} -> tiempo_ms < limite_ms end)
  end

  # Cuenta las soluciones para `n` y mide cuánto tarda con :timer.tc, que devuelve el
  # tiempo en microsegundos. Devuelve la tupla {n, soluciones, tiempo_ms}.
  defp medir(n) do
    {microsegundos, soluciones} = :timer.tc(fn -> BusquedaReinas.contar(n) end)
    {n, soluciones, div(microsegundos, 1000)}
  end

  @doc """
  Devuelve el valor de la secuencia A000170 para `n`, o `nil` si `n` no está en la tabla.
  """
  def oeis(n), do: Enum.at(@oeis_a000170, n - 1)
end
