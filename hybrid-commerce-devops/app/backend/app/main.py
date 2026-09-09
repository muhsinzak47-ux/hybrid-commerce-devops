import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles

from app.config import get_settings
from app.database import engine, Base
from app.api.routes import router as api_router

settings = get_settings()
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Create DB tables on startup
Base.metadata.create_all(bind=engine)

app = FastAPI(title=settings.app_name, version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api")

app.mount("/static", StaticFiles(directory=os.path.join(BASE_DIR, "static")), name="static")
templates = Jinja2Templates(directory=os.path.join(BASE_DIR, "templates"))


@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.get("/products", response_class=HTMLResponse)
async def products_page(request: Request):
    return RedirectResponse(url="/")


@app.get("/login", response_class=HTMLResponse)
async def login_page(request: Request):
    return RedirectResponse(url="/")


@app.get("/register", response_class=HTMLResponse)
async def register_page(request: Request):
    return RedirectResponse(url="/")


@app.get("/cart", response_class=HTMLResponse)
async def cart_page(request: Request):
    return RedirectResponse(url="/")


@app.get("/orders", response_class=HTMLResponse)
async def orders_page(request: Request):
    return RedirectResponse(url="/")


@app.get("/admin", response_class=HTMLResponse)
async def admin_page(request: Request):
    return RedirectResponse(url="/")


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/api/auth/login")
async def login_endpoint(request: Request):
    """Handled by API router; this redirect is for form fallback."""
    return RedirectResponse(url="/products", status_code=303)
