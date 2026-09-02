param(
  [Parameter(ValueFromPipeline = $true)]
  [AllowEmptyString()]
  [string]$Text = '',
  [string]$Path = '',
  [ValidateSet('generic', 'training', 'shared-collaboration', 'inspection-discovery')]
  [string]$Profile = 'generic',
  [switch]$AllowCompletedBaselineReview,
  [switch]$AllowFutureFormatDecision,
  [switch]$PassThrough
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
  } elseif ($Profile -eq 'training') {
    $draft = $chunks -join "`n"
  }
  if ([string]::IsNullOrWhiteSpace($draft)) { throw 'Question packet draft is empty.' }

  $lines = @($draft -split "`r?`n")
  $questionPrefix = '(?i)(?:\u95ee\u9898|question)\s*[:\uFF1A]'
  $bulletQuestion = '^\s*[-*]\s+.*[?\uFF1F]'
  $impact = '(?i)(?:\u5f71\u54cd|impact|effect)\s*[:\uFF1A]'
  $reply = '(?i)(?:\u56de\u590d|reply)\s*[:\uFF1A]'
  $questionLines = [System.Collections.Generic.List[int]]::new()

  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match $questionPrefix -or $lines[$i] -match $bulletQuestion) {
      $questionLines.Add($i) | Out-Null
    }
  }

  $failures = [System.Collections.Generic.List[string]]::new()
  if ($Profile -in @('generic', 'shared-collaboration')) {
    if ($questionLines.Count -eq 0) {
      $failures.Add('No independently answerable question block was found.') | Out-Null
    }

    for ($i = 0; $i -lt $questionLines.Count; $i++) {
      $start = $questionLines[$i]
      $next = if ($i + 1 -lt $questionLines.Count) { $questionLines[$i + 1] } else { $lines.Count }
      $end = [Math]::Min($next - 1, $start + 6)
      $segment = if ($end -ge $start) { ($lines[$start..$end] -join "`n") } else { $lines[$start] }
      $lineNumber = $start + 1
      if ($segment -notmatch $impact) { $failures.Add("Question block at line $lineNumber has no adjacent impact statement.") | Out-Null }
      if ($segment -notmatch $reply) { $failures.Add("Question block at line $lineNumber has no adjacent reply guidance.") | Out-Null }
    }
    if ($Profile -eq 'shared-collaboration') {
      $futureAcceptanceAsFact = '(?im)^\s*[-*]?\s*\**Q[0-9A-Za-z_-]*[\.\s].*(?:\u6700\u7ec8\u9a8c\u6536|\u6295\u5165\u4f7f\u7528|\u9a8c\u6536\u8d23\u4efb|final\s+acceptance)'
      if ($draft -match $futureAcceptanceAsFact) {
        $failures.Add('Shared packet classifies future final-acceptance authority as current fact Q instead of user-owned D.') | Out-Null
      }
    }
  } elseif ($Profile -eq 'training') {
    if ($draft -notmatch '[?\uFF1F]' -and $draft -notmatch '(?:\u8bf7\u786e\u8ba4|\u8bf7\u9009\u62e9|\u8bf7\u8bf4\u660e)') {
      $failures.Add('Training packet has no independently answerable confirmation.') | Out-Null
    }

    $trainingFacets = @(
      @{ name = 'project-practice content-design contrast'; pattern = '(?is)(?:\u8de8\u5c97\u4f4d|\u9879\u76ee\u5b9e\u8df5|\u5c97\u4f4d\u5b9e\u8df5).{0,120}(?:\u5185\u5bb9\u8bbe\u8ba1|\u8bfe\u7a0b\u8bbe\u8ba1).{0,120}(?:\u4e0d\u662f|\u5e76\u975e|\u4e0d\u5c5e\u4e8e|\u800c\u975e).{0,40}(?:\u8f6f\u4ef6\u67b6\u6784|\u6280\u672f\u67b6\u6784)' },
      @{ name = 'audience confirmation or correction'; pattern = '(?is)(?:\u53d7\u4f17|\u5b66\u5458|\u5c97\u4f4d).{0,120}(?:\u786e\u8ba4|\u4fee\u6b63|\u66f4\u6b63|\u589e\u5220|\u662f\u5426)' },
      @{ name = 'learning outcome'; pattern = '(?is)(?:\u5b66\u4e60\u7ed3\u679c|\u57f9\u8bad\u76ee\u6807|\u8bfe\u7a0b\u76ee\u6807|\u8bfe\u7a0b\u7ec8\u70b9|\u7ec3\u4e60\u7ec8\u70b9).{0,160}(?:\u786e\u8ba4|\u9009\u62e9|\u662f\u5426|\u54ea|\u4ec0\u4e48|\u671f\u671b)' },
      @{ name = 'open path for additional required topics'; pattern = '(?is)(?:(?:\u8865\u5145|\u65b0\u589e|\u5176\u4ed6).{0,60}(?:\u5fc5\u8bb2|\u8bfe\u7a0b|\u5185\u5bb9|\u4e3b\u9898)|(?:\u5fc5\u8bb2|\u8bfe\u7a0b\u5185\u5bb9|\u4e3b\u9898).{0,60}(?:\u8865\u5145|\u65b0\u589e|\u5176\u4ed6))' },
      @{ name = 'exercise endpoint'; pattern = '(?is)(?:\u7ec3\u4e60|\u5b9e\u64cd).{0,100}(?:\u7ec8\u70b9|\u6210\u679c|\u505a\u5230|\u5f62\u5f0f|\u65b9\u5f0f|\u5b8c\u6210)' },
      @{ name = 'current result boundary'; pattern = '(?is)(?:\u672c\u8f6e|\u5f53\u524d).{0,100}(?:\u4e0d\u751f\u6210|\u53ea|\u4ec5|\u5bf9\u8bdd|\u6587\u4ef6|\u8bb2\u4e49|\u7ec3\u4e60\u8868|\u7ed3\u679c)' },
      @{ name = 'evidence-only absence classification'; pattern = '(?is)(?:(?:\u7eb3\u5165|\u6392\u9664).{0,100}(?:\u672a\u5206\u7c7b|\u6682\u4e0d\u5206\u7c7b)|(?:\u672a\u5206\u7c7b|\u6682\u4e0d\u5206\u7c7b).{0,100}(?:\u7eb3\u5165|\u6392\u9664))' },
      @{ name = 'learning acceptance'; pattern = '(?is)(?:(?:\u9a8c\u6536|\u8fbe\u6807|\u6210\u529f\u6807\u51c6|\u5b66\u4e60\u6807\u51c6).{0,140}(?:\u786e\u8ba4|\u9009\u62e9|\u600e\u6837|\u4ec0\u4e48|\u7ed3\u679c|\u8bc1\u636e|\u5224\u65ad)|(?:\u600e\u6837|\u4ec0\u4e48|\u54ea\u4e9b).{0,100}(?:\u9a8c\u6536|\u8fbe\u6807|\u6210\u529f\u6807\u51c6|\u5b66\u4e60\u6807\u51c6))' }
    )
    foreach ($facet in $trainingFacets) {
      if ($draft -notmatch $facet.pattern) { $failures.Add("Training packet is missing $($facet.name).") | Out-Null }
    }
    if (-not $AllowCompletedBaselineReview -and $draft -match '(?i)(?:\u590d\u4e60|\u91cd\u8bb2|\u91cd\u65b0\u8bb2\u6388|\u91cd\u65b0\u57f9\u8bad|review|re-teach)') {
      $failures.Add('Training packet reopens a completed baseline without -AllowCompletedBaselineReview.') | Out-Null
    }
    $negativeBoundaryPattern = '(?i)(?:\u4e0d\u5305\u542b|\u660e\u786e\u6392\u9664|\u5df2\u786e\u8ba4\u6392\u9664|\u6392\u9664\s*[:\uFF1A]|\u4e0d\u7eb3\u5165|\u4e0d\u518d\u8bb2|\u4e0d\u91cd\u590d\u8bb2\u6388|\u4e0d\u5b89\u6392)'
    $unconfirmedBoundaryPattern = '(?i)(?:\u662f\u5426|\u8bf7\u9009\u62e9|\u9009\u62e9|\u5019\u9009|\u8d44\u6599(?:\u672a|\u6ca1\u6709)|\u672a\u8bf7\u6c42|\u672a\u5206\u7c7b|\u6682\u4e0d\u5206\u7c7b|\u4e0d\u7b49\u4e8e|\u4e0d\u89c6\u4e3a|\u5efa\u8bae|\u5982\u679c|\u82e5|\u7531\u4f60\u786e\u8ba4|\u5f85\u786e\u8ba4|\u4e0d\u80fd\u81ea\u52a8|\u4e0d\u5f97\u81ea\u52a8)'
    foreach ($sentence in ($draft -split '(?:\r?\n|[\u3002\uFF01\uFF1F!?;\uFF1B])')) {
      if ($sentence -match $negativeBoundaryPattern -and $sentence -notmatch $unconfirmedBoundaryPattern) {
        $failures.Add('Training packet states a negative curriculum boundary before user confirmation.') | Out-Null
      }
    }
    $currentNoFilePattern = '(?is)(?:(?:\u672c\u8f6e|\u5f53\u524d).{0,80}(?:\u4e0d\u751f\u6210|\u53ea.{0,20}\u5bf9\u8bdd)|do\s+not\s+generate|no\s+files?)'
    $formatTopicPattern = '(?:\u4ea4\u4ed8|\u57f9\u8bad\u6750\u6599|\u8bb2\u4e49|\u7ec3\u4e60\u8868|\u683c\u5f0f|deliverable|format)'
    $formatDecisionPattern = '(?:\u9009\u62e9|\u53ef\u9009|\u54ea|\u4ec0\u4e48|\u8bf7\u786e\u8ba4|\u662f\u5426|choose|which|what)'
    if (-not $AllowFutureFormatDecision -and $draft -match $currentNoFilePattern) {
      foreach ($sentence in ($draft -split '(?:\r?\n|[\u3002\uFF01\uFF1F!?;\uFF1B])')) {
        if ($sentence -match "(?is)(?:$formatTopicPattern.{0,100}$formatDecisionPattern|$formatDecisionPattern.{0,100}$formatTopicPattern)") {
          $failures.Add('Training packet asks for a future artifact format that does not affect the current in-chat result.') | Out-Null
        }
      }
    }
    if ($draft -match '(?im)^\s*(?:#{1,6}\s*)?(?:\u6682\u7f13(?:\u4e0e|\u548c)?\u6392\u9664|\u6682\u7f13|\u6392\u9664)\s*[:\uFF1A]?\s*$' -and $draft -match '(?:\u6682\u65e0\u5df2\u786e\u8ba4\u8bfe\u7a0b\u5185\u5bb9\u6682\u7f13\u9879|none confirmed)') {
      $failures.Add('Ordinary training decision packet renders an empty deferral or exclusion section.') | Out-Null
    }
  } else {
    if ($draft -notmatch '[?\uFF1F]' -and $draft -notmatch '(?:\u8bf7\u786e\u8ba4|\u8bf7\u9009\u62e9|\u8bf7\u8bf4\u660e)') {
      $failures.Add('Inspection discovery packet has no independently answerable confirmation.') | Out-Null
    }
    $inspectionFacets = @(
      @{ name = 'first-release fixed scope versus future additions'; pattern = '(?is)(?:\u9996\u7248|\u7b2c\u4e00\u7248).{0,100}(?:\u73b0\u6709|\u5f53\u524d|\u76ee\u524d|\u8fd9\u6279|\u56fa\u5b9a).{0,100}(?:\u65b0\u589e|\u672a\u6765|\u4ee5\u540e|\u6269\u5c55)' },
      @{ name = 'future configuration owner'; pattern = '(?is)(?:(?:\u8c01|\u7531\u8c01|\u7531\u4f60|\u4f7f\u7528\u8005|\u5f00\u53d1\u4eba\u5458|\u7ef4\u62a4\u4eba\u5458).{0,100}(?:\u914d\u7f6e|\u7ef4\u62a4|\u5904\u7406).{0,100}(?:\u65b0\u589e|\u672a\u6765|\u6a21\u677f)|(?:\u65b0\u589e|\u672a\u6765|\u6a21\u677f).{0,100}(?:\u8c01|\u7531\u8c01|\u7531\u4f60|\u4f7f\u7528\u8005|\u5f00\u53d1\u4eba\u5458|\u7ef4\u62a4\u4eba\u5458).{0,100}(?:\u914d\u7f6e|\u7ef4\u62a4|\u5904\u7406))' },
      @{ name = 'historical-record handling'; pattern = '(?is)(?:\u5386\u53f2|\u7eb8\u8d28|\u65e7\u8bb0\u5f55).{0,120}(?:\u5f55\u5165|\u8865\u5f55|\u7d22\u5f15|\u626b\u63cf|\u4e0d\u5f55)' },
      @{ name = 'correction or void lifecycle'; pattern = '(?is)(?:\u66f4\u6b63|\u4f5c\u5e9f|\u4fee\u6539\u75d5\u8ff9|\u76f4\u63a5\u4fee\u6539)' },
      @{ name = 'record and print scale'; pattern = '(?is)(?:\u6bcf\u5e74|\u8bb0\u5f55\u91cf|\u6570\u91cf).{0,120}(?:\u6253\u5370|\u5355\u6b21|\u6279\u91cf)' },
      @{ name = 'measurable search acceptance'; pattern = '(?is)(?:\u67e5\u8be2|\u67e5\u627e).{0,120}(?:\u79d2|\u65f6\u95f4|\u7b49\u5f85|\u54cd\u5e94|\u6ee1\u8db3\u8981\u6c42|\u8fbe\u5230\u4ec0\u4e48\u7ed3\u679c|\u7b97\u53ef\u7528)' },
      @{ name = 'measurable print acceptance'; pattern = '(?is)\u6253\u5370.{0,140}(?:\u6f0f\u9875|\u4e32\u9875|\u987a\u5e8f|\u7248\u5f0f|\u622a\u65ad|\u4efd|\u6b63\u786e|\u4e00\u81f4)' }
    )
    foreach ($facet in $inspectionFacets) {
      if ($draft -notmatch $facet.pattern) { $failures.Add("Inspection discovery packet is missing $($facet.name).") | Out-Null }
    }
  }

  if ($failures.Count -gt 0) {
    'Question packet lint: FAIL'
    foreach ($failure in @($failures | Select-Object -Unique)) { "- $failure" }
    exit 1
  }

  $label = if ($Profile -eq 'training') { 'Training question packet lint: PASS' } else { "Question packet lint: PASS ($($questionLines.Count) question blocks)" }
  if (-not $PassThrough) {
    $label
  } else {
    $label
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($draft)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try { $hash = ([System.BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $sha256.Dispose() }
    "Question packet SHA256: $hash"
    '---BEGIN APPROVED QUESTION PACKET---'
    $draft
    '---END APPROVED QUESTION PACKET---'
  }
}
