param(
  [Parameter(ValueFromPipeline = $true)]
  [AllowEmptyString()]
  [string]$Text = '',
  [string]$Path = ''
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
  if ($Path -and $chunks.Count -gt 0) { throw 'Use either pipeline text or -Path, not both.' }
  if ($Path) {
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $draft = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8
  } else {
    $draft = $chunks -join "`n"
  }
  if ([string]::IsNullOrWhiteSpace($draft)) { throw 'Training handoff draft is empty.' }

  $headingPattern = '^\s{0,3}(#{1,6})\s+(.+?)\s*$'
  $plainBoundaryHeadingPattern = '^\s*(?:\u3010|\[)?(?<heading>(?:\u5f53\u524d)?\u6267\u884c\u8fb9\u754c|\u6682\u7f13(?:\u4e0e|\u548c)?\u6392\u9664|\u6682\u7f13|\u6392\u9664)(?:\u3011|\])?\s*[:\uFF1A]?\s*$'
  $deferralHeadingPattern = '(?i)(?:\u6682\u7f13|\u6392\u9664|defer|exclu)'
  $executionHeadingPattern = '(?i)(?:\u6267\u884c\u8fb9\u754c|execution\s+boundary)'
  $noGenerationPattern = '(?i)(?:(?:\u672c\u8f6e|\u5f53\u524d).{0,16}\u4e0d\u751f\u6210|do\s+not\s+generate|no\s+files?)'
  $confirmedDeferralPattern = '(?i)(?:\u5df2\u786e\u8ba4\u6682\u7f13|confirmed\s+defer)'
  $failures = [System.Collections.Generic.List[string]]::new()
  $currentHeading = ''
  $sawNoGeneration = $false
  $sawExecutionBoundary = $false

  foreach ($line in ($draft -split "`r?`n")) {
    if ($line -match $headingPattern) {
      $currentHeading = $Matches[2]
      continue
    }
    if ($line -match $plainBoundaryHeadingPattern) {
      $currentHeading = $Matches['heading']
      continue
    }
    if ($line -notmatch $noGenerationPattern) { continue }

    $sawNoGeneration = $true
    if ($line -match $confirmedDeferralPattern) {
      $failures.Add('Current no-generation instruction was classified as confirmed curriculum deferral.') | Out-Null
    }
    if ($currentHeading -match $deferralHeadingPattern) {
      $failures.Add('Current no-generation instruction appears under a deferral or exclusion heading.') | Out-Null
    }
    if ($currentHeading -match $executionHeadingPattern) {
      $sawExecutionBoundary = $true
    } else {
      $failures.Add('Current no-generation instruction must appear only in its own execution-boundary section.') | Out-Null
    }
  }

  if ($sawNoGeneration -and -not $sawExecutionBoundary) {
    $failures.Add('No valid execution-boundary section contains the current no-generation instruction.') | Out-Null
  }
  if ($failures.Count -gt 0) {
    $unique = @($failures | Select-Object -Unique)
    'Training handoff lint: FAIL'
    foreach ($failure in $unique) { "- $failure" }
    exit 1
  }

  'Training handoff lint: PASS'
}
