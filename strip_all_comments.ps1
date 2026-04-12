param([string]$Root = ".")
$comment = [string]::Concat('/','/')
$files = Get-ChildItem -Recurse -File -Path $Root -ErrorAction SilentlyContinue
foreach ($f in $files) {
  try {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    if ($bytes.Length -gt 0 -and ($bytes | Where-Object { $_ -eq 0 })) { continue }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    $lines = $text -split [char]10
    $newLines = @()
    foreach ($line in $lines) {
      $idx = $line.IndexOf($comment)
      if ($idx -ge 0) {
        $newLines += $line.Substring(0, $idx).TrimEnd()
      } else {
        $newLines += $line.TrimEnd()
      }
    }
    $out = [string]::Join([string][char]10, $newLines)
    [System.IO.File]::WriteAllText($f.FullName, $out)
  } catch {
    continue
  }
}
