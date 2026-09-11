import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, RedirectResponse, Response
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

from app.config import get_settings
from app.database import engine, Base
from app.api.routes import router as api_router

settings = get_settings()
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Create DB tables on startup
Base.metadata.create_all(bind=engine)

app = FastAPI(title=settings.app_name, version="1.0.0")

# Prometheus metrics
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status_code"],
)
REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "endpoint"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
)
INPROGRESS = Counter(
    "http_inprogress_requests",
    "HTTP requests currently being processed",
    ["method", "endpoint"],
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def prometheus_middleware(request: Request, call_next):
    method = request.method
    endpoint = request.url.path
    INPROGRESS.labels(method=method, endpoint=endpoint).inc()
    try:
        response = await call_next(request)
        status_code = response.status_code
        REQUEST_COUNT.labels(method=method, endpoint=endpoint, status_code=str(status_code)).inc()
        return response
    finally:
        INPROGRESS.labels(method=method, endpoint=endpoint).dec()


@app.get("/metrics")
async def metrics():
    return Response(generate_latest(CONTENT_TYPE_LATEST))

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
