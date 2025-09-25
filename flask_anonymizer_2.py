from flask import Flask, request, jsonify
from presidio_analyzer import AnalyzerEngine, PatternRecognizer, Pattern
from presidio_anonymizer import AnonymizerEngine, DeanonymizeEngine
from presidio_anonymizer.entities import OperatorConfig, OperatorResult

from opentelemetry import trace
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.propagate import extract

import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Setup OpenTelemetry tracing with OTLP exporter (modern approach)
trace.set_tracer_provider(
    TracerProvider(
        resource=Resource.create({SERVICE_NAME: "flask-anonymizer"})
    )
)

# Use OTLP exporter to send traces to Jaeger
otlp_exporter = OTLPSpanExporter(
    endpoint="http://localhost:14250",  # Jaeger OTLP/gRPC endpoint
    insecure=True
)

span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)
tracer = trace.get_tracer(__name__)

# Rest of your code stays the same...
phone_patterns = [
    Pattern(name="10_digit_us_format", regex=r"\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b", score=0.8),
    Pattern(name="indian_phone_number", regex=r"\b(\+91[-\s]?|0)?[6789]\d{9}\b", score=0.9),
    Pattern(name="uae_phone_number", regex=r"\b(\+971[-\s]?|0)?[1-9]\d{7,8}\b", score=0.9),
    Pattern(name="custom_grouping", regex=r"\b\d{3}[-\s]?\d{4}[-\s]?\d{4}\b", score=0.9),
    Pattern(name="generic_10_14_digit", regex=r"\b\d{10,14}\b", score=0.7),
]

custom_phone_recognizer = PatternRecognizer(
    supported_entity="PHONE_NUMBER",
    patterns=phone_patterns
)

analyzer = AnalyzerEngine()
analyzer.registry.add_recognizer(custom_phone_recognizer)
anonymizer = AnonymizerEngine()
deanonymizer = DeanonymizeEngine()

key = "3t6w9z$C&F)J@NcR"
encrypt_operators = {"DEFAULT": OperatorConfig("encrypt", {"key": key})}
decrypt_operators = {"DEFAULT": OperatorConfig("decrypt", {"key": key})}

def item_to_dict(item):
    return {"entity_type": item.entity_type, "start": item.start, "end": item.end}

def dict_to_item(d):
    return OperatorResult(entity_type=d["entity_type"], start=d["start"], end=d["end"])

cache = {}

@app.route("/anonymize/text", methods=["POST"])
def anonymize_text():
    try:
        ctx = extract(request.headers)
        with tracer.start_as_current_span("anonymize_text", context=ctx) as span:
            data = request.get_json(force=True)
            text = data.get("text", "")
            
            span.set_attribute("input_length", len(text))
            logger.debug(f"Received text: {text}")
            
            if not text:
                span.set_attribute("error", True)
                return jsonify({"error": "no text provided"}), 400

            results = analyzer.analyze(text=text, entities=["PERSON", "PHONE_NUMBER", "EMAIL_ADDRESS"], language="en")
            logger.debug(f"Detected entities: {[(r.entity_type, text[r.start:r.end]) for r in results]}")
            
            anonymized_result = anonymizer.anonymize(text=text, analyzer_results=results, operators=encrypt_operators)
            items_serializable = [item_to_dict(item) for item in anonymized_result.items]
            
            session_id = "sess1"
            cache[session_id] = {"text": anonymized_result.text, "items": items_serializable}
            
            span.set_attribute("entities_found", len(results))
            span.set_attribute("anonymization_success", True)
            
            # Force flush traces
            trace.get_tracer_provider().force_flush(timeout_millis=1000)
            
            return jsonify({"result": anonymized_result.text, "items": items_serializable, "session_id": session_id})
            
    except Exception as e:
        logger.error(f"Error in anonymize_text: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500

@app.route("/deanonymize/session", methods=["POST"])
def deanonymize_session():
    try:
        ctx = extract(request.headers)
        with tracer.start_as_current_span("deanonymize_session", context=ctx) as span:
            data = request.get_json(force=True)
            session_id = data.get("session_id", None)
            
            if not session_id or session_id not in cache:
                span.set_attribute("error", True)
                return jsonify({"error": "invalid session_id"}), 400

            encrypted_text = cache[session_id]["text"]
            items = cache[session_id]["items"]
            operator_results = [dict_to_item(item) for item in items]
            
            deanonymized_result = deanonymizer.deanonymize(text=encrypted_text, entities=operator_results, operators=decrypt_operators)
            logger.debug(f"Deanonymized text: {deanonymized_result.text}")
            
            span.set_attribute("deanonymization_success", True)
            
            # Force flush traces
            trace.get_tracer_provider().force_flush(timeout_millis=1000)
            
            return jsonify({"result": deanonymized_result.text})
            
    except Exception as e:
        logger.error(f"Error in deanonymize_session: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(port=5000, debug=True)
