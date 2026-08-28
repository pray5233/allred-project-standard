param(
  [Parameter(Mandatory = $true)]
  [string]$Path
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
. (Join-Path $PSScriptRoot 'state_validation_common.ps1')

$failures = [System.Collections.Generic.List[string]]::new()
function Add-Failure([string]$Message) { $script:failures.Add($Message) | Out-Null }

try {
  $state = Read-AllredProjectState -Path $Path
} catch {
  Add-Failure $_.Exception.Message
  $state = $null
}

$decisions = @()
if ($null -ne $state) {
  $decisions = @(Get-AllredArray (Get-AllredProperty $state 'decisions'))
  $userSources = Get-AllredUserSourceMap $state
} else {
  $userSources = @{}
}
$byId = @{}
$activeAxes = @{}
$allowedStatuses = @('open', 'proposed', 'confirmed', 'deferred', 'superseded', 'not-applicable')
$activeStatuses = @('open', 'proposed', 'confirmed')

foreach ($decision in $decisions) {
  $id = [string](Get-AllredProperty $decision 'id')
  $axis = [string](Get-AllredProperty $decision 'axis')
  $status = ([string](Get-AllredProperty $decision 'status')).ToLowerInvariant()

  if ($id -notmatch '^D[0-9A-Za-z._-]+$') { Add-Failure "Invalid decision ID: $id"; continue }
  if ($byId.ContainsKey($id)) { Add-Failure "Duplicate decision ID: $id"; continue }
  $byId[$id] = $decision

  if ([string]::IsNullOrWhiteSpace($axis)) { Add-Failure "Decision has no material axis: $id" }
  if ($status -notin $allowedStatuses) { Add-Failure "Invalid decision status for ${id}: $status" }
  if ($status -in $activeStatuses -and -not [string]::IsNullOrWhiteSpace($axis)) {
    if ($activeAxes.ContainsKey($axis)) { Add-Failure "Active decisions share one axis: $($activeAxes[$axis]) and $id ($axis)" }
    else { $activeAxes[$axis] = $id }
  }
}

foreach ($decision in $decisions) {
  $id = [string](Get-AllredProperty $decision 'id')
  if (-not $byId.ContainsKey($id)) { continue }
  $status = ([string](Get-AllredProperty $decision 'status')).ToLowerInvariant()
  $exposed = Get-AllredProperty $decision 'exposed'
  $trigger = [string](Get-AllredProperty $decision 'trigger')
  $choice = [string](Get-AllredProperty $decision 'choice')
  $approvalSource = [string](Get-AllredProperty $decision 'approval_source')

  if ($null -eq $exposed -or $exposed -isnot [bool]) { Add-Failure "Decision exposed must be boolean: $id" }
  if ($exposed -eq $true) {
    if ($trigger -notmatch '^(baseline|user:U[0-9A-Za-z._-]+|evidence:E[0-9A-Za-z._-]+|decision:D[0-9A-Za-z._-]+=[^\s]+)$') {
      Add-Failure "Exposed decision has no exact trigger: $id"
    }
    if ($trigger -match '^user:(U[0-9A-Za-z._-]+)$' -and -not $userSources.ContainsKey($Matches[1])) {
      Add-Failure "Exposed decision references missing user trigger: $id -> $($Matches[1])"
    }
  }
  if ($status -eq 'confirmed') {
    if ([string]::IsNullOrWhiteSpace($choice)) { Add-Failure "Confirmed decision has no choice: $id" }
    if ($approvalSource -notmatch '^(U|C)[0-9A-Za-z._-]+$') { Add-Failure "Confirmed decision has no user/envelope approval source: $id" }
    if ($approvalSource -match '^U' -and -not $userSources.ContainsKey($approvalSource)) { Add-Failure "Confirmed decision references missing user approval source: $id -> $approvalSource" }
    if ($exposed -ne $true) { Add-Failure "A confirmed decision was never exposed: $id" }
  }

  foreach ($dependency in @(Get-AllredArray (Get-AllredProperty $decision 'depends_on'))) {
    $parentId = [string](Get-AllredProperty $dependency 'id')
    $allowedChoices = @((Get-AllredArray (Get-AllredProperty $dependency 'choices')) | ForEach-Object { [string]$_ })
    if ($parentId -notmatch '^D[0-9A-Za-z._-]+$' -or -not $byId.ContainsKey($parentId)) {
      Add-Failure "Decision $id references missing parent: $parentId"
      continue
    }
    if ($allowedChoices.Count -eq 0) { Add-Failure "Decision $id dependency has no exact parent choice: $parentId"; continue }

    $parent = $byId[$parentId]
    $parentStatus = ([string](Get-AllredProperty $parent 'status')).ToLowerInvariant()
    $parentChoice = [string](Get-AllredProperty $parent 'choice')
    $dependencySatisfied = $parentStatus -eq 'confirmed' -and $parentChoice -in $allowedChoices

    if ($status -eq 'confirmed' -and -not $dependencySatisfied) {
      Add-Failure "Confirmed decision $id was invalidated by parent $parentId=$parentChoice"
    } elseif ($status -in @('open', 'proposed') -and -not $dependencySatisfied) {
      Add-Failure "Active decision $id was exposed or retained before dependency $parentId=$($allowedChoices -join '/') was confirmed"
    }
  }

  $recommendation = Get-AllredProperty $decision 'recommendation'
  if ($null -ne $recommendation) {
    $recommendedOption = [string](Get-AllredProperty $recommendation 'option')
    $basis = @((Get-AllredArray (Get-AllredProperty $recommendation 'basis')) | ForEach-Object { [string]$_ })
    if ([string]::IsNullOrWhiteSpace($recommendedOption)) { Add-Failure "Recommendation has no option: $id" }
    if ($basis.Count -eq 0) { Add-Failure "Recommendation has no U/E/D basis: $id" }
    foreach ($reference in $basis) {
      if (-not (Test-AllredReferenceId -Value $reference -Prefixes 'UED')) {
        Add-Failure "Recommendation $id has invalid basis: $reference"
      }
      if ((Get-AllredReferencePrefix $reference) -eq 'U' -and -not $userSources.ContainsKey($reference)) {
        Add-Failure "Recommendation $id references missing user basis: $reference"
      }
      if ((Get-AllredReferencePrefix $reference) -eq 'D') {
        if (-not $byId.ContainsKey($reference) -or ([string](Get-AllredProperty $byId[$reference] 'status')).ToLowerInvariant() -ne 'confirmed') {
          Add-Failure "Recommendation $id depends on unconfirmed decision basis: $reference"
        }
      }
    }
  }
}

if ($failures.Count -gt 0) {
  'Decision frontier validation: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Decision frontier validation: PASS'
"Decisions checked: $($decisions.Count)"
