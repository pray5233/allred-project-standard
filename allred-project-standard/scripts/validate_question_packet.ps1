param(
  [Parameter(ValueFromPipeline = $true)]
  [AllowEmptyString()]
  [string]$Text = '',
  [string]$Path = '',
  [ValidateSet('generic', 'decision-frontier', 'training', 'shared-collaboration', 'inspection-discovery')]
  [string]$Profile = 'generic',
  [string]$StatePath = '',
  [string[]]$QuestionIds = @(),
  [ValidateSet('auto', 'new', 'existing')]
  [string]$WorkKind = 'auto',
  [switch]$AllowCompletedBaselineReview,
  [switch]$AllowFutureFormatDecision,
  [switch]$PassThrough,
  [switch]$AsJson
)

begin {
  $ErrorActionPreference = 'Stop'
  $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
  [Console]::OutputEncoding = $OutputEncoding
  $chunks = [System.Collections.Generic.List[string]]::new()
}
process {
  if (-not [string]::IsNullOrEmpty($Text)) { $chunks.Add($Text) | Out-Null }
}
end {
  # Windows PowerShell -File can skip process for an explicitly bound Text value.
  if ($chunks.Count -eq 0 -and -not [string]::IsNullOrEmpty($Text)) { $chunks.Add($Text) | Out-Null }
  if ($Path -and $chunks.Count -gt 0) { throw 'Use either pipeline text or -Path, not both.' }
  $draft = if ($Path) { Get-Content -LiteralPath $Path -Raw -Encoding UTF8 } else { $chunks -join [Environment]::NewLine }
  if ([string]::IsNullOrWhiteSpace($draft)) { throw 'Question packet draft is empty.' }
  $lines = @($draft -split '\r?\n')
  # PowerShell -File transports a comma-separated ID list as one string.
  $QuestionIds = @($QuestionIds | ForEach-Object { $_ -split ',' | ForEach-Object { $_.Trim() } })
  $failures = [System.Collections.Generic.List[string]]::new()
  $warnings = [System.Collections.Generic.List[string]]::new()
  $ids = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($match in [regex]::Matches($draft, '(?i)(?<![A-Za-z0-9_])(?:Q|D)[0-9][0-9A-Za-z._-]*(?![A-Za-z0-9_])')) { $ids.Add($match.Value.TrimEnd('.')) | Out-Null }
  $heads = @($lines | Where-Object {
    $_ -match '(?i)^\s*(?:[-*]\s+)?(?:\*\*)?(?:\x60)?[QD][0-9][0-9A-Za-z._-]*(?:\x60)?(?:\*\*)?[.:\uFF1A\u3001\s]' -or
    $_ -match '^\s*[1-9][0-9]*[.)\u3001]\s*.*[?\uFF1F]' -or
    $_ -match '^\s*[1-9][0-9]*[.)\u3001]\s*\*\*[^*]+\*\*' -or
    $_ -match '^\s*[-*]\s+.*[?\uFF1F]'
  })
  $count = [Math]::Max($heads.Count, $ids.Count)
  if ($count -eq 0) { $count = [regex]::Matches($draft, '[?\uFF1F]').Count }
  if ($count -eq 0 -and $draft -match '(?i)(?:\u8bf7\u786e\u8ba4|\u8bf7\u9009\u62e9|\u8bf7\u8bf4\u660e|please confirm|please choose)') { $count = 1 }
  # Text heuristics flag review points; they cannot judge meaning or response burden.
  if ($count -eq 0) { $warnings.Add('No explicit question marker found; check that the requested reply is clear.') | Out-Null }
  if ($count -gt 4) { $warnings.Add("Estimated $count question blocks; check whether this is a manageable group or should be split.") | Out-Null }
  if (@($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count -gt 18) {
    $warnings.Add('More than 18 non-empty lines; check for repetition and unnecessary detail.') | Out-Null
  }
  if ($draft.Trim().Length -gt 1800) { $warnings.Add('More than 1800 visible characters; check reading burden without dropping decision-critical context.') | Out-Null }
  $replyLines = @($lines | Where-Object { $_ -match '(?i)(?:^\s*(?:\u56de\u590d|reply)\s*[:\uFF1A]|(?:\u76f4\u63a5|\u53ef\u4ee5).{0,60}(?:\u56de\u7b54|\u56de\u590d))' })
  if ($replyLines.Count -gt 1) { $warnings.Add('Multiple reply instructions detected; consolidate if redundant.') | Out-Null }
  if ($draft -match '(?im)^\s*(?:dependency|approval_source|state_id|recommendation_basis)\s*[:\uFF1A]') {
    $warnings.Add('Internal ledger fields detected; explain their consequence in ordinary language when relevant.') | Out-Null
  }
  foreach ($line in $lines) {
    if ($line -match '(?i)(?:\u540e\u7eed|\u5269\u4f59|\u4ecd\u6709|\u8fd8\u6709|queued).{0,30}[0-9]+.{0,12}(?:\u9879|\u95ee\u9898|items?|nodes?)' -and
        $line -match '(?i)(?:\u5df2\u786e\u8ba4|\u9ed8\u8ba4|\u6682\u7f13|\u6392\u9664|\u4e0d\u505a|approve|exclude|defer)') {
      $warnings.Add('Possible queue disposition claim; check its actual user authority in context.') | Out-Null
    }
  }

  $guardSummary = 'Decision packet guard: NOT RUN (unbound readability check).'
  $guard = [ordered]@{status='not_run'; scope=$null}
  $stateHash = $null
  $selected = @()
  # A Q/D label cannot establish semantics. Every bound packet uses the current gate.
  if ($QuestionIds.Count -gt 0 -and -not $StatePath) { $failures.Add('QuestionIds requires StatePath.') | Out-Null }
  if ($StatePath) {
    . (Join-Path $PSScriptRoot 'state_validation_common.ps1')
    $StatePath = (Resolve-Path -LiteralPath $StatePath).Path
    $stateHash = (Get-FileHash -LiteralPath $StatePath -Algorithm SHA256).Hash
    $state = Read-AllredProjectState -Path $StatePath
    $selected = @(if ($QuestionIds.Count -gt 0) { $QuestionIds } else { $ids })
    if ($selected.Count -eq 0) { $failures.Add('State-bound questions require QuestionIds; keep those IDs internal if preferred.') | Out-Null }
    if (@($selected | Select-Object -Unique).Count -ne $selected.Count) { $failures.Add('Selected question IDs must be unique.') | Out-Null }
    foreach ($visibleId in $ids) {
      if ($visibleId -notin $selected) { $failures.Add("Visible question is outside the selected state slice: $visibleId") | Out-Null }
    }
    if ($count -gt $selected.Count) { $warnings.Add('Estimated visible blocks exceed selected IDs; check the question-to-state mapping in context.') | Out-Null }
    $nodes = @{}
    foreach ($ledger in @('decisions', 'questions')) {
      $prefix = if ($ledger -eq 'decisions') { 'D' } else { 'Q' }
      foreach ($node in @(Get-AllredArray (Get-AllredProperty $state $ledger))) {
        $nodeId = [string](Get-AllredProperty $node 'id')
        if ($nodeId -notmatch "^${prefix}[0-9A-Za-z._-]+$") { $failures.Add("Invalid $ledger ID: $nodeId") | Out-Null }
        if ([string]::IsNullOrWhiteSpace($nodeId) -or $nodes.ContainsKey($nodeId)) { $failures.Add('State question and decision IDs must be non-empty and unique.') | Out-Null }
        $nodes[$nodeId] = $node
      }
    }
    foreach ($id in $selected) {
      if (-not $nodes.ContainsKey($id)) { $failures.Add("Question is not in current state: $id") | Out-Null; continue }
      $node = $nodes[$id]
      if (([string](Get-AllredProperty $node 'status')).ToLowerInvariant() -notin @('open', 'proposed', 'conflict')) {
        $failures.Add("Question is settled or waiting and must not be re-asked: $id") | Out-Null
      }
      foreach ($dependency in @(Get-AllredArray (Get-AllredProperty $node 'depends_on'))) {
        $parentId = [string](Get-AllredProperty $dependency 'id')
        $parent = $nodes[$parentId]
        if ($null -eq $parent -or (Get-AllredProperty $parent 'status') -ne 'confirmed' -or
            (Get-AllredProperty $parent 'choice') -notin @(Get-AllredArray (Get-AllredProperty $dependency 'choices'))) {
          $failures.Add("Question dependency is not settled: $id -> $parentId") | Out-Null
        }
      }
    }
    if ($failures.Count -eq 0) {
      $route = [string](Get-AllredProperty $state 'route')
      $newRoutes = @('new-standard', 'new-public')
      $knownRoutes = $newRoutes + @('non-software', 'existing-debug', 'existing-feature', 'existing-ui', 'long-term')
      $effectiveKind = if ($WorkKind -ne 'auto') { $WorkKind } elseif ($route -in ($newRoutes + @('non-software'))) { 'new' } else { 'existing' }
      if ($route -notin $knownRoutes) { $failures.Add("Unknown state route: $route") | Out-Null }
      if ($route -in $newRoutes -and $effectiveKind -ne 'new') { $failures.Add('A new-project route cannot use WorkKind existing.') | Out-Null }
      if ($failures.Count -eq 0) {
        $validator = if ($effectiveKind -eq 'new') { 'invoke_validation_gate.ps1' } else { 'validate_decision_frontier.ps1' }
        $arguments = @('-Path', $StatePath)
        if ($effectiveKind -eq 'new') { $arguments += @('-ToStage', 'DECISION') }
        $previousErrorAction = $ErrorActionPreference
        $guard.scope = if ($effectiveKind -eq 'new') { 'new-project-decision' } else { 'existing-work-frontier' }
        try {
          $ErrorActionPreference = 'Continue'
          $validationOutput = @(& (Get-Process -Id $PID).Path -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $validator) @arguments 2>&1 | ForEach-Object { [string]$_ })
          $validationExit = $LASTEXITCODE
        } finally { $ErrorActionPreference = $previousErrorAction }
        if ($validationExit -ne 0) {
          $guard.status = 'failed'
          $failures.Add("Product decision packet blocked by ${validator}: $($validationOutput -join [Environment]::NewLine)") | Out-Null
        } else {
          $guard.status = 'passed'
          $guardSummary = if ($effectiveKind -eq 'new') { 'Decision packet guard: PASS (actual DECISION aggregate; current state).' } else { 'Decision packet guard: PASS (existing-work frontier only; no new-project intake).' }
        }
      }
    }
    if ((Get-FileHash -LiteralPath $StatePath -Algorithm SHA256).Hash -ne $stateHash) {
      $failures.Add('State changed during packet validation; rerun on the current snapshot.') | Out-Null
    }
  }
  if ($AsJson) {
    $passed = $failures.Count -eq 0
    $hasher = [Security.Cryptography.SHA256]::Create()
    try { $packetHash = [BitConverter]::ToString($hasher.ComputeHash($OutputEncoding.GetBytes($draft))).Replace('-','') }
    finally { $hasher.Dispose() }
    [ordered]@{
      schema_version = 1
      status = $(if ($passed) { 'passed' } else { 'blocked' })
      decision_guard = $guard
      input = [ordered]@{state_path=$(if ($StatePath) { $StatePath } else { $null }); state_sha256=$stateHash; packet_sha256=$packetHash; question_ids=@($selected)}
      errors = @($failures | Select-Object -Unique)
      warnings = @($warnings | Select-Object -Unique)
      semantic_validation = 'not_performed'
      next_action = $(if (-not $passed) { 'repair_input' } elseif ($warnings.Count) { 'review_presentation' } else { 'present_questions' })
      # PS5.1 otherwise serializes Get-Content's filesystem metadata with the string.
      questions_text = $(if ($passed) { $draft.ToString() } else { $null })
      execution_authorized = $false
    } | ConvertTo-Json -Depth 8
    if (-not $passed) { exit 1 }
    return
  }
  if ($failures.Count -gt 0) {
    'Question packet lint: FAIL'
    foreach ($failure in @($failures | Select-Object -Unique)) { "- $failure" }
    exit 1
  }
  "Question packet lint: PASS ($count question blocks; profile $Profile)"
  $guardSummary
  'Validation scope: the guard above reports the decision check actually run. Neither readability nor that guard establishes complete discovery, READY, or execution authorization.'
  'Semantic validation: NOT PERFORMED. Codex judges meaning and presentation from the conversation.'
  foreach ($warning in @($warnings | Select-Object -Unique)) { "Advisory: $warning" }
  if ($PassThrough) {
    '---BEGIN LINTED QUESTION PACKET---'
    $draft
    '---END LINTED QUESTION PACKET---'
  }
}
