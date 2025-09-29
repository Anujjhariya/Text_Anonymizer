defmodule AnonymizerApp.PythonClient do
  use Tesla

  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  alias OpenTelemetry.Tracer

  # Safely inject trace context headers only if valid span context present
  defp inject_trace_context_headers(headers) do
    ctx = OpenTelemetry.Tracer.current_span_ctx()

    if valid_span_ctx?(ctx) do
      carrier = %{}
      :otel_propagator_text_map.inject(carrier, ctx)
      headers ++ Map.to_list(carrier)
    else
      headers
    end
  end

  defp valid_span_ctx?(:undefined), do: false
  defp valid_span_ctx?(%{span_id: span_id}) when is_binary(span_id) and byte_size(span_id) == 8, do: true
  defp valid_span_ctx?(_), do: false

  def encrypt_text(text) do
    json_body = Jason.encode!(%{text: text})
    base_headers = [{"content-type", "application/json"}]
    headers = inject_trace_context_headers(base_headers)
    url = "http://localhost:5000/anonymize/text"  # Full URL

    response = Tesla.post(url, json_body, headers: headers)
    IO.inspect(response, label: "Tesla encrypt response")

    case response do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"result" => encrypted_text, "items" => items}} ->
            {:ok, %{encrypted_text: encrypted_text, items: items}}

          {:ok, %{"result" => encrypted_text}} ->
            {:ok, %{encrypted_text: encrypted_text, items: []}}

          _ ->
            {:error, :invalid_response}
        end

      {:ok, %Tesla.Env{status: status, body: body}} ->
        IO.inspect(body, label: "Encrypt error response body")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        IO.inspect(reason, label: "Tesla encrypt error")
        {:error, reason}
    end
  end

  def decrypt_text(encrypted_text, items \\ []) do
    json_body = Jason.encode!(%{text: encrypted_text, items: items})
    base_headers = [{"content-type", "application/json"}]
    headers = inject_trace_context_headers(base_headers)
    url = "http://localhost:5000/deanonymize/text"  # Full URL

    response = Tesla.post(url, json_body, headers: headers)
    IO.inspect(response, label: "Tesla decrypt response")

    case response do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, decode_result(body)}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        IO.inspect(body, label: "Decrypt error response body")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        IO.inspect(reason, label: "Tesla decrypt error")
        {:error, reason}
    end
  end

  defp decode_result(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, %{"result" => result}} -> result
      _ -> body
    end
  end

  defp decode_result(other), do: other
end
