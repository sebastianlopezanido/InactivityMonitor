Add-Type @"
    using System;
    using System.Diagnostics;
    using System.Runtime.InteropServices;
    public class User32 {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);

         [DllImport("user32.dll", SetLastError = true)]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    }
    namespace PInvoke.Win32 {

    public static class UserInput {

        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
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

function Get-LastActivity {
    return [PInvoke.Win32.UserInput]::IdleTime
}

function Get-LastInput {
    $currentTime = Get-Date
    $lastInputUtc = [PInvoke.Win32.UserInput]::LastInput
    $localTimeZone = [System.TimeZoneInfo]::Local
    $lastInputLocal = [System.TimeZoneInfo]::ConvertTimeFromUtc($lastInputUtc, $localTimeZone)
    $timeDifference = [math]::abs(($currentTime - $lastInputLocal).TotalMilliseconds)
    return [TimeSpan]::FromMilliseconds($timeDifference)
}

while($true)
{
    # unfocus tolerance in seconds 
    $unfocusTolerance = 10
    # inactivity tolerance in time for inactivity
    $inactivityTolerance = '00:01:00'
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

        #Get last activity
        $lastActivity = Get-LastActivity
        #Get last input
        $lastInput = Get-LastInput 

        # Kill program after inactivity
        if ($counter -ge $unfocusTolerance -or  $lastActivity -ge $inactivityTolerance -or  $lastInput -ge $inactivityTolerance) {
            taskkill /IM $programExecutable /F
            [System.Windows.Forms.MessageBox]::Show("yourProgram,`nwas closed", "Script done by Tuki", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            exit
        }

    } else { # Kill program after locked
        taskkill /IM $programExecutable /F
        [System.Windows.Forms.MessageBox]::Show("yourProgram,`nwas closed because locked", "Script done by Tuki", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        exit
    }

    Start-Sleep -Seconds 1

}
