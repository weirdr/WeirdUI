param(
    [ValidateSet('retail', 'xptr')]
    [string]$Client = 'retail',

    [string]$WoWRoot = 'C:\Program Files (x86)\World of Warcraft'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$clientFolder = if ($Client -eq 'retail') { '_retail_' } else { '_xptr_' }
$addonsRoot = Join-Path $WoWRoot "$clientFolder\Interface\AddOns"
$targetRoot = Join-Path $addonsRoot 'WeirdUI'

if (-not (Test-Path $addonsRoot)) {
    throw "AddOns folder not found: $addonsRoot"
}

if (Test-Path $targetRoot) {
    Remove-Item $targetRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $targetRoot | Out-Null

$itemsToCopy = @(
    'WeirdUI.toc',
    'Core',
    'Themes',
    'Assets',
    'Menu',
    'Debug'
)

foreach ($item in $itemsToCopy) {
    Copy-Item (Join-Path $repoRoot $item) -Destination $targetRoot -Recurse -Force
}

Write-Output "Installed WeirdUI to $targetRoot"
