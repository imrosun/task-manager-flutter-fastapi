from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional
from models import StatusEnum

class TaskBase(BaseModel):
    title: str = Field(..., min_length=1)
    description: str = Field(..., min_length=1)
    due_date: datetime
    status: StatusEnum
    blocked_by_id: Optional[int] = None

class TaskCreate(TaskBase):
    pass

class TaskUpdate(TaskBase):
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    status: Optional[StatusEnum] = None
    blocked_by_id: Optional[int] = None

class TaskResponse(TaskBase):
    id: int

    model_config = ConfigDict(from_attributes=True)
