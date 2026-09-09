import uuid
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict


class ProductBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: str | None = None
    price: float = Field(..., gt=0)
    stock_quantity: int = Field(0, ge=0)
    image_url: str | None = None


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)
    description: str | None = None
    price: float | None = Field(None, gt=0)
    stock_quantity: int | None = Field(None, ge=0)
    image_url: str | None = None


class Product(ProductBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    created_at: datetime


class CartItemBase(BaseModel):
    product_id: uuid.UUID
    quantity: int = Field(1, ge=1)


class CartItemCreate(CartItemBase):
    pass


class CartItemUpdate(BaseModel):
    quantity: int = Field(1, ge=1)


class CartItem(CartItemBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID


class Cart(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    items: list[CartItem] = []


class OrderCreate(BaseModel):
    shipping_name: str = Field(..., min_length=1, max_length=255)
    shipping_address: str = Field(..., min_length=1, max_length=512)
    shipping_city: str = Field(..., min_length=1, max_length=100)


class OrderStatusUpdate(BaseModel):
    status: str = Field(
        ...,
        pattern="^(PENDING|CONFIRMED|PROCESSING|OUT_FOR_DELIVERY|DELIVERED|CANCELLED)$",
    )


class Order(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    status: str
    total_amount: float
    shipping_name: str | None
    shipping_address: str | None
    shipping_city: str | None
    created_at: datetime
    items: list[dict] = []


class UserCreate(BaseModel):
    email: str = Field(..., min_length=3, max_length=255)
    password: str = Field(..., min_length=6, max_length=128)
    full_name: str | None = Field(None, max_length=255)


class UserLogin(BaseModel):
    email: str
    password: str


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    email: str
    full_name: str | None
    is_admin: bool


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    user_id: uuid.UUID | None = None
