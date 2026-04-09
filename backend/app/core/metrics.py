from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

REQUEST_COUNT = Counter(
    "blogsnap_http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status_code"],
)

REQUEST_DURATION = Histogram(
    "blogsnap_http_request_duration_seconds",
    "HTTP request duration seconds",
    ["method", "path"],
)

JOB_PROCESSED = Counter(
    "blogsnap_jobs_processed_total",
    "Total processed jobs by type and outcome",
    ["job_type", "outcome"],
)


def metrics_response() -> tuple[bytes, str]:
    return generate_latest(), CONTENT_TYPE_LATEST
