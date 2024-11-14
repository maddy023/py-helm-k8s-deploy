"""FastAPI application that provides endpoints for IP address retrieval and health checking."""

from fastapi import FastAPI
import requests

app = FastAPI()


@app.get("/")
async def get_public_ip():
    """Retrieve the public IP address of the server using ipify API."""
    try:
        ip = requests.get('https://api.ipify.org', timeout=5).text
        return {"public_ip": ip}
    except requests.RequestException:
        return {"error": "Unable to retrieve IP address"}


@app.get("/health", status_code=200)
async def health_check():
    """Health check endpoint that returns server status."""
    return {"status": "healthy"}
