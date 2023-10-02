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
    # inactivity tolerance in seconds
    $inactivityTolerance = 10
    # your program name
    $programName = "YourProgram" 
    $programExecutable =  $programName + ".exe"

    
    $process = @(Get-WmiObject -Class Win32_Process -Filter "Name = 'LogonUI.exe'" -ErrorAction SilentlyContinue | Where-Object {$_.SessionID -eq $([System.Diagnostics.Process]::GetCurrentProcess().SessionId)})
    # Check if the computer is locked
    if ($process.Count -eq 0) {

        # Check if $programName is running
        $isProgramRunning = Get-Process -Name  $programName -ErrorAction SilentlyContinue

        if (-not $isProgramRunning) {
            # Kill script
            exit
        }

        #Get active window
        $activeprogram = Get-ActiveWindowPath
        $exeName = Split-Path $activeprogram -Leaf
       
        if ($exeName -ne $programExecutable) {
            $counter++
        } else {
            $counter = 0
        }

    } else { # Kill program after locked
        taskkill /IM $programExecutable /F
        [System.Windows.Forms.MessageBox]::Show("yourProgram,`nwas closed because locked", "Script done by Tuki", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        exit
    }

    # Kill program after inactivity
    if ($counter -ge $inactivityTolerance) {
        taskkill /IM $programExecutable /F
        [System.Windows.Forms.MessageBox]::Show("yourProgram,`nwas closed", "Script done by Tuki", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        exit
    }

    Start-Sleep -Seconds 1

}
