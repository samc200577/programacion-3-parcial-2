# Problema 2: Escapar de la isla
#
# Uso (desde la carpeta isla/):
#   elixir main.exs                                   -> usa datos/isla.txt y datos/terrenos.csv
#   elixir main.exs datos/isla_invalida.txt           -> otro mapa, mismos terrenos
#   elixir main.exs <isla.txt> <terrenos.csv>         -> ambos archivos
#
# Los resultados quedan en la carpeta resultados/.

Code.require_file("../util.exs", __DIR__)
Code.require_file("../archivos.exs", __DIR__)
Code.require_file("terreno.exs", __DIR__)
Code.require_file("ruta.exs", __DIR__)
Code.require_file("validacion_isla.exs", __DIR__)
Code.require_file("busqueda_isla.exs", __DIR__)
Code.require_file("reporte_isla.exs", __DIR__)

defmodule Isla do
  @moduledoc """
  Punto de entrada del problema 2.

  Orquesta el flujo completo: lee `terrenos.csv` y el mapa de la isla con Streams, valida
  el mapa, busca todas las rutas hasta el bote y genera `validacion_isla.txt`,
  `rutas_isla.csv` y `resumen_isla.txt` en la carpeta `resultados/`.
  """

  @resultados Path.join(__DIR__, "resultados")

  # Los símbolos especiales se identifican por su nombre en terrenos.csv,
  # así ningún símbolo queda escrito en el código.
  @nombres_especiales %{inicio: "inicio", bote: "bote", agua: "agua"}

  @doc """
  Ejecuta el flujo principal del programa con los argumentos de la línea de comandos.

  `args` puede estar vacío (usa los archivos de `datos/`), traer solo la ruta del mapa o
  traer la ruta del mapa y la de `terrenos.csv`. Si algún paso falla (archivo inexistente,
  terrenos inválidos o mapa inválido), muestra un mensaje de error y no sigue con los demás.
  """
  def main(args) do
    {ruta_isla, ruta_terrenos} = rutas_entrada(args)
    Util.imprimir_mensaje("=== Escapar de la isla ===")
    Util.imprimir_mensaje("Mapa: #{Path.relative_to_cwd(ruta_isla)}")
    Util.imprimir_mensaje("Terrenos: #{Path.relative_to_cwd(ruta_terrenos)}\n")

    with {:ok, terrenos} <- cargar_terrenos(ruta_terrenos),
         {:ok, especiales} <- simbolos_especiales(terrenos),
         {:ok, filas} <- cargar_isla(ruta_isla),
         :ok <- validar_mapa(filas, terrenos, especiales) do
      resolver(filas, terrenos, especiales)
    else
      {:error, mensaje} -> Util.imprimir_error("Error: #{mensaje}")
    end
  end

  # Obtiene las rutas del mapa y de terrenos.csv a partir de los argumentos.
  # Si falta alguno, se usa el archivo correspondiente de la carpeta datos/.
  defp rutas_entrada([isla, terrenos | _]), do: {isla, terrenos}
  defp rutas_entrada([isla]), do: {isla, Path.join(__DIR__, "datos/terrenos.csv")}

  defp rutas_entrada([]) do
    {Path.join(__DIR__, "datos/isla.txt"), Path.join(__DIR__, "datos/terrenos.csv")}
  end

  # --- Lectura con Streams ---

  # Lee terrenos.csv y devuelve {:ok, mapa} con el mapa simbolo => %Terreno{}.
  # Cada línea se convierte en %Terreno{} de forma perezosa; el mapa solo se construye
  # cuando el Enum.reduce consume el Stream. Las líneas mal formadas se muestran como
  # error y se omiten. Devuelve {:error, mensaje} si el archivo no existe o si no queda
  # ningún terreno válido.
  defp cargar_terrenos(ruta) do
    with {:ok, lineas} <- Archivos.leer_lineas(ruta) do
      {terrenos, errores} =
        lineas
        |> Stream.map(fn {numero, texto} -> {numero, texto, Terreno.parse(texto)} end)
        |> Enum.reduce({%{}, []}, fn
          {_numero, _texto, {:ok, terreno}}, {mapa, errores} ->
            {Map.put(mapa, terreno.simbolo, terreno), errores}

          {numero, texto, {:error, motivo}}, {mapa, errores} ->
            {mapa, ["terrenos.csv, línea #{numero}: #{texto} -> #{motivo}" | errores]}
        end)

      errores |> Enum.reverse() |> Enum.each(&Util.imprimir_error/1)

      if map_size(terrenos) == 0,
        do: {:error, "#{ruta} no tiene ningún terreno válido"},
        else: {:ok, terrenos}
    end
  end

  # Busca en los terrenos el símbolo del inicio, del bote y del agua según su nombre.
  # Devuelve {:ok, %{inicio: "P", bote: "B", agua: "~"}} (con los símbolos del archivo)
  # o {:error, mensaje} si terrenos.csv no define alguno de los tres.
  defp simbolos_especiales(terrenos) do
    especiales =
      Map.new(@nombres_especiales, fn {clave, nombre} ->
        simbolo =
          Enum.find_value(terrenos, fn {simbolo, terreno} ->
            if terreno.nombre == nombre, do: simbolo
          end)

        {clave, simbolo}
      end)

    if Enum.any?(especiales, fn {_clave, simbolo} -> simbolo == nil end),
      do: {:error, "terrenos.csv debe definir los terrenos inicio, bote y agua"},
      else: {:ok, especiales}
  end

  # Lee el mapa de la isla y devuelve {:ok, filas}, donde cada fila es una lista de símbolos.
  # Cada línea se separa en símbolos de forma perezosa; la lista de filas se construye al
  # final con Enum.to_list. Devuelve {:error, mensaje} si el archivo no existe.
  defp cargar_isla(ruta) do
    with {:ok, lineas} <- Archivos.leer_lineas(ruta) do
      filas =
        lineas
        |> Stream.map(fn {_numero, texto} -> String.split(texto) end)
        |> Enum.to_list()

      {:ok, filas}
    end
  end

  # --- Validación previa (recursiva) ---

  # Valida el mapa con ValidacionIsla y escribe el resultado en validacion_isla.txt.
  # Si el mapa es válido devuelve :ok; si no, muestra todos los problemas en pantalla y
  # devuelve {:error, mensaje} para que main/1 no realice la búsqueda.
  defp validar_mapa(filas, terrenos, especiales) do
    ruta_salida = Path.join(@resultados, "validacion_isla.txt")

    case ValidacionIsla.validar(filas, terrenos, especiales) do
      :ok ->
        Archivos.escribir_lineas(ruta_salida, ["El mapa es válido; se realiza la búsqueda."])
        Util.imprimir_mensaje("Validación del mapa: correcta\n")
        :ok

      {:error, problemas} ->
        Archivos.escribir_lineas(ruta_salida, problemas)
        Util.imprimir_mensaje("Validación del mapa: se encontraron #{length(problemas)} problemas")
        Enum.each(problemas, &Util.imprimir_mensaje/1)
        {:error, "el mapa no es válido; no se realiza la búsqueda (ver #{Path.relative_to_cwd(ruta_salida)})"}
    end
  end

  # --- Búsqueda y salidas ---

  # Construye el mapa de terrenos, ubica el inicio y el bote, busca todas las rutas y genera
  # las salidas: cada ruta en pantalla, rutas_isla.csv (una línea por ruta) y el resumen,
  # que se muestra en pantalla y se escribe en resumen_isla.txt.
  defp resolver(filas, terrenos, especiales) do
    mapa = BusquedaIsla.construir_mapa(filas, terrenos)
    inicio = BusquedaIsla.ubicar(filas, especiales.inicio)
    bote = BusquedaIsla.ubicar(filas, especiales.bote)

    numeradas =
      mapa
      |> BusquedaIsla.buscar(inicio, bote)
      |> Enum.with_index(1)

    Enum.each(numeradas, fn {ruta, numero} ->
      Enum.each(Ruta.lineas_pantalla(ruta, numero), &Util.imprimir_mensaje/1)
    end)

    lineas_csv =
      Stream.concat(
        ["ruta;movimientos;costo;recorrido"],
        Stream.map(numeradas, fn {ruta, numero} -> Ruta.linea_csv(ruta, numero) end)
      )

    Archivos.escribir_lineas(Path.join(@resultados, "rutas_isla.csv"), lineas_csv)

    resumen = ReporteIsla.lineas_resumen(numeradas, filas, especiales)
    Enum.each(resumen, &Util.imprimir_mensaje/1)
    Archivos.escribir_lineas(Path.join(@resultados, "resumen_isla.txt"), resumen)

    Util.imprimir_mensaje("\nArchivos generados en #{Path.relative_to_cwd(@resultados)}")
  end
end

Isla.main(System.argv())
