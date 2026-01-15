$ErrorActionPreference = 'Stop'

function Ask-Choice($prompt, $choices) {
    Write-Host ""; Write-Host $prompt
    for ($i = 0; $i -lt $choices.Count; $i++) {
        Write-Host "[$($i+1)] $($choices[$i])"
    }
    do {
        $sel = Read-Host "Enter choice number"
    } until ($sel -as [int] -and $sel -ge 1 -and $sel -le $choices.Count)
    return $choices[$sel-1]
}

# URLs (official / reputable sources)
$chocoDoomZip = 'https://www.chocolate-doom.org/downloads/3.0.1/chocolate-doom-3.0.1-win32.zip'
$doomSharewareWad = 'https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad'

$mode = Ask-Choice "Choose mode:" @('Portable (auto-delete on exit)', 'Install to C:\Games\DOOM')

if ($mode -like 'Portable*') {
    $baseDir = Join-Path $env:TEMP "doom_portable_$([guid]::NewGuid().ToString())"
    $cleanup = $true
} else {
    $baseDir = 'C:\Games\DOOM'
    $cleanup = $false
}

$null = New-Item -ItemType Directory -Force -Path $baseDir
$zipPath = Join-Path $baseDir 'chocolate-doom.zip'

Write-Host "Downloading Chocolate Doom..."
Invoke-WebRequest $chocoDoomZip -OutFile $zipPath

Write-Host "Extracting..."
Expand-Archive $zipPath -DestinationPath $baseDir -Force
Remove-Item $zipPath -Force

Write-Host "Downloading DOOM Shareware (doom1.wad)..."
Invoke-WebRequest $doomSharewareWad -OutFile (Join-Path $baseDir 'doom1.wad')

# Find chocolate-doom.exe
$exe = Get-ChildItem -Path $baseDir -Recurse -Filter 'chocolate-doom.exe' | Select-Object -First 1
if (-not $exe) { throw 'chocolate-doom.exe not found.' }

Write-Host "Launching DOOM..."
$proc = Start-Process -FilePath $exe.FullName -WorkingDirectory $exe.DirectoryName -PassThru
$proc.WaitForExit()

Write-Host "DOOM closed."

if ($cleanup) {
    Write-Host "Cleaning up portable files..."
    Remove-Item $baseDir -Recurse -Force
    Write-Host "Done."
} else {
    Write-Host "Installed at $baseDir"
}

Write-Host "Press Enter to exit."
[void][System.Console]::ReadLine()
