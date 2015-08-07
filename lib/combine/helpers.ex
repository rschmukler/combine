defmodule Combine.Helpers do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      require Combine.Helpers
      import Combine.Helpers
    end
  end

  defmacro defparser(call, do: body) do
    call = Macro.postwalk(call, fn {x, y, nil} -> {x, y, __CALLER__.module}; expr -> expr end)
    body = Macro.postwalk(body, fn {x, y, nil} -> {x, y, __CALLER__.module}; expr -> expr end)
    {name, args} = case call do
      {:when, _, [{name, _, args}|_]} -> {name, args}
      {name, _, args} -> {name, args}
    end
    other_args = case args do
      [_]      -> []
      [_|rest] -> rest
      _        -> raise(ArgumentError, "Invalid defparser arguments: (#{Macro.to_string args})")
    end

    quote do
      def unquote(name)(unquote_splicing(other_args)) do
        fn state -> unquote(name)(state, unquote_splicing(other_args)) end
      end
      def unquote(name)(parser, unquote_splicing(other_args)) when is_function(parser, 1) do
        fn
          %Combine.ParserState{status: :ok} = state ->
            unquote(name)(parser.(state), unquote_splicing(other_args))
          %Combine.ParserState{} = state ->
            state
        end
      end
      def unquote(name)(%Combine.ParserState{status: :error} = state, unquote_splicing(other_args)), do: state
      def unquote(call) do
        unquote(body)
      end
    end
  end

end
