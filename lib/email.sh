#!/bin/bash
# Email delivery module for proxmox-autoshutdown

set -Eeuo pipefail

################################################################################
# Sendmail Wrapper
################################################################################

send_html_email() {
  if ((PROXMOX_AS_DRY_RUN)); then
    log_info "DRY-RUN: Would send email to $PROXMOX_AS_MAIL_TO"
    return 0
  fi

  if [[ -z "$PROXMOX_AS_MAIL_TO" ]]; then
    log_warn "MAIL_TO not set - skipping email transmission"
    return 1
  fi

  if ! command -v sendmail >/dev/null 2>&1; then
    log_error "sendmail not found. Install msmtp-mta or postfix."
    return 1
  fi

  local subject
  subject="${PROXMOX_AS_MAIL_SUBJECT_PREFIX} - $(hostname) - $(date '+%Y-%m-%d %H:%M')"

  log_info "Sending HTML report to $PROXMOX_AS_MAIL_TO"

  if ! _email_send_message "$subject"; then
    log_error "Failed to send email via sendmail"
    return 1
  fi

  log_info "Email sent successfully"
}

_email_send_message() {
  local subject="$1"
  local mail_body

  # Read the HTML report and encode properly
  if [[ ! -r "$PROXMOX_AS_HTML_REPORT" ]]; then
    log_error "Cannot read HTML report: $PROXMOX_AS_HTML_REPORT"
    return 1
  fi

  mail_body="$(cat "$PROXMOX_AS_HTML_REPORT")"

  {
    echo "To: $PROXMOX_AS_MAIL_TO"
    echo "From: $PROXMOX_AS_MAIL_FROM"
    echo "Subject: $subject"
    echo "MIME-Version: 1.0"
    echo "Content-Type: text/html; charset=UTF-8"
    echo "Content-Transfer-Encoding: 8bit"
    echo
    echo "$mail_body"
  } | sendmail -t >>"$PROXMOX_AS_LOG_FILE" 2>&1
}

# Verify email configuration
email_verify_config() {
  local warnings=0

  if [[ -z "$PROXMOX_AS_MAIL_TO" ]]; then
    log_warn "MAIL_TO is not set - email will not be sent"
    warnings=$((warnings + 1))
  fi

  if ! command -v sendmail >/dev/null 2>&1; then
    log_warn "sendmail not found - email will not be sent"
    log_warn "Install msmtp-mta or postfix for email support"
    warnings=$((warnings + 1))
  fi

  return $warnings
}
