"""add user roles and volunteer assignment fields

Revision ID: 0002
Revises: 0001
Create Date: 2026-06-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("role", sa.String(length=50), nullable=False, server_default="user"),
    )
    op.create_index(op.f("ix_users_role"), "users", ["role"], unique=False)

    op.add_column(
        "accidents",
        sa.Column("assigned_volunteer_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.add_column(
        "accidents",
        sa.Column("volunteer_status", sa.String(length=50), nullable=False, server_default="searching"),
    )
    op.create_foreign_key(
        "fk_accidents_assigned_volunteer_id_volunteers",
        "accidents",
        "volunteers",
        ["assigned_volunteer_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_accidents_assigned_volunteer_id_volunteers",
        "accidents",
        type_="foreignkey",
    )
    op.drop_column("accidents", "volunteer_status")
    op.drop_column("accidents", "assigned_volunteer_id")
    op.drop_index(op.f("ix_users_role"), table_name="users")
    op.drop_column("users", "role")