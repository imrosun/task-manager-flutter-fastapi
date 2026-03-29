from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
import enum
from database import Base

class StatusEnum(str, enum.Enum):
    TODO = "To-Do"
    IN_PROGRESS = "In-Progress"
    DONE = "Done"

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    due_date = Column(DateTime)
    status = Column(String, default=StatusEnum.TODO.value)
    blocked_by_id = Column(Integer, ForeignKey("tasks.id"), nullable=True)
