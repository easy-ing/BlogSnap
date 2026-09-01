import base64
import hashlib

from cryptography.fernet import Fernet, InvalidToken

from backend.app.core.config import settings


def _fernet() -> Fernet:
    # Derive a Fernet-compatible key from AUTH_SECRET_KEY rather than requiring
    # a second secret to configure. Namespaced so it never collides with JWT signing.
    digest = hashlib.sha256(f"{settings.auth_secret_key}:user-secret-encryption".encode()).digest()
    return Fernet(base64.urlsafe_b64encode(digest))


def encrypt_secret(raw_value: str) -> str:
    return _fernet().encrypt(raw_value.encode()).decode()


def decrypt_secret(encrypted_value: str) -> str:
    try:
        return _fernet().decrypt(encrypted_value.encode()).decode()
    except InvalidToken as exc:
        raise ValueError("Stored secret could not be decrypted (key rotated or corrupted).") from exc
