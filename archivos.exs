defmodule Archivos do
  @moduledoc """
  Lectura y escritura de archivos compartida por los dos problemas.

  La lectura se hace con `File.stream!/1`, línea por línea y de forma perezosa.
  La escritura se hace línea por línea sobre un archivo que se crea (o reemplaza)
  en cada ejecución.
  """

  @doc """
  Abre un archivo de entrada como un Stream perezoso de pares `{numero_linea, texto}`.

  - Los números de línea empiezan en 1 y cuentan todas las líneas del archivo,
    incluidos los comentarios y las líneas vacías (por eso se numera antes de filtrar).
  - Las líneas vacías y las que comienzan con `#` se descartan.
  - Si el archivo no existe devuelve `{:error, mensaje}` en lugar de lanzar una excepción.

  Nada se lee del disco hasta que alguien consume el Stream.
  """
  def leer_lineas(ruta) do
    if File.regular?(ruta) do
      lineas =
        ruta
        |> File.stream!()
        |> Stream.with_index(1)
        |> Stream.map(fn {linea, numero} -> {numero, String.trim(linea)} end)
        |> Stream.reject(fn {_numero, texto} -> ignorar?(texto) end)

      {:ok, lineas}
    else
      {:error, "No se encontró el archivo de entrada: #{ruta}"}
    end
  end

  defp ignorar?(""), do: true
  defp ignorar?("#" <> _resto), do: true
  defp ignorar?(_texto), do: false

  @doc """
  Escribe en `ruta` cada elemento de `lineas` (lista o Stream), uno por línea.

  El archivo se crea en cada ejecución; si ya existe, se reemplaza. Cada línea se
  escribe en cuanto se recibe, sin unir antes todo el contenido en un único string.
  """
  def escribir_lineas(ruta, lineas) do
    con_archivo(ruta, fn dispositivo ->
      Enum.each(lineas, fn linea -> IO.puts(dispositivo, linea) end)
    end)
  end

  @doc """
  Abre `ruta` para escritura y le pasa el dispositivo a `funcion`, que decide qué
  escribir. Sirve cuando se necesita escribir mientras se consume un Stream.
  """
  def con_archivo(ruta, funcion) do
    File.mkdir_p!(Path.dirname(ruta))
    File.open!(ruta, [:write, :utf8], funcion)
  end
end
