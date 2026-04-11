from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class NotificationCreate(BaseModel):
    title: str
    message: str
    notification_type: str


class NotificationResponse(BaseModel):
    id: int
    user_id: Optional[int]
    workshop_id: Optional[int]
    title: str
    message: str
    notification_type: str
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}
