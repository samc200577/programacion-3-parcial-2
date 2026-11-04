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

  Orquesta las cuatro partes del problema: las soluciones para cada N de `tamanos.txt`,
  la primera solución para N = 20, la verificación de los tableros de `propuestas.txt` y
  la secuencia infinita N = 1, 2, 3, ... Todos los resultados se muestran en pantalla y se
  escriben en la carpeta `resultados/`.
  """

  @resultados Path.join(__DIR__, "resultados")

  # Tiempo máximo (en milisegundos) que puede tardar un término de la secuencia infinita.
  @limite_ms 10_000

  @doc """
  Ejecuta el programa según los argumentos de la línea de comandos.

  - `[]`: ejecuta todas las partes con los archivos de `datos/`.
  - `["tamanos" | archivo]`: soluciones para cada N del archivo (por defecto `datos/tamanos.txt`).
  - `["n20"]`: solo la primera solución para N = 20.
  - `["propuestas" | archivo]`: verifica los tableros del archivo (por defecto `datos/propuestas.txt`).
  - `["secuencia" | limite_ms]`: secuencia infinita con el límite indicado (por defecto 10000 ms).

  Con cualquier otro argumento muestra cómo se usa el programa.
  """
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

  # Devuelve la ruta del archivo de entrada: la que se pasó como argumento o, si no se
  # pasó ninguna, el archivo por defecto dentro de la carpeta de este script.
  defp archivo([ruta | _], _por_defecto), do: ruta
  defp archivo([], por_defecto), do: Path.join(__DIR__, por_defecto)

  # Devuelve la ruta completa de un archivo de salida dentro de resultados/.
  defp salida(nombre), do: Path.join(@resultados, nombre)

  # --- Tamaños del tablero ---

  # Lee los valores de N del archivo, escribe los valores inválidos en errores_tamanos.txt
  # y, para cada N válido, escribe todas sus soluciones en reinas_n<N>.txt.
  # Si el archivo no existe, muestra un mensaje de error.
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

  # Convierte una línea de tamanos.txt en un tamaño de tablero.
  # Devuelve {:ok, n} si es un entero positivo (se valida con Util.validar_positivo),
  # o {:error, motivo} si no es un entero o si es cero o negativo.
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

  # Escribe en errores_tamanos.txt una línea por cada valor omitido, con su número de
  # línea, su contenido y el motivo, y también la muestra en pantalla. Si no hubo errores,
  # el archivo lo indica.
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

  # Escribe en reinas_n<N>.txt (y muestra en pantalla) todos los tableros numerados de N y,
  # al final, el número total de soluciones.
  # Cada solución se escribe en cuanto el Stream la produce; no se guardan en una lista.
  # Enum.reduce lleva como acumulador el número de la última solución, que al final es el total.
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

  # Calcula solo la primera solución para `n`, mide cuánto tarda y la escribe en
  # primera_solucion_n<N>.txt con sus columnas, el tiempo y el tablero.
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

  # Verifica cada tablero del archivo con VerificacionReinas y escribe en
  # verificacion_reinas.txt (y en pantalla) una línea "<tablero> -> <resultado>".
  # Las líneas se procesan con un Stream y se escriben a medida que se verifican.
  # Si el archivo no existe, muestra un mensaje de error.
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

  # Consume la secuencia infinita mientras cada término tarde menos de `limite_ms` y
  # escribe cada término en secuencia_reinas.csv apenas se calcula.
  # En pantalla se muestra cada término calculado (incluido el que supera el límite),
  # comparado con la secuencia A000170 de la OEIS.
  defp secuencia(limite_ms) do
    Util.imprimir_mensaje("\n=== Secuencia de las N reinas (límite: #{limite_ms} ms por término) ===")

    # Función que recibe cada término calculado y lo muestra en pantalla.
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
