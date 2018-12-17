$framesCompressBase64 = '{{ payload }}'
$songUrl = 'http://www.leeholmes.com/projects/ps_html5/background.mp3'

## Decompress the frames
$framesBin = [System.Convert]::FromBase64String($framesCompressBase64)
$compressMemStream = New-Object System.IO.MemoryStream
$compressMemStream.Write($framesBin, 0, $framesBin.Length)
$compressMemStream.Seek(0, 0) | Out-Null
$gzipStream = New-Object System.IO.Compression.GZipStream($compressMemStream, [System.IO.Compression.CompressionMode]"Decompress")
$streamReader = New-Object System.IO.StreamReader($gzipStream)
$framesData = $streamReader.ReadToEnd()
$streamReader.Close()
$gzipStream.Close()
$compressMemStream.Close()

# Split frame data into an array
$frames = $framesData -split "\r\n-----------\r\n"

# Go through the frames, and re-scale them so that they have the
# proper aspect ratio in the console
for ($i = 0; $i -lt $frames.Count; $i++)
{
    $frame = $frames[$i]
    $expansion = (@('$1') + (('$2','$3','$2','$3') | Get-Random -Count 4 | Sort)) -join ''
    $frame = (($frame -split "`t") -replace '(.)(.)(.)',$expansion) -join "`t"
    $frames[$i] = $frame
}
    
# Prepare the screen
$counter = 0
$maxCounter = $frames.Count - 1
$Host.UI.RawUI.BackgroundColor = "White"
$Host.UI.RawUI.ForegroundColor = "Black"
try
{
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size 83,45
}
catch
{}

try
{
    $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size 83,45
}
catch {}

try
{
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size 83,45
}
catch {}

try
{
    $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size 83,45
}
catch {}

## Open the background song
$backgroundScript = @'
   $player = New-Object -ComObject 'MediaPlayer.MediaPlayer'
   $player.Open("{{ songUrl }}")
   $player
'@.Replace('{{ songUrl }}', $songUrl)

# ... in a background MTA-threaded PowerShell because
# the MediaPlayer COM object doesn't like STA
$runspace = [RunspaceFactory]::CreateRunspace()
$runspace.ApartmentState = "MTA"
$backgroundPS = [PowerShell]::Create()
$backgroundPS.Runspace = $runspace
$runspace.Open()
$player = @($backgroundPS.AddScript($backgroundScript).Invoke())[0]

try
{
    # Wait for it to buffer (or error out)
    while ($true)
    {
        Start-Sleep -m 500
        if ($player.HasError -or ($player.ReadyState -eq 4))
        { 
            break 
        }
    }
    
    Start-Sleep -m 1600
    Clear-Host
    
    $host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0, ([Console]::WindowHeight - 1)
    Write-Host -NoNewLine 'Q or ESC when its enough...'
    
    ## Loop through the frames and display them
    [Console]::TreatControlCAsInput = $true
    while ($true)
    {
        if ([Console]::KeyAvailable)
        {
            $key = [Console]::ReadKey()
            if(($key.Key -eq 'Escape') -or ($key.Key -eq 'Q'))
            {
                break
            }
        }
        
        if ((-not $player.HasError) -and ($player.PlayState -eq 0))
        { 
            break 
        }

        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0, 0
        Write-Host (($frames[$counter] -split "`t") -join [Environment]::NewLine)
        
        Start-Sleep -m 100
        $counter = ($counter + 1) % $maxCounter
    }
}
finally
{
    ## Clean up, display exit screen
    Clear-Host
    $frames[-1] -split "`t"
    "`n"
    "                        Never enough cheesy stuff...even in Powershell"
    "                                    ASCII Art rocks!!!!"
    "`n`n`n"
    $player.Stop()
    $backgroundPS.Dispose()
}
