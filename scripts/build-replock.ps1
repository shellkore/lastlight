param([string]$FlutterSdk, [string]$AndroidSdk, [string]$JavaHome)
$ErrorActionPreference = 'Stop'
$repRoot = Split-Path -Parent $PSScriptRoot
if ($JavaHome) { $env:JAVA_HOME = $JavaHome }
if ($AndroidSdk) { $env:ANDROID_HOME = $AndroidSdk }
$env:CI = 'true'
if ($env:OS -eq 'Windows_NT') { $env:JAVA_TOOL_OPTIONS = ($env:JAVA_TOOL_OPTIONS + " -Djdk.net.unixdomain.tmpdir=$repRoot/.tools/no-unix-sockets").Trim() }
if ($FlutterSdk) { $repFlutter = Join-Path $FlutterSdk 'bin/flutter.bat' }
elseif (Test-Path -LiteralPath (Join-Path $repRoot '.tools/flutter/bin/flutter.bat')) { $repFlutter = Join-Path $repRoot '.tools/flutter/bin/flutter.bat' }
else { $repFlutter = (Get-Command flutter -ErrorAction Stop).Source }
Push-Location (Join-Path $repRoot 'mobile-replock')
try {
    & $repFlutter --no-version-check pub get
    if ($LASTEXITCODE) { throw 'Dependency install failed.' }
    & $repFlutter --no-version-check analyze
    if ($LASTEXITCODE) { throw 'Analysis failed.' }
    & $repFlutter --no-version-check test
    if ($LASTEXITCODE) { throw 'Flutter tests failed.' }
    & $repFlutter --no-version-check build apk --release --split-per-abi
    if ($LASTEXITCODE) { throw 'Android build failed.' }
    Push-Location android
    try { & ./gradlew.bat testDebugUnitTest; if ($LASTEXITCODE) { throw 'Native tests failed.' } } finally { Pop-Location }
    & $repFlutter --no-version-check build web --release --base-href /replock/preview/
    if ($LASTEXITCODE) { throw 'Browser preview build failed.' }
    & node (Join-Path $repRoot 'web/scripts/attach-replock.mjs') (Join-Path $repRoot 'mobile-replock/build/app/outputs/flutter-apk')
    if ($LASTEXITCODE) { throw 'APK attachment failed.' }
    Copy-Item -Path 'build/web/*' -Destination (New-Item -ItemType Directory -Force (Join-Path $repRoot 'web/dist/replock/preview')).FullName -Recurse -Force
} finally { Pop-Location }
