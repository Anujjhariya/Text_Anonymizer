defmodule AnonymizerApp.Anonymizer do
  alias AnonymizerApp.PythonClient
  import OpenTelemetry.Tracer, only: [with_span: 2]

  def anonymize_text(params) do
    with_span "anonymize_text_span" do
      PythonClient.encrypt_text(params[:text])
    end
  end

  def deanonymize_text(params) do
    with_span "deanonymize_text_span" do
      PythonClient.decrypt_text(params[:encrypted_text])
    end
  end
end
