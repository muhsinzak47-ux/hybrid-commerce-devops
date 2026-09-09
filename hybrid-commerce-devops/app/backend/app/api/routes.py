from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import select
from app.database import get_db
from app.models.user import User
from app.models.models import Product as ProductModel, Cart as CartModel, CartItem as CartItemModel, Order as OrderModel, OrderItem as OrderItemModel
from app.schemas.schemas import (
    Product as ProductSchema, ProductCreate, ProductUpdate,
    Cart as CartSchema, CartItem as CartItemSchema, CartItemCreate, CartItemUpdate,
    Order as OrderSchema, OrderCreate, OrderStatusUpdate,
    UserResponse, Token, UserCreate, UserLogin,
)
from app.services.auth import verify_password, get_password_hash, create_access_token, verify_token
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from datetime import datetime, timezone
import uuid

security = HTTPBearer()
router = APIRouter()


def _get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    token_data = verify_token(credentials.credentials)
    if token_data is None or token_data.user_id is None:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    user = db.execute(select(User).where(User.id == token_data.user_id)).scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user


def _get_admin_user(current_user: User = Depends(_get_current_user)) -> User:
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user


def _get_or_create_cart(db: Session, user: User) -> CartModel:
    cart = db.execute(select(CartModel).where(CartModel.user_id == user.id)).scalar_one_or_none()
    if cart is None:
        cart = CartModel(user_id=user.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    return cart


# ─── Auth ──────────────────────────────────────────────────────────────────────

@router.post("/auth/register", response_model=UserResponse, status_code=201)
def register(body: UserCreate, db: Session = Depends(get_db)):
    if db.execute(select(User).where(User.email == body.email)).scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Email already registered")
    user = User(
        email=body.email,
        password_hash=get_password_hash(body.password),
        full_name=body.full_name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/auth/login", response_model=Token)
def login(body: UserLogin, db: Session = Depends(get_db)):
    user = db.execute(select(User).where(User.email == body.email)).scalar_one_or_none()
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    token = create_access_token(data={"sub": str(user.id)})
    return Token(access_token=token)


@router.get("/auth/me", response_model=UserResponse)
def me(current_user: User = Depends(_get_current_user)):
    return current_user


# ─── Products ──────────────────────────────────────────────────────────────────

@router.get("/products", response_model=list[ProductSchema])
def list_products(
    db: Session = Depends(get_db),
    search: str | None = Query(None),
    min_price: float | None = Query(None, gt=0),
    max_price: float | None = Query(None, gt=0),
    in_stock: bool | None = Query(None),
    limit: int = Query(50, ge=1, le=100),
):
    q = select(ProductModel)
    if search:
        q = q.where(ProductModel.name.ilike(f"%{search}%"))
    if min_price is not None:
        q = q.where(ProductModel.price >= min_price)
    if max_price is not None:
        q = q.where(ProductModel.price <= max_price)
    if in_stock is True:
        q = q.where(ProductModel.stock_quantity > 0)
    q = q.limit(limit)
    return list(db.execute(q).scalars().all())


@router.get("/products/{product_id}", response_model=ProductSchema)
def get_product(product_id: uuid.UUID, db: Session = Depends(get_db)):
    product = db.execute(select(ProductModel).where(ProductModel.id == product_id)).scalar_one_or_none()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product


@router.post("/products", response_model=ProductSchema, status_code=201)
def create_product(
    body: ProductCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(_get_admin_user),
):
    product = ProductModel(**body.model_dump())
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


@router.put("/products/{product_id}", response_model=ProductSchema)
def update_product(
    product_id: uuid.UUID,
    body: ProductUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(_get_admin_user),
):
    product = db.execute(select(ProductModel).where(ProductModel.id == product_id)).scalar_one_or_none()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(product, k, v)
    db.commit()
    db.refresh(product)
    return product


@router.delete("/products/{product_id}", status_code=204)
def delete_product(
    product_id: uuid.UUID,
    db: Session = Depends(get_db),
    admin: User = Depends(_get_admin_user),
):
    product = db.execute(select(ProductModel).where(ProductModel.id == product_id)).scalar_one_or_none()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    db.delete(product)
    db.commit()


# ─── Cart ──────────────────────────────────────────────────────────────────────

@router.get("/cart", response_model=CartSchema)
def get_cart(current_user: User = Depends(_get_current_user), db: Session = Depends(get_db)):
    cart = _get_or_create_cart(db, current_user)
    items = db.execute(
        select(CartItemModel).where(CartItemModel.cart_id == cart.id)
    ).scalars().all()
    return CartSchema(id=cart.id, items=items)


@router.post("/cart/items", response_model=CartItemSchema, status_code=201)
def add_to_cart(
    body: CartItemCreate,
    current_user: User = Depends(_get_current_user),
    db: Session = Depends(get_db),
):
    cart = _get_or_create_cart(db, current_user)
    product = db.execute(select(ProductModel).where(ProductModel.id == body.product_id)).scalar_one_or_none()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    if product.stock_quantity < body.quantity:
        raise HTTPException(status_code=400, detail="Not enough stock")
    existing = db.execute(
        select(CartItemModel).where(CartItemModel.cart_id == cart.id, CartItemModel.product_id == body.product_id)
    ).scalar_one_or_none()
    if existing:
        existing.quantity += body.quantity
        db.commit()
        db.refresh(existing)
        return existing
    item = CartItemModel(cart_id=cart.id, product_id=body.product_id, quantity=body.quantity)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.put("/cart/items/{item_id}", response_model=CartItemSchema)
def update_cart_item(
    item_id: uuid.UUID,
    body: CartItemUpdate,
    current_user: User = Depends(_get_current_user),
    db: Session = Depends(get_db),
):
    cart = _get_or_create_cart(db, current_user)
    item = db.execute(
        select(CartItemModel).where(CartItemModel.id == item_id, CartItemModel.cart_id == cart.id)
    ).scalar_one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Cart item not found")
    item.quantity = body.quantity
    db.commit()
    db.refresh(item)
    return item


@router.delete("/cart/items/{item_id}", status_code=204)
def remove_cart_item(
    item_id: uuid.UUID,
    current_user: User = Depends(_get_current_user),
    db: Session = Depends(get_db),
):
    cart = _get_or_create_cart(db, current_user)
    item = db.execute(
        select(CartItemModel).where(CartItemModel.id == item_id, CartItemModel.cart_id == cart.id)
    ).scalar_one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Cart item not found")
    db.delete(item)
    db.commit()


# ─── Orders ────────────────────────────────────────────────────────────────────

@router.post("/orders", response_model=OrderSchema, status_code=201)
def place_order(
    body: OrderCreate,
    current_user: User = Depends(_get_current_user),
    db: Session = Depends(get_db),
):
    cart = _get_or_create_cart(db, current_user)
    items = db.execute(select(CartItemModel).where(CartItemModel.cart_id == cart.id)).scalars().all()
    if not items:
        raise HTTPException(status_code=400, detail="Cart is empty")

    total = 0.0
    order = OrderModel(
        user_id=current_user.id,
        status="PENDING",
        total_amount=0,
        shipping_name=body.shipping_name,
        shipping_address=body.shipping_address,
        shipping_city=body.shipping_city,
    )
    db.add(order)
    db.flush()

    for item in items:
        product = db.execute(
            select(ProductModel).where(ProductModel.id == item.product_id)
        ).scalar_one()
        if product.stock_quantity < item.quantity:
            raise HTTPException(
                status_code=400,
                detail=f"Not enough stock for {product.name}",
            )
        product.stock_quantity -= item.quantity
        oi = OrderItemModel(
            order_id=order.id,
            product_id=item.product_id,
            quantity=item.quantity,
            unit_price=float(product.price),
        )
        db.add(oi)
        total += float(product.price) * item.quantity

    order.total_amount = total
    for item in db.execute(select(CartItemModel).where(CartItemModel.cart_id == cart.id)).scalars().all():
        db.delete(item)
    db.commit()
    db.refresh(order)

    order_items = db.execute(
        select(OrderItemModel).where(OrderItemModel.order_id == order.id)
    ).scalars().all()
    order.items = [
        {"product_id": i.product_id, "quantity": i.quantity, "unit_price": float(i.unit_price)}
        for i in order_items
    ]
    return order


@router.get("/orders", response_model=list[OrderSchema])
def list_orders(current_user: User = Depends(_get_current_user), db: Session = Depends(get_db)):
    orders = db.execute(
        select(OrderModel)
        .where(OrderModel.user_id == current_user.id)
        .order_by(OrderModel.created_at.desc())
    ).scalars().all()
    for order in orders:
        ois = db.execute(
            select(OrderItemModel).where(OrderItemModel.order_id == order.id)
        ).scalars().all()
        order.items = [
            {"product_id": i.product_id, "quantity": i.quantity, "unit_price": float(i.unit_price)}
            for i in ois
        ]
    return orders


@router.get("/orders/{order_id}", response_model=OrderSchema)
def get_order(order_id: uuid.UUID, current_user: User = Depends(_get_current_user), db: Session = Depends(get_db)):
    order = db.execute(
        select(OrderModel).where(OrderModel.id == order_id, OrderModel.user_id == current_user.id)
    ).scalar_one_or_none()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    ois = db.execute(
        select(OrderItemModel).where(OrderItemModel.order_id == order.id)
    ).scalars().all()
    order.items = [
        {"product_id": i.product_id, "quantity": i.quantity, "unit_price": float(i.unit_price)}
        for i in ois
    ]
    return order


@router.put("/orders/{order_id}/status", response_model=OrderSchema)
def update_order_status(
    order_id: uuid.UUID,
    body: OrderStatusUpdate,
    admin: User = Depends(_get_admin_user),
    db: Session = Depends(get_db),
):
    order = db.execute(select(OrderModel).where(OrderModel.id == order_id)).scalar_one_or_none()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    valid_transitions = {
        "PENDING": ["CONFIRMED", "CANCELLED"],
        "CONFIRMED": ["PROCESSING", "CANCELLED"],
        "PROCESSING": ["OUT_FOR_DELIVERY"],
        "OUT_FOR_DELIVERY": ["DELIVERED"],
    }
    if order.status in valid_transitions:
        if body.status not in valid_transitions[order.status]:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot move from {order.status} to {body.status}",
            )
    elif order.status not in ("DELIVERED", "CANCELLED"):
        raise HTTPException(status_code=400, detail=f"Invalid current status: {order.status}")
    order.status = body.status
    order.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(order)
    ois = db.execute(
        select(OrderItemModel).where(OrderItemModel.order_id == order.id)
    ).scalars().all()
    order.items = [
        {"product_id": i.product_id, "quantity": i.quantity, "unit_price": float(i.unit_price)}
        for i in ois
    ]
    return order


@router.get("/admin/orders", response_model=list[OrderSchema])
def admin_list_orders(
    status_filter: str | None = Query(None),
    db: Session = Depends(get_db),
    admin: User = Depends(_get_admin_user),
):
    q = select(OrderModel).order_by(OrderModel.created_at.desc())
    if status_filter:
        q = q.where(OrderModel.status == status_filter)
    orders = db.execute(q).scalars().all()
    for order in orders:
        ois = db.execute(
            select(OrderItemModel).where(OrderItemModel.order_id == order.id)
        ).scalars().all()
        order.items = [
            {"product_id": i.product_id, "quantity": i.quantity, "unit_price": float(i.unit_price)}
            for i in ois
        ]
    return orders


@router.get("/admin/dashboard")
def admin_dashboard(db: Session = Depends(get_db), admin: User = Depends(_get_admin_user)):
    total_products = db.execute(select(ProductModel)).scalars().all()
    total_orders = db.execute(select(OrderModel)).scalars().all()
    pending_orders = db.execute(
        select(OrderModel).where(OrderModel.status == "PENDING")
    ).scalars().all()
    low_stock = db.execute(
        select(ProductModel).where(ProductModel.stock_quantity < 5)
    ).scalars().all()
    total_revenue = sum(float(o.total_amount) for o in total_orders if o.status == "DELIVERED")
    return {
        "total_products": len(total_products),
        "total_orders": len(total_orders),
        "pending_orders": len(pending_orders),
        "low_stock_products": len(low_stock),
        "total_revenue": total_revenue,
    }
