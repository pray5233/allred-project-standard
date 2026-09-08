param(
  [Parameter(Mandatory=$true)][string]$StatePath,
  [Parameter(Mandatory=$true)][string]$QuestionPath,
  [Parameter(Mandatory=$true)][string]$ReplyPath
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
. (Join-Path $PSScriptRoot 'state_validation_common.ps1')
. (Join-Path $PSScriptRoot 'answer_context_common.ps1')
$context = Read-AllredAnswerContext -StatePath $StatePath -QuestionPath $QuestionPath -ReplyPath $ReplyPath
$context | Add-Member -NotePropertyName next_step -NotePropertyValue 'First decide the answer_map: binding, confirmed [{id, choice}], and pending [all other unresolved D IDs]. Explicit retirement/replacement uses optional resolved [{id, status, reason, superseded_by when replacing}]; exclude those IDs from pending. Then use that same map in update_project_state.ps1 PatchPath; do not retype mapped changes in upsert.decisions. The updater stores the complete reply as source_id. New facts, requirements and questions use ordinary upserts; a new topic needs a new ID. This preparation neither writes state nor validates meaning or authorization.'
$context | ConvertTo-Json -Depth 60
