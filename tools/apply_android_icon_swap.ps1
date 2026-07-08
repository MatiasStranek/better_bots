param(
  [string]$ProjectRoot = "."
)

$mobileRoot = Join-Path $ProjectRoot "lib\ui\mobile"

if (!(Test-Path $mobileRoot)) {
  Write-Error "Mobile-Ordner nicht gefunden: $mobileRoot"
  exit 1
}

$files = Get-ChildItem $mobileRoot -Recurse -Filter "*.dart"

$changed = @()

foreach ($file in $files) {
  $content = Get-Content -Raw -Encoding UTF8 $file.FullName
  $original = $content

  # Zielzustand:
  # Weiß bekommt das bisherige Schwarz-Icon.
  # Schwarz bekommt das bisherige Weiß-Icon.
  #
  # Das patcht bewusst alle Mobile-Dateien, damit es sowohl für
  # mobile_chess_top_controls.dart als auch für mobile_chess_side_menu.dart greift.
  $content = [regex]::Replace(
    $content,
    "(label:\s*['""](?:Mit\s+)?Weiß['""],\s*\r?\n\s*icon:\s*)Icons\.[A-Za-z0-9_]+",
    '${1}Icons.circle'
  )

  $content = [regex]::Replace(
    $content,
    "(label:\s*['""](?:Mit\s+)?Schwarz['""],\s*\r?\n\s*icon:\s*)Icons\.[A-Za-z0-9_]+",
    '${1}Icons.circle_outlined'
  )

  if ($content -ne $original) {
    $backup = "$($file.FullName).bak_icon_swap"

    if (!(Test-Path $backup)) {
      Copy-Item $file.FullName $backup
    }

    Set-Content -Encoding UTF8 $file.FullName $content
    $changed += $file.FullName
  }
}

if ($changed.Count -eq 0) {
  Write-Host "Keine passenden Android-Icon-Blöcke gefunden. Falls die Icons in einer anderen Datei/Struktur stehen, bitte mobile_chess_side_menu.dart hochladen."
} else {
  Write-Host "Android-Icons angepasst in:"
  $changed | ForEach-Object { Write-Host " - $_" }
}
