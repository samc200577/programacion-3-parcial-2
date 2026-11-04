# Problema 4: N reinas
#
# Uso (desde la carpeta reinas/):
#   elixir main.exs                          -> ejecuta todas las partes
#   elixir main.exs tamanos [archivo]        -> soluciones para cada N de datos/tamanos.txt
#   elixir main.exs n20                      -> solo la primera solución para N = 20
#   elixir main.exs propuestas [archivo]     -> verifica los tableros de datos/propuestas.txt
#   elixir main.exs secuencia [limite_ms]    -> Stream infinito N = 1, 2, 3, ... (límite 10000 ms)
#
# Los resultados quedan en la carpeta resultados/.

Code.require_file("../util.exs", __DIR__)
Code.require_file("../archivos.exs", __DIR__)
Code.require_file("busqueda_reinas.exs", __DIR__)
Code.require_file("verificacion_reinas.exs", __DIR__)
Code.require_file("secuencia_reinas.exs", __DIR__)

defmodule Reinas do
  @moduledoc """
  Punto de entrada del problema 4.
  """

  @resultados Path.join(__DIR__, "resultados")
  @limite_ms 10_000

  def main(["tamanos" | resto]), do: resolver_tamanos(archivo(resto, "datos/tamanos.txt"))
  def main(["n20" | _]), do: primera_solucion(20)
  def main(["propuestas" | resto]), do: verificar_propuestas(archivo(resto, "datos/propuestas.txt"))
  def main(["secuencia", limite | _]), do: secuencia(String.to_integer(limite))
  def main(["secuencia"]), do: secuencia(@limite_ms)

  def main([]) do
    resolver_tamanos(archivo([], "datos/tamanos.txt"))
    primera_solucion(20)
    verificar_propuestas(archivo([], "datos/propuestas.txt"))
    secuencia(@limite_ms)
  end

  def main(_otros) do
    Util.imprimir_error("Uso: elixir main.exs [tamanos|n20|propuestas|secuencia] [archivo|limite_ms]")
  end

  defp archivo([ruta | _], _por_defecto), do: ruta
  defp archivo([], por_defecto), do: Path.join(__DIR__, por_defecto)

  defp salida(nombre), do: Path.join(@resultados, nombre)

  # --- Tamaños del tablero ---

  defp resolver_tamanos(ruta) do
    Util.imprimir_mensaje("=== Soluciones para los tamaños de #{Path.relative_to_cwd(ruta)} ===")

    case Archivos.leer_lineas(ruta) do
      {:ok, lineas} ->
        # Cada línea se convierte de forma perezosa; las listas se construyen al final.
        {validos, errores} =
          lineas
          |> Stream.map(fn {numero, texto} -> {numero, texto, parse_tamano(texto)} end)
          |> Enum.split_with(fn {_numero, _texto, resultado} -> match?({:ok, _}, resultado) end)

        escribir_errores_tamanos(errores)
        Enum.each(validos, fn {_numero, _texto, {:ok, n}} -> escribir_soluciones(n) end)

      {:error, mensaje} ->
        Util.imprimir_error("Error: #{mensaje}")
    end
  end

  defp parse_tamano(texto) do
    case Integer.parse(texto) do
      {n, ""} ->
        case Util.validar_positivo(n) do
          {:ok, n} -> {:ok, n}
          {:error, _} -> {:error, "debe ser un entero positivo"}
        end

      _ ->
        {:error, "no es un número entero"}
    end
  end

  defp escribir_errores_tamanos(errores) do
    lineas =
      case errores do
        [] ->
          ["No se encontraron valores inválidos"]

        _ ->
          Enum.map(errores, fn {numero, texto, {:error, motivo}} ->
            "Línea #{numero}: #{texto} -> #{motivo}"
          end)
      end

    Archivos.escribir_lineas(salida("errores_tamanos.txt"), lineas)
    Util.imprimir_mensaje("Valores omitidos (errores_tamanos.txt):")
    Enum.each(lineas, &Util.imprimir_mensaje("  " <> &1))
  end

  # Cada solución se escribe en cuanto el Stream la produce; no se guardan en una lista.
  defp escribir_soluciones(n) do
    nombre = "reinas_n#{n}.txt"
    Util.imprimir_mensaje("\n=== N = #{n} ===")

    total =
      Archivos.con_archivo(salida(nombre), fn dispositivo ->
        total =
          n
          |> BusquedaReinas.soluciones()
          |> Stream.with_index(1)
          |> Enum.reduce(0, fn {solucion, numero}, _contador ->
            lineas = ["Solución #{numero}:" | BusquedaReinas.tablero(solucion)] ++ [""]

            Enum.each(lineas, fn linea ->
              IO.puts(dispositivo, linea)
              Util.imprimir_mensaje(linea)
            end)

            numero
          end)

        IO.puts(dispositivo, "Número total de soluciones: #{total}")
        total
      end)

    Util.imprimir_mensaje("Número total de soluciones: #{total}  (#{nombre})")
  end

  # --- Primera solución para N = 20 ---

  # Enum.take(1) solo pide un elemento al Stream: la búsqueda se detiene en la primera solución.
  defp primera_solucion(n) do
    Util.imprimir_mensaje("\n=== Primera solución para N = #{n} ===")

    {microsegundos, [solucion]} =
      :timer.tc(fn -> n |> BusquedaReinas.soluciones() |> Enum.take(1) end)

    lineas =
      [
        "Primera solución para N = #{n}",
        "Columnas por fila: #{Enum.join(solucion, " ")}",
        "Tiempo de cálculo: #{div(microsegundos, 1000)} ms",
        ""
      ] ++ BusquedaReinas.tablero(solucion)

    Archivos.escribir_lineas(salida("primera_solucion_n#{n}.txt"), lineas)
    Enum.each(lineas, &Util.imprimir_mensaje/1)
  end

  # --- Verificación de tableros propuestos ---

  defp verificar_propuestas(ruta) do
    Util.imprimir_mensaje("\n=== Verificación de #{Path.relative_to_cwd(ruta)} ===")

    case Archivos.leer_lineas(ruta) do
      {:ok, lineas} ->
        resultados =
          Stream.map(lineas, fn {_numero, texto} ->
            "#{texto} -> #{VerificacionReinas.verificar_linea(texto)}"
          end)

        Archivos.con_archivo(salida("verificacion_reinas.txt"), fn dispositivo ->
          Enum.each(resultados, fn linea ->
            IO.puts(dispositivo, linea)
            Util.imprimir_mensaje(linea)
          end)
        end)

      {:error, mensaje} ->
        Util.imprimir_error("Error: #{mensaje}")
    end
  end

  # --- Stream infinito N = 1, 2, 3, ... ---

  defp secuencia(limite_ms) do
    Util.imprimir_mensaje("\n=== Secuencia de las N reinas (límite: #{limite_ms} ms por término) ===")

    mostrar = fn {n, soluciones, tiempo_ms} ->
      comparacion =
        case SecuenciaReinas.oeis(n) do
          ^soluciones -> "coincide con A000170"
          nil -> "sin dato de A000170"
          esperado -> "NO coincide con A000170 (#{esperado})"
        end

      limite = if tiempo_ms >= limite_ms, do: "  -> supera el límite; no se incluye", else: ""
      palabra = if soluciones == 1, do: "solución", else: "soluciones"
      Util.imprimir_mensaje("N = #{n}: #{soluciones} #{palabra} en #{tiempo_ms} ms (#{comparacion})#{limite}")
    end

    Archivos.con_archivo(salida("secuencia_reinas.csv"), fn dispositivo ->
      IO.puts(dispositivo, "n;soluciones;tiempo_ms")

      limite_ms
      |> SecuenciaReinas.mientras_tarde_menos_de(mostrar)
      |> Enum.each(fn {n, soluciones, tiempo_ms} ->
        IO.puts(dispositivo, "#{n};#{soluciones};#{tiempo_ms}")
      end)
    end)

    Util.imprimir_mensaje("Términos escritos en secuencia_reinas.csv")
  end
end

Reinas.main(System.argv())
