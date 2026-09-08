function Get-AllredConfigTrustEquivalence {
  param(
    [Parameter(Mandatory=$true)][string]$ConfigPath,
    [Parameter(Mandatory=$true)][string[]]$KnownHashes,
    [Parameter(Mandatory=$true)][string[]]$WorkspacePaths
  )
  $allowed = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach ($path in $WorkspacePaths) { [void]$allowed.Add([IO.Path]::GetFullPath($path).TrimEnd('\','/')) }
  $bytes = [IO.File]::ReadAllBytes($ConfigPath)
  $text = [Text.Encoding]::UTF8.GetString($bytes)
  $blocks = [Collections.Generic.List[object]]::new()
  foreach ($block in [regex]::Matches($text,'(?ms)^\[projects\.[^\r\n]+\]\r?\n(?:(?!^\[).)*')) {
    # Accept only the literal, single-key registration emitted by the local CLI.
    # This is byte reconstruction, not a general TOML parser or config normalizer.
    $match = [regex]::Match($block.Value, '(?s)^\[projects\.\x27([^\x27\r\n]+)\x27\]\r?\n\s*trust_level\s*=\s*"trusted"\s*$')
    if ($match.Success -and $allowed.Contains([IO.Path]::GetFullPath($match.Groups[1].Value).TrimEnd('\','/'))) { $blocks.Add($block) }
  }
  $matchesFound = [Collections.Generic.List[object]]::new()
  $sourceHash = ''
  for ($keep = $blocks.Count; $keep -ge 0; $keep--) {
    $trial = $text
    for ($index = $blocks.Count-1; $index -ge $keep; $index--) { $trial = $trial.Remove($blocks[$index].Index,$blocks[$index].Length) }
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $hash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($trial)))).Replace('-','') }
    finally { $sha.Dispose() }
    if ($keep -eq $blocks.Count) { $sourceHash = $hash }
    if ($hash -in $KnownHashes) { $matchesFound.Add([pscustomobject]@{hash=$hash;retained_trust_blocks=$keep}) }
  }
  if (@($KnownHashes | Where-Object { $_ -notin $matchesFound.hash }).Count) { throw 'Configuration equivalence unproven: differences exceed verified fixture trust registrations.' }
  [pscustomobject]@{
    method='Exact byte reconstruction of historical hashes by removing only suffix registrations for explicit fixture workspaces. No change outside those registrations is ignored.'
    source_sha256=$sourceHash
    trust_blocks=$blocks.Count
    matches=@($matchesFound)
    limitation='Proves the recorded snapshots differ only by these registrations; does not freeze configuration throughout every model call.'
  }
}
