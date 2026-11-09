-- Keep audit_trackguard_report_status as the single
-- authoritative audit trigger for report status changes.

DROP TRIGGER IF EXISTS report_status_change_audit
ON public.reports;
