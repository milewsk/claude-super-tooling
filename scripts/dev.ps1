#Requires -Version 5.1
<#
.SYNOPSIS
  Launch Claude Code with this repo's plugins loaded from disk.
.DESCRIPTION
  Loads every plugin under ./plugins without installing from the marketplace.
  Run /reload-plugins in the session after editing a plugin file.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$plugins = Join-Path $repo 'plugins'

if (-not (Test-Path $plugins)) {
    throw "No plugins directory at $plugins"
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warning "'claude' is not on PATH. Install the CLI, or run this from a terminal where it is available."
    Write-Host "Otherwise, run manually:  claude --plugin-dir `"$plugins`"" -ForegroundColor Yellow
    exit 1
}

Write-Host "Loading plugins from $plugins" -ForegroundColor Cyan
& claude --plugin-dir $plugins
