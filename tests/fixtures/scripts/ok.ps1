# A small script that PSScriptAnalyzer should pass.
param(
    [string]$Name = 'world'
)

Write-Output "hello, $Name"
