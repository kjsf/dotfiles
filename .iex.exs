# Will be using `ANSI`
Application.put_env(:elixir, :ansi_enabled, true)

# Letting people know what iex.exs they are using
IO.puts(
  IO.ANSI.blink_slow() <>
    "\nUsing IEx global config\n" <> IO.ANSI.reset()
)

# Get queue length for the IEx process
# This is fun to see while playing with nodes
queue_length = fn ->
  self()
  |> Process.info()
  |> Keyword.get(:message_queue_len)
end

prefix =
  IO.ANSI.bright() <>
    IO.ANSI.yellow() <>
    "%prefix" <>
    IO.ANSI.reset()

counter =
  IO.ANSI.bright() <>
    IO.ANSI.white() <>
    "%counter" <>
    IO.ANSI.reset()

# info = IO.ANSI.yellow() <> "#{queue_length.()}" <> IO.ANSI.reset()

last = IO.ANSI.bright() <> IO.ANSI.white() <> "$" <> IO.ANSI.reset()

alive =
  IO.ANSI.bright() <>
    IO.ANSI.yellow() <>
    IO.ANSI.blink_rapid() <>
    "*" <>
    IO.ANSI.reset()

default_prompt = prefix <> "(" <> counter <> ")" <> " " <> last
alive_prompt = prefix <> "(" <> counter <> ")" <> " " <> alive <> last

inspect_limit = 5_000
history_size = 100

eval_result = [:green, :bright]
eval_error = [:red, :bright]
eval_info = [:white, :bright]

# Configuring IEx
IEx.configure(
  inspect: [limit: inspect_limit],
  history_size: history_size,
  colors: [
    eval_result: eval_result,
    eval_error: eval_error,
    eval_info: eval_info
  ],
  default_prompt: default_prompt,
  alive_prompt: alive_prompt
)

# Phoenix Support
import_if_available(Plug.Conn)
import_if_available(Phoenix.HTML)

phoenix_app =
  :application.info()
  |> Keyword.get(:running)
  |> Enum.reject(fn {_x, y} ->
    y == :undefined
  end)
  |> Enum.find(fn {x, _y} ->
    x |> Atom.to_string() |> String.match?(~r{_web})
  end)

# Check if phoenix app is found
case phoenix_app do
  nil ->
    :ok

  {app, _pid} ->
    IO.puts("Phoenix app found: #{app}\n")

    ecto_app =
      app
      |> Atom.to_string()
      |> (&Regex.split(~r{_web}, &1)).()
      |> Enum.at(0)
      |> String.to_atom()

    exists =
      :application.info()
      |> Keyword.get(:running)
      |> Enum.reject(fn {_x, y} ->
        y == :undefined
      end)
      |> Enum.map(fn {x, _y} -> x end)
      |> Enum.member?(ecto_app)

    # Check if Ecto app exists or running
    case exists do
      false ->
        :ok

      true ->
        IO.puts("Ecto app found: #{ecto_app}\n")

        # Ecto Support
        import_if_available(Ecto.Query)
        import_if_available(Ecto.Changeset)

        # Alias Repo
        repo = ecto_app |> Application.get_env(:ecto_repos) |> Enum.at(0)

        quote do
          alias unquote(repo), as: Repo
        end
    end
end