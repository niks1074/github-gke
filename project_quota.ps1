# check_ssd_quota.ps1
param(
  [string]$Project = "gke-tf-bg",
  [int]$GcloudTimeoutSeconds = 20
)

function Run-GcloudWithTimeout {
  param($Args, $TimeoutSec)
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "gcloud"
  $psi.Arguments = $Args
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true

  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo = $psi
  $proc.Start() | Out-Null

  if ($proc.WaitForExit($TimeoutSec * 1000)) {
    $out = $proc.StandardOutput.ReadToEnd()
    $err = $proc.StandardError.ReadToEnd()
    return @{ Success = $true; Out = $out; Err = $err; ExitCode = $proc.ExitCode }
  } else {
    try { $proc.Kill() } catch {}
    return @{ Success = $false; Out = ""; Err = "Timed out after ${TimeoutSec}s"; ExitCode = -1 }
  }
}

Write-Host "Checking SSD_TOTAL_GB quota for project: $Project" -ForegroundColor Cyan

# get list of regions
$regionsRes = Run-GcloudWithTimeout "compute regions list --project $Project --format=json" $GcloudTimeoutSeconds
if (-not $regionsRes.Success) {
  Write-Host "Failed to list regions: $($regionsRes.Err)" -ForegroundColor Red
  exit 1
}

$regions = @()
try {
  $regions = ($regionsRes.Out | ConvertFrom-Json).name
} catch {
  Write-Host "Failed to parse regions JSON: $_" -ForegroundColor Red
  exit 1
}

$results = @()
foreach ($r in $regions) {
  Write-Host "Querying region: $r ..." -NoNewline
  $cmd = "compute regions describe $r --project $Project --format=json(quotas)"
  $res = Run-GcloudWithTimeout $cmd $GcloudTimeoutSeconds

  if (-not $res.Success) {
    Write-Host " timed out or failed." -ForegroundColor Yellow
    $results += [PSCustomObject]@{ region = $r; metric = "SSD_TOTAL_GB"; limit = $null; usage = $null; available = $null; note = "timeout/failure" }
    continue
  }

  try {
    $json = $res.Out | ConvertFrom-Json
    $ssd = $json.quotas | Where-Object { $_.metric -eq "SSD_TOTAL_GB" }
    if ($ssd) {
      $limit = [int]$ssd.limit
      $usage = [int]$ssd.usage
      $available = $limit - $usage
      Write-Host " available=$available (limit=$limit usage=$usage)" -ForegroundColor Green
      $results += [PSCustomObject]@{ region = $r; metric = "SSD_TOTAL_GB"; limit = $limit; usage = $usage; available = $available; note = "" }
    } else {
      Write-Host " no SSD_TOTAL_GB metric" -ForegroundColor Yellow
      $results += [PSCustomObject]@{ region = $r; metric = "SSD_TOTAL_GB"; limit = $null; usage = $null; available = $null; note = "metric not present" }
    }
  } catch {
    Write-Host " parse error" -ForegroundColor Red
    $results += [PSCustomObject]@{ region = $r; metric = "SSD_TOTAL_GB"; limit = $null; usage = $null; available = $null; note = "parse error" }
  }
}

Write-Host "`nSummary (regions with available SSD >= 300):" -ForegroundColor Cyan
$results | Where-Object { $_.available -ge 300 } | Format-Table region,limit,usage,available -AutoSize

Write-Host "`nAll results:" -ForegroundColor Cyan
$results | Sort-Object -Property @{Expression={$_.available -as [int]}} -Descending | Format-Table region,limit,usage,available,note -AutoSize