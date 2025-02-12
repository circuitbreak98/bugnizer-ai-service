from fastapi import FastAPI, HTTPException
from transformers import pipeline
from pydantic import BaseModel
from typing import Optional
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

classifier = pipeline("text-classification", model="AntoineMC/distilbart-mnli-github-issues")

class BugTicket(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None

@app.post("/triage")
async def triage(ticket: BugTicket):
    if not ticket.title and not ticket.description:
        raise HTTPException(status_code=400, detail="Title or description is required")
    
    if ticket.title and ticket.description:
        text = f"{ticket.title} {ticket.description}"
    else:
        text = ticket.title or ticket.description

    try:
        prediction = classifier(text)[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error during prediction: {str(e)}")
    label = prediction['label']
    score = float(prediction.get('score', 0.0))
    return {"category": label, "confidence": score}

#uvicorn main:app --reload --host 0.0.0.0 --port 8000