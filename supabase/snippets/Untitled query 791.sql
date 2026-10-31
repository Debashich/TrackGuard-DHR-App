SELECT request_id, user_id, status, http_status,
       error_code, duration_ms, created_at
FROM public.ai_usage_logs
ORDER BY created_at DESC
LIMIT 5;