# Text_Anonymizer
Text Anonymizer API — A Flask-based REST API that detects and encrypts sensitive information such as names, emails, and phone numbers in text using Microsoft's Presidio, with session-based deanonymization and OpenTelemetry tracing integration for observability.

This API provides endpoints to anonymize and deanonymize personal information (names, emails, phone numbers) in unstructured text using encryption and session-based storage. It is built with Flask, Microsoft Presidio libraries, and OpenTelemetry tracing.


1. Clone repository
```bash
git clone <your-repo-url>
cd <repo-directory>
```
2. Create & activate virtual environment

```bash
python -m venv venv
# On Windows:
venv\Scripts\activate
# On Mac/Linux:
source venv/bin/activate
```

3. Install dependencies

```
pip install -r requirements.txt
```
4. Run the API

```
python flask_anonymizer_2.py
```

5. Anonymize Text Endpoint
```bash
curl -X POST {BASE_URL}/anonymize/text \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"My name is John Smith, email john@example.com, phone 123-456-7890\"}"
```

Response:
```json
{
  "result": "My name is <ENCRYPTED>, email <ENCRYPTED>, phone 123-456-7890",
  "items": [
    {"entity_type": "PERSON", "start": 11, "end": 21},
    {"entity_type": "EMAIL_ADDRESS", "start": 28, "end": 44}
  ],
  "session_id": "sess1"
}
```

6. Deanonymize Session Endpoint

Request:
```bash
curl -X POST {BASE_URL}/deanonymize/session \
  -H "Content-Type: application/json" \
  -d "{\"session_id\": \"sess1\"}"
```

Response:
```json
{
  "result": "My name is John Smith, email john@example.com, phone 123-456-7890"
}
```


7. 
