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

  if ($failures.Count -gt 0) {
    'Question packet lint: FAIL'
    foreach ($failure in @($failures | Select-Object -Unique)) { "- $failure" }
    exit 1
  }

  "Question packet lint: PASS ($($questionLines.Count) question blocks)"
}
