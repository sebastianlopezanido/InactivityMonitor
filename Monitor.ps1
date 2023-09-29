Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class User32 {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);

         [DllImport("user32.dll", SetLastError = true)]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    }
"@

Add-Type -AssemblyName System.Windows.Forms

function Get-ActiveWindow {
    $buffer = New-Object System.Text.StringBuilder(256)
    $handle = [User32]::GetForegroundWindow()
    if ([User32]::GetWindowText($handle, $buffer, 256) -gt 0) {
        return $buffer.ToString()
    }
    return $null
}

function Get-ActiveWindowPath {
    $hWnd = [User32]::GetForegroundWindow()
    $pid2 = 0
    $tid = [User32]::GetWindowThreadProcessId($hWnd, [ref] $pid2)
    $process = Get-Process -Id $pid2
    return $process.MainModule.FileName
}

while($true)
{
    $activeprogram = Get-ActiveWindowPath
    $exeName = Split-Path $activeprogram -Leaf
    # your program name
    $programName = "yourProgram.exe" 
    if ($exeName -ne $programName) {
        $counter++
    } else {
        $counter = 0
    }
    Start-Sleep -Seconds 1

    # inactivity tolerance in seconds
    $inactivityTolerance = 10

    if ($counter -ge $inactivityTolerance) {
        # your program name
        taskkill /IM yourProgram.exe /F
        [System.Windows.Forms.MessageBox]::Show("yourProgram,`nwas closed", "Script done by Tuki", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        exit
    }
}
