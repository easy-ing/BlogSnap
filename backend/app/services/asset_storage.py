from pathlib import Path
from typing import Optional


UPLOAD_ROOT = Path("tmp/uploads")

_EXTENSION_BY_CONTENT_TYPE = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}


def extension_for(content_type: str) -> str:
    return _EXTENSION_BY_CONTENT_TYPE.get(content_type, ".bin")


def resolve_upload_path(storage_key: str) -> Optional[Path]:
    # storage_key comes from the DB; rows written before filenames were stripped from
    # keys may contain "../", so never touch a path that escapes UPLOAD_ROOT.
    root = UPLOAD_ROOT.resolve()
    path = (UPLOAD_ROOT / storage_key).resolve()
    if not path.is_relative_to(root) or path == root:
        return None
    return path
