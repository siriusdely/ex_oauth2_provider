defmodule ExOauth2Provider.Mixin.Scopes do
  @moduledoc false
  alias ExOauth2Provider.Scopes

  defmacro __using__(_) do
    quote location: :keep do
      def put_scopes(%{} = changeset), do: put_scopes(changeset, nil)
      def put_scopes(%{} = changeset, ""), do: put_scopes(changeset, nil)
      def put_scopes(%{} = changeset, server_scopes) do
        case changeset |> get_field(:scopes) |> is_empty do
          true -> changeset |> change(%{scopes: default_scopes_string(server_scopes)})
          _    -> changeset
        end
      end

      def validate_scopes(%{} = changeset), do: validate_scopes(changeset, nil)
      def validate_scopes(%{} = changeset, ""), do: validate_scopes(changeset, nil)
      def validate_scopes(%{} = changeset, server_scopes) do
        server_scopes = server_scopes |> permitted_scopes

        case can_use_scopes?(get_field(changeset, :scopes), server_scopes) do
          true -> changeset
          _    -> add_error(changeset, :scopes, "not in permitted scopes list: #{inspect(server_scopes)}")
        end
      end

      defp is_empty(""), do: true
      defp is_empty(nil), do: true
      defp is_empty(_), do: false

      defp default_scopes_string(nil), do: default_scopes_string("")
      defp default_scopes_string(server_scopes) when is_binary(server_scopes),
        do: server_scopes |> Scopes.to_list |> default_scopes_string
      defp default_scopes_string(server_scopes) do
        server_scopes
        |> Scopes.default_to_server_scopes
        |> Scopes.filter_default_scopes
        |> Scopes.to_string
      end

      defp can_use_scopes?(scopes, server_scopes) when is_binary(scopes) do
        scopes
        |> Scopes.to_list
        |> can_use_scopes?(server_scopes)
      end
      defp can_use_scopes?(scopes, server_scopes) when is_binary(server_scopes) do
        can_use_scopes?(scopes, server_scopes |> Scopes.to_list)
      end
      defp can_use_scopes?(scopes, server_scopes) do
        server_scopes
        |> Scopes.default_to_server_scopes
        |> Scopes.all?(scopes)
      end

      defp permitted_scopes(nil),
        do: ExOauth2Provider.Config.server_scopes
      defp permitted_scopes(server_scopes),
        do: server_scopes
    end
  end
end
