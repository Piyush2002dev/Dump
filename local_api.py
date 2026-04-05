import json
import uvicorn
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

from lambda_function import lambda_handler

app = FastAPI(title="Recommendation Agent - Local Runner")


# ─────────────────────────────────────────────────────────────
# Request Models
# ─────────────────────────────────────────────────────────────
class TriggerRequest(BaseModel):
    quoteId: str


class BatchRequest(BaseModel):
    quoteIds: list[str]


# ─────────────────────────────────────────────────────────────
# Helper — build the SQS-style event that lambda_handler expects
# ─────────────────────────────────────────────────────────────
def build_sqs_event(quote_id: str) -> dict:
    return {
        "Records": [
            {
                "body": json.dumps({
                    "quote_id": quote_id
                })
            }
        ]
    }


# ─────────────────────────────────────────────────────────────
# Health check
# ─────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "Recommendation Agent Local Runner",
        "port": 8020
    }


# ─────────────────────────────────────────────────────────────
# POST /recommend/trigger
# Accepts quoteId as query param OR JSON body.
#
# Example (query param):
#   POST http://localhost:8020/recommend/trigger?quoteId=Q-12345
#
# Example (JSON body):
#   POST http://localhost:8020/recommend/trigger
#   { "quoteId": "Q-12345" }
# ─────────────────────────────────────────────────────────────
@app.post("/recommend/trigger")
def trigger_recommendation(
    quoteId: str = Query(None),
    payload: TriggerRequest = None
):
    quote_id = quoteId or (payload.quoteId if payload else None)

    if not quote_id:
        raise HTTPException(status_code=400, detail="quoteId is required")

    try:
        event = build_sqs_event(quote_id)
        response = lambda_handler(event, None)

        status_code = response.get("statusCode", 500)
        body = json.loads(response["body"])

        if status_code != 200:
            raise HTTPException(
                status_code=status_code,
                detail=body.get("error", "Lambda handler returned an error")
            )

        return {
            "quoteId": quote_id,
            "status": "success",
            "message": body.get("message", "Processed successfully")
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────────────────────
# POST /recommend/batch
# Run recommendations for multiple quoteIds at once.
#
# Example:
#   POST http://localhost:8020/recommend/batch
#   { "quoteIds": ["Q-001", "Q-002", "Q-003"] }
# ─────────────────────────────────────────────────────────────
@app.post("/recommend/batch")
def trigger_batch_recommendation(payload: BatchRequest):
    if not payload.quoteIds:
        raise HTTPException(
            status_code=400,
            detail="quoteIds list is required and must not be empty"
        )

    results = []
    for qid in payload.quoteIds:
        try:
            event = build_sqs_event(qid)
            response = lambda_handler(event, None)
            status_code = response.get("statusCode", 500)
            body = json.loads(response["body"])

            if status_code == 200:
                results.append({
                    "quoteId": qid,
                    "status": "success",
                    "message": body.get("message", "Processed successfully")
                })
            else:
                results.append({
                    "quoteId": qid,
                    "status": "error",
                    "error": body.get("error", "Unknown error")
                })

        except Exception as e:
            results.append({
                "quoteId": qid,
                "status": "error",
                "error": str(e)
            })

    return {
        "batchSize": len(results),
        "results": results
    }


# ─────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run("local_api:app", host="0.0.0.0", port=8020, reload=True)