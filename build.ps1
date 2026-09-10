$ErrorActionPreference = "Stop"

# Auto-heal corrupted/truncated .git/index (< 12 bytes header)
$gitIndex = Join-Path $PSScriptRoot ".git\index"
if ((Test-Path $gitIndex) -and (Get-Item $gitIndex).Length -lt 12) {
  Write-Warning "Corrupted .git/index detected (size < 12 bytes). Rebuilding index..."
  Remove-Item $gitIndex -Force
  & git reset --quiet
}

$propsFile = Join-Path $PSScriptRoot "version.properties"
$props = @{}
Get-Content $propsFile | ForEach-Object {
  $line = $_.Trim()
  if ($line -and -not $line.StartsWith("#")) {
    $parts = $line.Split("=", 2)
    if ($parts.Length -eq 2) { $props[$parts[0].Trim()] = $parts[1].Trim() }
  }
}

$mcreatorVersion = if ($props.ContainsKey("mcreator_version")) { $props["mcreator_version"] } else { "2026.2" }
$now = Get-Date
$lastYear = if ($props.ContainsKey("last_year")) { [int]$props["last_year"] } else { 0 }
$lastMonth = if ($props.ContainsKey("last_month")) { [int]$props["last_month"] } else { 0 }

if ($now.Year -ne $lastYear -or $now.Month -ne $lastMonth) {
  $increment = 1
}
else {
  $increment = if ($props.ContainsKey("build_increment")) { [int]$props["build_increment"] } else { 1 }
}

$version = "$mcreatorVersion-$($now.Year).$($now.Month).$increment"

$mcreatorRoot = "C:\Program Files\Pylo\MCreator-2026.2"
$javac = Join-Path $mcreatorRoot "jdk\bin\javac.exe"
$jar = Join-Path $mcreatorRoot "jdk\bin\jar.exe"
$coreJar = "C:\Users\casey\AppData\Local\Temp\mcreator_clean.jar"
if (-not (Test-Path $javac)) { $javac = "javac" }
if (-not (Test-Path $jar)) { $jar = "jar" }

$buildDir = Join-Path $PSScriptRoot "build"
$classesDir = Join-Path $buildDir "classes"
$stagingDir = Join-Path $buildDir "plugin_staging"
$distDir = Join-Path $buildDir "distribution"
Remove-Item $classesDir, $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $classesDir, $stagingDir, $distDir | Out-Null

$pluginJsonPath = Join-Path $PSScriptRoot "plugin.json"
$pluginJson = Get-Content $pluginJsonPath -Raw | ConvertFrom-Json
$pluginJson.info.version = $version
$pluginJson | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $pluginJsonPath

$javaSources = Get-ChildItem (Join-Path $PSScriptRoot "src\main\java") -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName
if ($javaSources) {
  & $javac -encoding UTF-8 -cp "$coreJar;$mcreatorRoot\lib\*" -d $classesDir $javaSources
  if ($LASTEXITCODE -ne 0) { throw "Java compilation failed with exit code $LASTEXITCODE" }
}

if (Test-Path (Join-Path $classesDir "net")) {
  Copy-Item (Join-Path $classesDir "net") (Join-Path $stagingDir "net") -Recurse -Force
}
Copy-Item $pluginJsonPath $stagingDir
foreach ($item in @("README.md", "lang", "blockly", "variables", "procedures", "triggers", "themes", "forge-1.20.1", "neoforge-1.21.1", "neoforge-26.1.2", "neoforge-26.2")) {
  $source = Join-Path $PSScriptRoot $item
  if (Test-Path $source) { Copy-Item $source (Join-Path $stagingDir $item) -Recurse -Force }
}

$outputName = "BlockOverlays-$version.zip"
$outputPath = Join-Path $distDir $outputName
Remove-Item $outputPath -Force -ErrorAction SilentlyContinue
Push-Location $stagingDir
try {
  & $jar -c -f $outputPath *
  if ($LASTEXITCODE -ne 0) { throw "ZIP packaging failed with exit code $LASTEXITCODE" }
}
finally {
  Pop-Location
}

$nextIncrement = $increment + 1
@"
mcreator_version=$mcreatorVersion
build_increment=$nextIncrement
last_year=$($now.Year)
last_month=$($now.Month)
"@ | Set-Content -Encoding ASCII $propsFile

Write-Host "Build complete: $outputPath"