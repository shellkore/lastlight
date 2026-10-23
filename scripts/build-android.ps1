param([string]$FlutterSdk, [string]$AndroidSdk, [string]$JavaHome)
$ErrorActionPreference = 'Stop'
$lastlightRoot = Split-Path -Parent $PSScriptRoot
if ($JavaHome) { $env:JAVA_HOME = $JavaHome }
if ($AndroidSdk) { $env:ANDROID_HOME = $AndroidSdk }
$env:CI = 'true'
# Some packaged Windows shells expose a temp path unsupported by Java AF_UNIX.
# Use the JDK's TCP fallback for this build process and its children only.
if ($IsWindows) {
    $lastlightSocketFallback = Join-Path $lastlightRoot '.tools\no-unix-sockets'
    if (-not (Test-Path -LiteralPath $lastlightSocketFallback)) {
        $env:JAVA_TOOL_OPTIONS = ($env:JAVA_TOOL_OPTIONS + " -Djdk.net.unixdomain.tmpdir=$lastlightSocketFallback").Trim()
    }
}
if ($FlutterSdk) { $lastlightFlutter = Join-Path $FlutterSdk 'bin\flutter.bat' }
elseif (Test-Path -LiteralPath (Join-Path $lastlightRoot '.tools\flutter\bin\flutter.bat')) { $lastlightFlutter = Join-Path $lastlightRoot '.tools\flutter\bin\flutter.bat' }
else { $lastlightFlutter = (Get-Command flutter -ErrorAction Stop).Source }
Push-Location (Join-Path $lastlightRoot 'mobile-lastlight')
try {
    & $lastlightFlutter --no-version-check pub get
    if ($LASTEXITCODE) { throw 'Dependency installation failed.' }
    & $lastlightFlutter --no-version-check analyze
    if ($LASTEXITCODE) { throw 'Analysis failed.' }
    & $lastlightFlutter --no-version-check test
    if ($LASTEXITCODE) { throw 'Flutter tests failed.' }
    & $lastlightFlutter --no-version-check build apk --release --split-per-abi
    if ($LASTEXITCODE) { throw 'Android build failed.' }
    $lastlightApk = Join-Path $lastlightRoot 'mobile-lastlight\build\app\outputs\flutter-apk'
    & node (Join-Path $lastlightRoot 'web\scripts\attach-apk.mjs') $lastlightApk
    if ($LASTEXITCODE) { throw 'Could not attach APK to website.' }
} finally { Pop-Location }
