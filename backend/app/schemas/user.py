from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    name: str
    email: EmailStr
    phone: str
    role: str = "user"
    fcm_token: Optional[str] = None


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    role: Optional[str] = None
    fcm_token: Optional[str] = None
    password: Optional[str] = None


class UserResponse(UserBase):
    id: UUID
    created_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    sub: Optional[str] = None
    type: Optional[str] = None


class DeviceTokenUpdate(BaseModel):
    fcm_token: str


class LoginRequest(BaseModel):
    email_or_phone: str
    password: str
    fcm_token: Optional[str] = None


class RefreshTokenRequest(BaseModel):
    refresh_token: str
