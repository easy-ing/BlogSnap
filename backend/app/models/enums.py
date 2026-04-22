from enum import Enum


class PostType(str, Enum):
    review = "review"
    explanation = "explanation"
    impression = "impression"


class JobType(str, Enum):
    draft_generate = "draft_generate"
    draft_regenerate = "draft_regenerate"
    publish = "publish"


class JobStatus(str, Enum):
    PENDING = "PENDING"
    RUNNING = "RUNNING"
    SUCCEEDED = "SUCCEEDED"
    FAILED = "FAILED"
    RETRYING = "RETRYING"


class DraftStatus(str, Enum):
    GENERATED = "GENERATED"
    SELECTED = "SELECTED"
    ARCHIVED = "ARCHIVED"


class PublishStatus(str, Enum):
    REQUESTED = "REQUESTED"
    PUBLISHED = "PUBLISHED"
    ERROR = "ERROR"


class ProviderType(str, Enum):
    wordpress = "wordpress"
    tistory = "tistory"
