#    This file is part of Invoke-Obfuscation.
#
#   Copyright 2016 Daniel Bohannon <@danielhbohannon>
#         while at Mandiant <http://www.mandiant.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.



Function Invoke-Obfuscation
{
<#
.SYNOPSIS

Master function that orchestrates the application of all obfuscation functions to provided PowerShell script block or script path contents. Interactive mode enables one to explore all available obfuscation functions and apply them incrementally to input PowerShell script block or script path contents.
CLI support and customizable RUNBOOK options will be available in the next release of this tool.

Invoke-Obfuscation Function: Invoke-Obfuscation
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: Show-AsciiArt, Show-HelpMenu, Show-Menu, Show-OptionsMenu, Show-Tutorial and Out-ScriptContents (all located in Invoke-Obfuscation.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Invoke-Obfuscation orchestrates the application of all obfuscation functions to provided PowerShell script block or script path contents to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments.

.EXAMPLE

C:\PS> Import-Module .\Invoke-Obfuscation.psm1; Invoke-Obfuscation

.NOTES

Invoke-Obfuscation orchestrates the application of all obfuscation functions to provided PowerShell script block or script path contents to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments.
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>
 
    # Ensure Invoke-Obfuscation module was properly imported before continuing.
    If(!(Get-Module Invoke-Obfuscation))
    {
        $PathToPsm1 = "$ScriptDir\Invoke-Obfuscation.psm1"
        If($PathToPsm1.Contains(' ')) {$PathToPsm1 = '"' + $PathToPsm1 + '"'}
        Write-Host "`n`nERROR: Invoke-Obfuscation module is not loaded. You must run:" -ForegroundColor Red
        Write-Host "       Import-Module $PathToPsm1`n`n" -ForegroundColor Yellow
        Exit
    }

    # Maximum size for cmd.exe and clipboard.
    $CmdMaxLength = 8190
    
    # Build interactive menus.
    $LineSpacing = '[*] '
    
    # Main Menu.
    $MenuLevel  =   @()
    $MenuLevel += , @($LineSpacing, 'TOKEN'    , 'Obfuscate PowerShell command <Tokens>')
    $MenuLevel += , @($LineSpacing, 'STRING'   , 'Obfuscate entire command as a <String>')
    $MenuLevel += , @($LineSpacing, 'ENCODING' , 'Obfuscate entire command via <Encoding>')
    $MenuLevel += , @($LineSpacing, 'LAUNCHER' , 'Obfuscate command args w/<Launcher> techniques (run once at end)')
    
    # Main\Token Menu.
    $MenuLevel_Token               =   @()
    $MenuLevel_Token              += , @($LineSpacing, 'STRING'     , 'Obfuscate <String> tokens (suggested to run first)')
    $MenuLevel_Token              += , @($LineSpacing, 'COMMAND'    , 'Obfuscate <Command> tokens')
    $MenuLevel_Token              += , @($LineSpacing, 'ARGUMENT'   , 'Obfuscate <Argument> tokens')
    $MenuLevel_Token              += , @($LineSpacing, 'MEMBER'     , 'Obfuscate <Member> tokens')
    $MenuLevel_Token              += , @($LineSpacing, 'VARIABLE'   , 'Obfuscate <Variable> tokens')
    $MenuLevel_Token              += , @($LineSpacing, 'COMMENT'   , 'Remove all <Comment> tokens')
    $MenuLevel_Token              += , @($LineSpacing, 'WHITESPACE' , 'Insert random <Whitespace> (suggested to run last)')
    $MenuLevel_Token              += , @($LineSpacing, 'ALL   '     , 'Select <All> choices from above (random order)')
    
    $MenuLevel_Token_String        =   @()
    $MenuLevel_Token_String       += , @($LineSpacing, '1' , "Concatenate --> e.g. <('co'+'ffe'+'e')>"                           , @('Out-ObfuscatedTokenCommand', 'String', 1))
    $MenuLevel_Token_String       += , @($LineSpacing, '2' , "Reorder     --> e.g. <('{1}{0}'-f'ffee','co')>"                    , @('Out-ObfuscatedTokenCommand', 'String', 2))
    
    $MenuLevel_Token_Command       =   @()
    $MenuLevel_Token_Command      += , @($LineSpacing, '1' , 'Ticks                   --> e.g. <Ne`w-O`Bject>'                   , @('Out-ObfuscatedTokenCommand', 'Command', 1))
    $MenuLevel_Token_Command      += , @($LineSpacing, '2' , "Splatting + Concatenate --> e.g. <&('Ne'+'w-Ob'+'ject')>"          , @('Out-ObfuscatedTokenCommand', 'Command', 2))
    $MenuLevel_Token_Command      += , @($LineSpacing, '3' , "Splatting + Reorder     --> e.g. <&('{1}{0}'-f'bject','New-O')>"   , @('Out-ObfuscatedTokenCommand', 'Command', 3))
    
    $MenuLevel_Token_Argument      =   @()
    $MenuLevel_Token_Argument     += , @($LineSpacing, '1' , 'Random Case --> e.g. <nEt.weBclIenT>'                              , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 1))
    $MenuLevel_Token_Argument     += , @($LineSpacing, '2' , 'Ticks       --> e.g. <nE`T.we`Bc`lIe`NT>'                          , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 2))
    $MenuLevel_Token_Argument     += , @($LineSpacing, '3' , "Concatenate --> e.g. <('Ne'+'t.We'+'bClient')>"                    , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 3))
    $MenuLevel_Token_Argument     += , @($LineSpacing, '4' , "Reorder     --> e.g. <('{1}{0}'-f'bClient','Net.We')>"             , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 4))
    
    $MenuLevel_Token_Member        =   @()
    $MenuLevel_Token_Member       += , @($LineSpacing, '1' , 'Random Case --> e.g. <dOwnLoAdsTRing>'                             , @('Out-ObfuscatedTokenCommand', 'Member', 1))
    $MenuLevel_Token_Member       += , @($LineSpacing, '2' , 'Ticks       --> e.g. <d`Ow`NLoAd`STRin`g>'                         , @('Out-ObfuscatedTokenCommand', 'Member', 2))
    $MenuLevel_Token_Member       += , @($LineSpacing, '3' , "Concatenate --> e.g. <('dOwnLo'+'AdsT'+'Ring').Invoke()>"          , @('Out-ObfuscatedTokenCommand', 'Member', 3))
    $MenuLevel_Token_Member       += , @($LineSpacing, '4' , "Reorder     --> e.g. <('{1}{0}'-f'dString','Downloa').Invoke()>"   , @('Out-ObfuscatedTokenCommand', 'Member', 4))
    
    $MenuLevel_Token_Variable      =   @()
    $MenuLevel_Token_Variable     += , @($LineSpacing, '1' , 'Random Case + {} + Ticks --> e.g. <${c`hEm`eX}>'                   , @('Out-ObfuscatedTokenCommand', 'Variable', 1))
    
    $MenuLevel_Token_Whitespace    =   @()
    $MenuLevel_Token_Whitespace   += , @($LineSpacing, '1' , "`tRandom Whitespace --> e.g. <.( 'Ne'  +'w-Ob' +  'ject')>"        , @('Out-ObfuscatedTokenCommand', 'RandomWhitespace', 1))
    
    $MenuLevel_Token_Comment       =   @()
    $MenuLevel_Token_Comment      += , @($LineSpacing, '1' , "Remove Comments   --> e.g. self-explanatory"                       , @('Out-ObfuscatedTokenCommand', 'Comment', 1))

    $MenuLevel_Token_All           =   @()
    $MenuLevel_Token_All          += , @($LineSpacing, '1' , "`tExecute <ALL> Token obfuscation techniques (random order)"       , @('Out-ObfuscatedTokenCommandAll', '', ''))
    
    # Main\String Menu.
    $MenuLevel_String              =   @()
    $MenuLevel_String             += , @($LineSpacing, '1' , '<Concatenate> entire command'                                      , @('Out-ObfuscatedStringCommand', '', 1))
    $MenuLevel_String             += , @($LineSpacing, '2' , '<Reorder> entire command after concatenating'                      , @('Out-ObfuscatedStringCommand', '', 2))
    $MenuLevel_String             += , @($LineSpacing, '3' , '<Reverse> entire command after concatenating'                      , @('Out-ObfuscatedStringCommand', '', 3))

    # Main\Encoding Menu.
    $MenuLevel_Encoding            =   @()
    $MenuLevel_Encoding           += , @($LineSpacing, '1' , "`tEncode entire command as <ASCII>"                                , @('Out-EncodedAsciiCommand' , '', ''))
    $MenuLevel_Encoding           += , @($LineSpacing, '2' , "`tEncode entire command as <Hex>"                                  , @('Out-EncodedHexCommand'   , '', ''))
    $MenuLevel_Encoding           += , @($LineSpacing, '3' , "`tEncode entire command as <Octal>"                                , @('Out-EncodedOctalCommand' , '', ''))
    $MenuLevel_Encoding           += , @($LineSpacing, '4' , "`tEncode entire command as <Binary>"                               , @('Out-EncodedBinaryCommand', '', ''))
    $MenuLevel_Encoding           += , @($LineSpacing, '5' , "`tEncrypt entire command as <SecureString> (AES)"                  , @('Out-SecureStringCommand' , '', ''))

    # Main\Launcher Menu.
    $MenuLevel_Launcher            =   @()
    $MenuLevel_Launcher           += , @($LineSpacing, 'PS'            , "`t<PowerShell>")
    $MenuLevel_Launcher           += , @($LineSpacing, 'CMD'           , '<Cmd> + PowerShell')
    $MenuLevel_Launcher           += , @($LineSpacing, 'VAR'           , 'Cmd + set <Var> && PowerShell iex <Var>')
    $MenuLevel_Launcher           += , @($LineSpacing, 'STDIN'         , 'Cmd + <Echo> | PowerShell - (stdin)')
    $MenuLevel_Launcher           += , @($LineSpacing, 'VAR++'         , 'Cmd + set <Var> && Cmd && PowerShell iex <Var>')
    $MenuLevel_Launcher           += , @($LineSpacing, 'STDIN++'       , 'Cmd + set <Var> && Cmd <Echo> | PowerShell - (stdin)')

    $MenuLevel_Launcher_PS         =   @()
    $MenuLevel_Launcher_PS        += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_PS        += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS        += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS        += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS        += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS        += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS        += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS        += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS        += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS        += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '1'))

    $MenuLevel_Launcher_CMD        =   @()
    $MenuLevel_Launcher_CMD       += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_CMD       += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD       += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD       += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD       += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD       += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD       += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD       += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD       += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD       += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '2'))

    $MenuLevel_Launcher_VAR        =   @()
    $MenuLevel_Launcher_VAR       += , @('Enter string of numbers with all desired flags to pass to function. (e.g. 23459)', ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_VAR       += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_VAR       += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_VAR       += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_VAR       += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_VAR       += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_VAR       += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_VAR       += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_VAR       += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_VAR       += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '3'))

    $MenuLevel_Launcher_STDIN      =   @()
    $MenuLevel_Launcher_STDIN     += , @('Enter string of numbers with all desired flags to pass to function. (e.g. 23459)', ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_STDIN     += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_STDIN     += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_STDIN     += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_STDIN     += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_STDIN     += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_STDIN     += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_STDIN     += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_STDIN     += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_STDIN     += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '4'))

    ${MenuLevel_Launcher_VAR++}    =   @()
    ${MenuLevel_Launcher_VAR++}   += , @('Enter string of numbers with all desired flags to pass to function. (e.g. 23459)', ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_VAR++}   += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR++}   += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR++}   += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR++}   += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR++}   += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR++}   += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR++}   += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR++}   += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR++}   += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '5'))

    ${MenuLevel_Launcher_STDIN++}  =   @()
    ${MenuLevel_Launcher_STDIN++} += , @('Enter string of numbers with all desired flags to pass to function. (e.g. 23459)', ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '0' , "`tNO EXECUTION FLAGS"                                        , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '1' , "`t-NoExit"                                                   , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '2' , "`t-NonInteractive"                                           , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '3' , "`t-NoLogo"                                                   , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '4' , "`t-NoProfile"                                                , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '5' , "`t-Command"                                                  , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '6' , "`t-WindowStyle Hidden"                                       , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '7' , "`t-ExecutionPolicy Bypass"                                   , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '8' , "`t-Wow64 (to path 32-bit powershell.exe)"                    , @('Out-PowerShellLauncher', '', '6'))

    # Input options to display non-interactive menus or perform actions.
    $TutorialInputOptions         = @(@('tutorial')                            , "<Tutorial> of how to use this tool        `t")
    $MenuInputOptionsShowHelp     = @(@('help','get-help','?','-?','/?','menu'), "Show this <Help> Menu                     `t")
    $MenuInputOptionsShowOptions  = @(@('show options','show','options')       , "<Show options> for payload to obfuscate   `t")
    $ClearScreenInputOptions      = @(@('clear','clear-host','cls')            , "<Clear> screen                            `t")
    $CopyToClipboardInputOptions  = @(@('copy','clip','clipboard')             , "<Copy> ObfuscatedCommand to clipboard     `t")
    $OutputToDiskInputOptions     = @(@('out')                                 , "Write ObfuscatedCommand <Out> to disk     `t")
    $ExecutionInputOptions        = @(@('exec','execute','test','run')         , "<Execute> ObfuscatedCommand locally       `t")
    $ResetObfuscationInputOptions = @(@('reset')                               , "<Reset> obfuscation for ObfuscatedCommand `t")
    $BackCommandInputOptions      = @(@('back','cd ..')                        , "Go <Back> to previous obfuscation menu    `t")
    $ExitCommandInputOptions      = @(@('quit','exit')                         , "<Quit> Invoke-Obfuscation                 `t")
    $HomeMenuInputOptions         = @(@('home','main')                         , "Return to <Home> Menu                     `t")
    # For Version 1.0 ASCII art is not necessary.
    #$ShowAsciiArtInputOptions     = @(@('ascii')                               , "Display random <ASCII> art for the lulz :)`t")
    
    # Add all above input options lists to be displayed in SHOW OPTIONS menu.
    $AllAvailableInputOptionsLists   = @()
    $AllAvailableInputOptionsLists  += , $TutorialInputOptions
    $AllAvailableInputOptionsLists  += , $MenuInputOptionsShowHelp
    $AllAvailableInputOptionsLists  += , $MenuInputOptionsShowOptions
    $AllAvailableInputOptionsLists  += , $ClearScreenInputOptions
    $AllAvailableInputOptionsLists  += , $ExecutionInputOptions
    $AllAvailableInputOptionsLists  += , $CopyToClipboardInputOptions
    $AllAvailableInputOptionsLists  += , $OutputToDiskInputOptions
    $AllAvailableInputOptionsLists  += , $ResetObfuscationInputOptions
    $AllAvailableInputOptionsLists  += , $BackCommandInputOptions    
    $AllAvailableInputOptionsLists  += , $ExitCommandInputOptions
    $AllAvailableInputOptionsLists  += , $HomeMenuInputOptions
    # For Version 1.0 ASCII art is not necessary.
    #$AllAvailableInputOptionsLists  += , $ShowAsciiArtInputOptions

    # Input options to change interactive menus.
    $ExitInputOptions = $ExitCommandInputOptions[0]
    $MenuInputOptions = $BackCommandInputOptions[0]

    # Obligatory ASCII Art.
    Show-AsciiArt
    Start-Sleep -Seconds 2
    
    # Show Help Menu once at beginning of script.
    Show-HelpMenu
    
    # Main loop for user interaction. Show-Menu function displays current function along with acceptable input options (defined in arrays instantiated above).
    # User input and validation is handled within Show-Menu.
    $UserResponse = ''
    While($ExitInputOptions -NotContains ([String]$UserResponse).ToLower())
    {
        # Keep previous response for scenarios like $MenuInputOptions.
        If($HomeMenuInputOptions[0] -Contains ([String]$UserResponse).ToLower())
        {
            $UserResponse = ''
        }
        $LastUserResponse = $UserResponse

        # Display menu if it is defined in a menu variable with $UserResponse in the variable name.
        If(Get-Variable "MenuLevel$UserResponse" -ErrorAction SilentlyContinue)
        {
            $UserResponse = Show-Menu (Get-Variable "MenuLevel$UserResponse").Value $UserResponse $Script:OptionsMenu
        }
        Else
        {
            Write-Error "The variable MenuLevel$UserResponse does not exist."
            Exit
        }
    }
}


########################################
## Script-wide variable instantiation ##
########################################

# Script-level array of Show Options menu, set outside of functions so it can be set from within any of the functions.
# Build out menu for Show Options selection from user in Show-OptionsMenu menu.
$Script:ScriptPath   = ''
$Script:ScriptBlock  = ''
$Script:ExecutionCommands = ''
$Script:ObfuscatedCommand = ''
$Script:ObfuscationLength = ''
$Script:OptionsMenu  =   @()
$Script:OptionsMenu += , @('ScriptPath '       , $Script:ScriptPath, $TRUE)
$Script:OptionsMenu += , @('ScriptBlock'       , $Script:ScriptBlock, $TRUE)
$Script:OptionsMenu += , @('ExecutionCommands' , $Script:ExecutionCommands, $FALSE)
$Script:OptionsMenu += , @('ObfuscatedCommand' , $Script:ObfuscatedCommand, $FALSE)
$Script:OptionsMenu += , @('ObfuscationLength' , $Script:ObfuscatedCommand, $FALSE)
# Build out $SetInputOptions from above items set as $TRUE (as settable).
$SettableInputOptions = @()
ForEach($Option in $Script:OptionsMenu)
{
    If($Option[2]) {$SettableInputOptions += ([String]$Option[0]).ToLower().Trim()}
}

# Script-level variable for whether LAUNCHER has been applied to current ObfuscatedToken.
$Script:LauncherApplied = $FALSE

# Get location of this script no matter what the current directory is for the process executing this script.
$ScriptDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 


Function Show-Menu
{
<#
.SYNOPSIS

HELPER FUNCTION :: Displays current menu with obfuscation navigation and application options for Invoke-Obfuscation.

Invoke-Obfuscation Function: Show-Menu
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Show-Menu displays current menu with obfuscation navigation and application options for Invoke-Obfuscation.

.PARAMETER Menu

Specifies the menu options to display, with acceptable input options parsed out of this array.

.PARAMETER MenuName

Specifies the menu header display and the breadcrumb used in the interactive prompt display.

.PARAMETER Script:OptionsMenu

Specifies the script-wide variable containing additional acceptable input in addition to each menu's specific acceptable input (e.g. EXIT, QUIT, BACK, HOME, MAIN, etc.).

.EXAMPLE

C:\PS> Show-Menu

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    Param(
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $Menu,

        [String]
        $MenuName,

        [Object[]]
        $Script:OptionsMenu
    )

    # Extract all acceptable values from $Menu.
    $AcceptableInput = @()
    $SelectionContainsCommand = $FALSE
    ForEach($Line in $Menu)
    {
        # If there are 4 items in each $Line in $Menu then the fourth item is a command to exec if selected.
        If($Line.Count -eq 4)
        {
            $SelectionContainsCommand = $TRUE
        }
        $AcceptableInput += ($Line[1]).Trim(' ')
    }

    $UserInput = $NULL
    
    While($AcceptableInput -NotContains $UserInput)
    {
        # Format custom breadcrumb prompt.
        Write-Host "`n"
        $BreadCrumb = $MenuName.Trim('_')
        If($BreadCrumb.Length -gt 1)
        {
            If($BreadCrumb.ToLower() -eq 'show options')
            {
                $BreadCrumb = 'Show Options'
            }
            If($MenuName -ne '')
            {
                $BreadCrumbArray = @()
                ForEach($Crumb in $BreadCrumb.Split('_'))
                {
                    $BreadCrumbArray += $Crumb.SubString(0,1).ToUpper() + $Crumb.SubString(1).ToLower()
                }
                $BreadCrumb = $BreadCrumbArray -Join '\'
            }
            $BreadCrumb = '\' + $BreadCrumb
        }
        
        # Output menu heading.
        $FirstLine = "Choose one of the below "
        If($BreadCrumb -ne '')
        {
            $FirstLine = $FirstLine + $BreadCrumb.Trim('\') + ' '
        }
        Write-Host "$FirstLine" -NoNewLine
        
        # Change color and verbiage if selection will execute command.
        If($SelectionContainsCommand)
        {
            Write-Host "options" -NoNewLine -ForegroundColor Green
            Write-Host " to" -NoNewLine
            Write-Host " APPLY" -NoNewLine -ForegroundColor Green
            Write-Host " to current payload" -NoNewLine
        }
        Else
        {
            Write-Host "options" -NoNewLine -ForegroundColor Yellow
        }
        Write-Host ":`n"
    
        ForEach($Line in $Menu)
        {
            $LineSpace  = $Line[0]
            $LineOption = $Line[1]
            $LineValue  = $Line[2]
            Write-Host $LineSpace -NoNewLine

            # If not empty then include breadcrumb in $LineOption output (is not colored and won't affect user input syntax).
            If(($BreadCrumb -ne '') -AND ($LineSpace.StartsWith('[')))
            {
                Write-Host ($BreadCrumb.ToUpper().Trim('\') + '\') -NoNewLine
            }
            
            # Change color if selection will execute command.
            If($SelectionContainsCommand)
            {
                Write-Host $LineOption -NoNewLine -ForegroundColor Green
            }
            Else
            {
                Write-Host $LineOption -NoNewLine -ForegroundColor Yellow
            }
            
            # Add additional coloring to string encapsulated by <> if it exists in $LineValue.
            If($LineValue.Contains('<') -AND $LineValue.Contains('>'))
            {
                $FirstPart  = $LineValue.SubString(0,$LineValue.IndexOf('<'))
                $MiddlePart = $LineValue.SubString($FirstPart.Length+1)
                $MiddlePart = $MiddlePart.SubString(0,$MiddlePart.IndexOf('>'))
                $LastPart   = $LineValue.SubString($FirstPart.Length+$MiddlePart.Length+2)
                Write-Host "`t$FirstPart" -NoNewLine
                Write-Host $MiddlePart -NoNewLine -ForegroundColor Cyan

                # Handle if more than one term needs to be output in different color.
                If($LastPart.Contains('<') -AND $LastPart.Contains('>'))
                {
                    $LineValue  = $LastPart
                    $FirstPart  = $LineValue.SubString(0,$LineValue.IndexOf('<'))
                    $MiddlePart = $LineValue.SubString($FirstPart.Length+1)
                    $MiddlePart = $MiddlePart.SubString(0,$MiddlePart.IndexOf('>'))
                    $LastPart   = $LineValue.SubString($FirstPart.Length+$MiddlePart.Length+2)
                    Write-Host "$FirstPart" -NoNewLine
                    Write-Host $MiddlePart -NoNewLine -ForegroundColor Cyan
                }

                Write-Host $LastPart
            }
            Else
            {
                Write-Host "`t$LineValue"
            }
        }
        
        # Prompt for user input with custom breadcrumb prompt.
        Write-Host ''
        If($UserInput -ne '') {Write-Host ''}
        $UserInput = ''
        While($UserInput -eq '')
        {
            Write-Host "Invoke-Obfuscation$BreadCrumb> " -NoNewLine -ForegroundColor Magenta
            $UserInput = (Read-Host).Trim()
        }

        # If $UserInput is all numbers and is in a menu in $MenusWithMultiSelectNumbers
        $OverrideAcceptableInput = $FALSE
        $MenusWithMultiSelectNumbers = @('\Launcher')
        If(($UserInput.Trim(' 0123456789').Length -eq 0) -AND $BreadCrumb.Contains('\') -AND ($MenusWithMultiSelectNumbers -Contains $BreadCrumb.SubString(0,$BreadCrumb.LastIndexOf('\'))))
        {
            $OverrideAcceptableInput = $TRUE
        }
        
        If($ExitInputOptions -Contains $UserInput.ToLower())
        {
            Return $ExitInputOptions[0]
        }
        ElseIf($MenuInputOptions -Contains $UserInput.ToLower())
        {
            # Commands like 'back' that will return user to previous interactive menu.
            If($BreadCrumb.Contains('\')) {$UserInput = $BreadCrumb.SubString(0,$BreadCrumb.LastIndexOf('\')).Replace('\','_')}
            Else {$UserInput = ''}

            Return $UserInput.ToLower()
        }
        ElseIf($HomeMenuInputOptions[0] -Contains $UserInput.ToLower())
        {
            Return $UserInput.ToLower()
        }
        ElseIf($UserInput.ToLower().StartsWith('set '))
        {
            # Extract $UserInputOptionName and $UserInputOptionValue from $UserInput SET command.
            $UserInputOptionName  = $NULL
            $UserInputOptionValue = $NULL
            $HasError = $FALSE
    
            $UserInputMinusSet = $UserInput.SubString(4).Trim()
            If($UserInputMinusSet.IndexOf(' ') -eq -1)
            {
                $HasError = $TRUE
                $UserInputOptionName  = $UserInputMinusSet.Trim()
            }
            Else
            {
                $UserInputOptionName  = $UserInputMinusSet.SubString(0,$UserInputMinusSet.IndexOf(' ')).Trim().ToLower()
                $UserInputOptionValue = $UserInputMinusSet.SubString($UserInputMinusSet.IndexOf(' ')).Trim()
            }

            # Validate that $UserInputOptionName is defined in $SettableInputOptions.
            If($SettableInputOptions -Contains $UserInputOptionName)
            {
                # Perform separate validation for $UserInputOptionValue before setting value. Set to 'emptyvalue' if no value was entered.
                If($UserInputOptionValue -eq '') {$UserInputOptionName = 'emptyvalue'}
                Switch($UserInputOptionName.ToLower())
                {
                    'scriptpath' {
                        If($UserInputOptionValue -AND ((Test-Path $UserInputOptionValue) -OR ($UserInputOptionValue -Match '(http|https)://')))
                        {
                            # Reset ScriptBlock in case it contained a value.
                            $Script:ScriptBlock = ''
                        
                            # Check if user-input ScriptPath is a URL or a directory.
                            If($UserInputOptionValue -Match '(http|https)://')
                            {
                                # ScriptPath is a URL.
                            
                                # Download content.
                                $Script:ScriptBlock = (New-Object Net.WebClient).DownloadString($UserInputOptionValue)
                            
                                # Set script-wide variables for future reference.
                                $Script:ScriptPath = $UserInputOptionValue
                                $Script:ObfuscatedCommand = $Script:ScriptBlock
                                $Script:ExecutionCommands = ''
                                $Script:LauncherApplied = $FALSE
                            
                                Write-Host "`n`nSuccessfully set ScriptPath (as URL):" -ForegroundColor Cyan
                                Write-Host $Script:ScriptPath -ForegroundColor Magenta
                            }
                            ElseIf ((Get-Item $UserInputOptionValue) -is [System.IO.DirectoryInfo])
                            {
                                # ScriptPath does not exist.
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' Path is a directory instead of a file (' -NoNewLine
                                Write-Host "$UserInputOptionValue" -NoNewLine -ForegroundColor Cyan
                                Write-Host ").`n" -NoNewLine
                            }
                            Else
                            {
                                # Read contents from user-input ScriptPath value.
                                Get-ChildItem $UserInputOptionValue -ErrorAction Stop | Out-Null
                                $Script:ScriptBlock = [IO.File]::ReadAllText((Resolve-Path $UserInputOptionValue))
                        
                                # Set script-wide variables for future reference.
                                $Script:ScriptPath = $UserInputOptionValue
                                $Script:ObfuscatedCommand = $Script:ScriptBlock
                                $Script:ExecutionCommands = ''
                                $Script:LauncherApplied = $FALSE
                            
                                Write-Host "`n`nSuccessfully set ScriptPath:" -ForegroundColor Cyan
                                Write-Host $Script:ScriptPath -ForegroundColor Magenta
                            }
                        }
                        Else
                        {
                            # ScriptPath not found (failed Test-Path).
                            Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                            Write-Host ' Path not found (' -NoNewLine
                            Write-Host "$UserInputOptionValue" -NoNewLine -ForegroundColor Cyan
                            Write-Host ").`n" -NoNewLine
                        }
                    }
                    'scriptblock' {
                        # Remove evenly paired {} '' or "" if user includes it around their scriptblock input.
                        ForEach($Char in @(@('{','}'),@('"','"'),@("'","'")))
                        {
                            While($UserInputOptionValue.StartsWith($Char[0]) -AND $UserInputOptionValue.EndsWith($Char[1]))
                            {
                                $UserInputOptionValue = $UserInputOptionValue.SubString(1,$UserInputOptionValue.Length-2).Trim()
                            }
                        }

                        # Set script-wide variables for future reference.
                        $Script:ScriptPath        = 'N/A'
                        $Script:ScriptBlock       = $UserInputOptionValue
                        $Script:ObfuscatedCommand = $UserInputOptionValue
                        $Script:ExecutionCommands = ''
                        $Script:LauncherApplied = $FALSE
                    
                        Write-Host "`n`nSuccessfully set ScriptBlock:" -ForegroundColor Cyan
                        Write-Host $Script:ScriptBlock -ForegroundColor Magenta
                    }
                    'emptyvalue' {
                        # No OPTIONVALUE was entered after OPTIONNAME.
                        $HasError = $TRUE
                        Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                        Write-Host ' No value was entered after' -NoNewLine
                        Write-Host ' :' -NoNewLine -ForegroundColor Cyan
                        Write-Host '.' -NoNewLine
                    }
                    default {Write-Error "An invalid OPTIONNAME ($UserInputOptionName) was passed to switch block."; Exit}
                }
            }
            Else
            {
                $HasError = $TRUE
                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                Write-Host ' OPTIONNAME' -NoNewLine
                Write-Host " $UserInputOptionName" -NoNewLine -ForegroundColor Cyan
                Write-Host " is not a settable option." -NoNewLine
            }
    
            If($HasError)
            {
                Write-Host "`n       Correct syntax is" -NoNewLine
                Write-Host ' SET OPTIONNAME VALUE' -NoNewLine -ForegroundColor Green
                Write-Host '.' -NoNewLine
        
                Write-Host "`n       Enter" -NoNewLine
                Write-Host ' SHOW OPTIONS' -NoNewLine -ForegroundColor Yellow
                Write-Host ' for more details.'
            }
        }
        ElseIf(($AcceptableInput -Contains $UserInput) -OR ($OverrideAcceptableInput))
        {
            # User input matches $AcceptableInput extracted from the current $Menu, so decide if:
            # 1) an obfuscation function needs to be called and remain in current interactive prompt, or
            # 2) return value to enter into a new interactive prompt.
            
            # Format breadcrumb trail to successfully retrieve the next interactive prompt.
            $UserInput = $BreadCrumb.Trim('\').Replace('\','_') + '_' + $UserInput
            If($BreadCrumb.StartsWith('\')) {$UserInput = '_' + $UserInput}
            
            # If the current selection contains a command to execute then continue. Otherwise return to go to another menu.
            If($SelectionContainsCommand)
            {
                # Make sure user has entered command or path to script.
                If($Script:ObfuscatedCommand -ne $NULL)
                {
                    # Iterate through lines in $Menu to extract command for the current selection in $UserInput.
                    ForEach($Line in $Menu)
                    {
                        If($Line[1].Trim(' ') -eq $UserInput.SubString($UserInput.LastIndexOf('_')+1)) {$CommandToExec = $Line[3]; Continue}
                    }

                    If(!$OverrideAcceptableInput)
                    {
                        # Extract arguments from $CommandToExec.
                        $Function = $CommandToExec[0]
                        $Token    = $CommandToExec[1]
                        $ObfLevel = $CommandToExec[2]
                    }
                    Else
                    {
                        # Overload above arguments if $OverrideAcceptableInput is $TRUE, and extract $Function from $BreadCrumb
                        Switch($BreadCrumb.ToLower())
                        {
                            '\launcher\ps'      {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 1}
                            '\launcher\cmd'     {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 2}
                            '\launcher\var'     {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 3}
                            '\launcher\stdin'   {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 4}
                            '\launcher\var++'   {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 5}
                            '\launcher\stdin++' {$Function = 'Out-PowerShellLauncher'; $ObfLevel = 6}
                            default {Write-Error "An invalid value ($($BreadCrumb.ToLower())) was passed to switch block for setting `$Function when `$OverrideAcceptableInput -eq `$TRUE."; Exit}
                        }
                        # Extract $ObfLevel from first element in array (in case 0th element is used for informational purposes), and extract $Token from $BreadCrumb.
                        $ObfLevel = $Menu[1][3][2]
                        $Token = $UserInput.SubString($UserInput.LastIndexOf('_')+1)
                    }
                    
                    # Convert ObfuscatedCommand (string) to ScriptBlock for next obfuscation function.
                    $ObfCommandScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock($Script:ObfuscatedCommand)
                    
                    # Validate that user has set SCRIPTPATH or SCRIPTBLOCK (by seeing if $Script:ObfuscatedCommand is empty).
                    If($Script:ObfuscatedCommand -eq '')
                    {
                        Write-Host "`n`nERROR: Cannot execute obfuscation commands without setting ScriptPath or ScriptBlock values in SHOW OPTIONS menu. Set these by executing" -NoNewLine -ForegroundColor Red
                        Write-Host ' SET SCRIPTBLOCK script_block_or_command' -NoNewLine -ForegroundColor Green
                        Write-Host ' or' -NoNewLine -ForegroundColor Red
                        Write-Host ' SET SCRIPTPATH path_to_script_or_URL' -NoNewLine -ForegroundColor Green
                        Write-Host '.' -ForegroundColor Red
                        Continue
                    }

                    # Switch block to route to the correct function.
                    $CmdToPrint = $NULL
                    $BeforeAndAfterTheSame = $FALSE
                    Switch($Function)
                    {
                        'Out-ObfuscatedTokenCommand'    {
                            If($Script:LauncherApplied)
                            {
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' You cannot obfuscate after applying a Launcher to ObfuscatedCommand.' -NoNewLine
                                Write-Host "`n       Enter" -NoNewLine
                                Write-Host ' RESET' -NoNewLine -ForegroundColor Yellow
                                Write-Host " to remove obfuscation from ObfuscatedCommand.`n" -NoNewLine
                            }
                            Else
                            {
                                $ObfuscatedCommandBefore = $Script:ObfuscatedCommand
                                $Script:ObfuscatedCommand = Out-ObfuscatedTokenCommand  -ScriptBlock $ObfCommandScriptBlock $Token $ObfLevel
                                $CmdToPrint = @("Out-ObfuscatedTokenCommand -ScriptBlock "," '$Token' $ObfLevel")
                                If($Script:ObfuscatedCommand -eq $ObfuscatedCommandBefore) {$BeforeAndAfterTheSame = $TRUE}
                            }
                        }
                        'Out-ObfuscatedTokenCommandAll' {
                            If($Script:LauncherApplied)
                            {
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' You cannot obfuscate after applying a Launcher to ObfuscatedCommand.' -NoNewLine
                                Write-Host "`n       Enter" -NoNewLine
                                Write-Host ' RESET' -NoNewLine -ForegroundColor Yellow
                                Write-Host " to remove obfuscation from ObfuscatedCommand.`n" -NoNewLine
                            }
                            Else
                            {
                                $ObfuscatedCommandBefore = $Script:ObfuscatedCommand
                                $Script:ObfuscatedCommand = Out-ObfuscatedTokenCommand  -ScriptBlock $ObfCommandScriptBlock
                                $CmdToPrint = @("Out-ObfuscatedTokenCommand -ScriptBlock ","")
                                If($Script:ObfuscatedCommand -eq $ObfuscatedCommandBefore) {$BeforeAndAfterTheSame = $TRUE}
                            }
                        }
                        'Out-ObfuscatedStringCommand'   {
                            If($Script:LauncherApplied)
                            {
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' You cannot obfuscate after applying a Launcher to ObfuscatedCommand.' -NoNewLine
                                Write-Host "`n       Enter" -NoNewLine
                                Write-Host ' RESET' -NoNewLine -ForegroundColor Yellow
                                Write-Host " to remove obfuscation from ObfuscatedCommand.`n" -NoNewLine
                            }
                            Else
                            {
                                $Script:ObfuscatedCommand = Out-ObfuscatedStringCommand -ScriptBlock $ObfCommandScriptBlock $ObfLevel
                                $CmdToPrint = @("Out-ObfuscatedStringCommand -ScriptBlock "," $ObfLevel")
                            }
                        }
                        'Out-EncodedAsciiCommand'       {
                            If($Script:LauncherApplied)
                            {
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' You cannot obfuscate after applying a Launcher to ObfuscatedCommand.' -NoNewLine
                                Write-Host "`n       Enter" -NoNewLine
                                Write-Host ' RESET' -NoNewLine -ForegroundColor Yellow
                                Write-Host " to remove obfuscation from ObfuscatedCommand.`n" -NoNewLine
                            }
                            Else
                            {
                                $Script:ObfuscatedCommand = Out-EncodedAsciiCommand     -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedAsciiCommand -ScriptBlock "," -PassThru")
                            }
                        }
                        'Out-EncodedHexCommand'         {
                            If($Script:LauncherApplied)
                            {
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' You cannot obfuscate after applying a Launcher to ObfuscatedCommand.' -NoNewLine
                                Write-Host "`n       Enter" -NoNewLine
                                Write-Host ' RESET' -NoNewLine -ForegroundColor Yellow
                                Write-Host " to remove obfuscation from ObfuscatedCommand.`n" -NoNewLine
                            }
                            Else
                            {
                                $Script:ObfuscatedCommand = Out-EncodedHexCommand     -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedHexCommand -ScriptBlock "," -PassThru")
                            }
                        }
                        'Out-EncodedOctalCommand'       {
                            If($Script:LauncherApplied)
                            {
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' You cannot obfuscate after applying a Launcher to ObfuscatedCommand.' -NoNewLine
                                Write-Host "`n       Enter" -NoNewLine
                                Write-Host ' RESET' -NoNewLine -ForegroundColor Yellow
                                Write-Host " to remove obfuscation from ObfuscatedCommand.`n" -NoNewLine
                            }
                            Else
                            {
                                $Script:ObfuscatedCommand = Out-EncodedOctalCommand     -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedOctalCommand -ScriptBlock "," -PassThru")
                            }
                        }
                        'Out-EncodedBinaryCommand'      {
                            If($Script:LauncherApplied)
                            {
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' You cannot obfuscate after applying a Launcher to ObfuscatedCommand.' -NoNewLine
                                Write-Host "`n       Enter" -NoNewLine
                                Write-Host ' RESET' -NoNewLine -ForegroundColor Yellow
                                Write-Host " to remove obfuscation from ObfuscatedCommand.`n" -NoNewLine
                            }
                            Else
                            {
                                $Script:ObfuscatedCommand = Out-EncodedBinaryCommand     -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedBinaryCommand -ScriptBlock "," -PassThru")
                            }
                        }
                        'Out-SecureStringCommand'       {
                            If($Script:LauncherApplied)
                            {
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' You cannot obfuscate after applying a Launcher to ObfuscatedCommand.' -NoNewLine
                                Write-Host "`n       Enter" -NoNewLine
                                Write-Host ' RESET' -NoNewLine -ForegroundColor Yellow
                                Write-Host " to remove obfuscation from ObfuscatedCommand.`n" -NoNewLine
                            }
                            Else
                            {
                                $Script:ObfuscatedCommand = Out-SecureStringCommand     -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-SecureStringCommand -ScriptBlock "," -PassThru")
                            }
                        }
                        'Out-PowerShellLauncher'        {
                            If($Script:LauncherApplied)
                            {
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' You have already applied a launcher to ObfuscatedCommand.' -NoNewLine
                                Write-Host "`n       Enter" -NoNewLine
                                Write-Host ' RESET' -NoNewLine -ForegroundColor Yellow
                                Write-Host " to remove obfuscation from ObfuscatedCommand.`n" -NoNewLine
                            }
                            Else
                            {   
                                # Extract numbers from string so we an output proper flag syntax in ExecutionCommands history.
                                $SwitchesAsStringArray = [char[]]$Token | Sort-Object -Unique | Where-Object {$_ -ne ' '}
                                
                                If($SwitchesAsStringArray -Contains '0')
                                {
                                    $CmdToPrint = @("Out-PowerShellLauncher -ScriptBlock "," $ObfLevel")
                                }
                                Else
                                {
                                    $HasWindowStyle = $FALSE
                                    $SwitchesToPrint = @()
                                    ForEach($Value in $SwitchesAsStringArray)
                                    {
                                        Switch($Value)
                                        {
                                            1 {$SwitchesToPrint += '-NoExit'}
                                            2 {$SwitchesToPrint += '-NonInteractive'}
                                            3 {$SwitchesToPrint += '-NoLogo'}
                                            4 {$SwitchesToPrint += '-NoProfile'}
                                            5 {If(!$HasWindowStyle) {$SwitchesToPrint += '-WindowStyle Hidden'   ; $HasWindowStyle = $TRUE}}
                                            6 {If(!$HasWindowStyle) {$SwitchesToPrint += '-WindowStyle Minimized'; $HasWindowStyle = $TRUE}}
                                            7 {If(!$HasWindowStyle) {$SwitchesToPrint += '-WindowStyle Normal'   ; $HasWindowStyle = $TRUE}}
                                            8 {If(!$HasWindowStyle) {$SwitchesToPrint += '-WindowStyle Maximized'; $HasWindowStyle = $TRUE}}
                                            9 {$SwitchesToPrint += '-Wow64'}
                                            default {Write-Error "An invalid `$SwitchesAsString value ($Value) was passed to switch block."; Exit;}
                                        }
                                    }
                                    $SwitchesToPrint =  $SwitchesToPrint -Join ' '
                                    $CmdToPrint = @("Out-PowerShellLauncher -ScriptBlock "," $SwitchesToPrint $ObfLevel")
                                }
                                
                                $PreviousObfuscatedCommand = $Script:ObfuscatedCommand
                                $Script:ObfuscatedCommand = Out-PowerShellLauncher      -ScriptBlock $ObfCommandScriptBlock -SwitchesAsString $Token $ObfLevel
                                
                                # Only set LauncherApplied to true if before/after are different (i.e. no warnings prevented launcher from being applied).
                                If($PreviousObfuscatedCommand -ne $Script:ObfuscatedCommand)
                                {
                                    $Script:LauncherApplied = $TRUE
                                }
                            }
                        }
                        default {Write-Error "An invalid `$Function value ($Function) was passed to switch block."; Exit;}
                    }
                    
                    If($CmdToPrint)
                    {
                        # Add execution syntax to $Script:ExecutionCommands to maintain a history of commands to arrive at current obfuscated command.
                        $Script:ExecutionCommands += ($CmdToPrint[0] + '$ScriptBlock' + $CmdToPrint[1] + ';')
                        
                        # Output syntax of command we executed in above Switch block.
                        Write-Host "`nExecuted:`t"
                        Write-Host $CmdToPrint[0] -NoNewLine -ForegroundColor Cyan
                        Write-Host '$ScriptBlock' -NoNewLine -ForegroundColor Magenta
                        Write-Host $CmdToPrint[1] -ForegroundColor Cyan
                            
                        # Output obfuscation result.
                        Write-Host "`nResult:`t"
                        Out-ScriptContents $Script:ObfuscatedCommand -PrintWarning
                    }
                    If($BeforeAndAfterTheSame)
                    {
                        Write-Host "`nWARNING:" -NoNewLine -ForegroundColor Red
                        Write-Host " There were not any" -NoNewLine
                        If($BreadCrumb.SubString($BreadCrumb.LastIndexOf('\')+1).ToLower() -ne 'all') {Write-Host " $($BreadCrumb.SubString($BreadCrumb.LastIndexOf('\')+1))" -NoNewLine -ForegroundColor Yellow}
                        Write-Host " tokens to further obfuscate, so nothing changed."
                    }
                    
                }
            }
            Else
            {
                Return $UserInput
            }
        }
        Else
        {
            If    ($MenuInputOptionsShowHelp[0]     -Contains $UserInput) {Show-HelpMenu}
            ElseIf($MenuInputOptionsShowOptions[0]  -Contains $UserInput) {Show-OptionsMenu}
            ElseIf($TutorialInputOptions[0]         -Contains $UserInput) {Show-Tutorial}
            ElseIf($ClearScreenInputOptions[0]      -Contains $UserInput) {Clear-Host}
            # For Version 1.0 ASCII art is not necessary.
            #ElseIf($ShowAsciiArtInputOptions[0]     -Contains $UserInput) {Show-AsciiArt -Random}
            ElseIf($ResetObfuscationInputOptions[0] -Contains $UserInput)
            {
                $Script:LauncherApplied = $FALSE
                $Script:ObfuscatedCommand = $Script:ScriptBlock
                $Script:ExecutionCommands = ''
                Write-Host "`n`nSuccessfully reset ObfuscatedCommand." -ForegroundColor Cyan
            }
            ElseIf($OutputToDiskInputOptions[0]  -Contains $UserInput)
            {
                If(($Script:ObfuscatedCommand -ne '') -AND ($Script:ObfuscatedCommand -eq $Script:ScriptBlock))
                {
                    Write-Host "`n`nWARNING: You haven't applied any obfuscation.`n         Just enter" -NoNewLine -ForegroundColor Red
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at" -NoNewLine -ForegroundColor Red
                    Write-Host " ObfuscatedCommand." -ForegroundColor Red
                }
                ElseIf($Script:ObfuscatedCommand -ne '')
                {

                
                    # Get file path information from user input.
                    $UserInputOutputFilePath = Read-Host "`n`nEnter path for output file (or leave blank for default)"
                    
                    # Decipher if user input a full file path, just a file name or nothing (default).
                    If($UserInputOutputFilePath.Trim() -eq '')
                    {
                        # User did not input anything so use default filename and current directory of this script.
                        $OutputFilePath = "$ScriptDir\Obfuscated_Command.txt"
                    }
                    ElseIf(!($UserInputOutputFilePath.Contains('\')) -AND !($UserInputOutputFilePath.Contains('/')))
                    {
                        # User input is not a file path so treat it as a filename and use current directory of this script.
                        $OutputFilePath = "$ScriptDir\$($UserInputOutputFilePath.Trim())"
                    }
                    Else
                    {
                        # User input is a full file path.
                        $OutputFilePath = $UserInputOutputFilePath
                    }
                    
                    # Write ObfuscatedCommand out to disk.
                    Write-Output $Script:ObfuscatedCommand > $OutputFilePath

                    If($Script:LauncherApplied -AND (Test-Path $OutputFilePath))
                    {
                        Write-Host "`nSuccessfully output ObfuscatedCommand to" -NoNewLine -ForegroundColor Cyan
                        Write-Host " $OutputFilePath" -NoNewLine -ForegroundColor Yellow
                        Write-Host ".`nA Launcher has been applied so this script cannot be run as a standalone .ps1 file." -ForegroundColor Cyan
C:\Windows\Notepad.exe $OutputFilePath
                    }
                    ElseIf(!$Script:LauncherApplied -AND (Test-Path $OutputFilePath))
                    {
                        Write-Host "`nSuccessfully output ObfuscatedCommand to" -NoNewLine -ForegroundColor Cyan
                        Write-Host " $OutputFilePath" -NoNewLine -ForegroundColor Yellow
                        Write-Host "." -ForegroundColor Cyan
C:\Windows\Notepad.exe $OutputFilePath
                    }
                    Else
                    {
                        Write-Host "`nERROR: Unable to write ObfuscatedCommand out to" -NoNewLine -ForegroundColor Red
                        Write-Host " $OutputFilePath" -NoNewLine -ForegroundColor Yellow
                    }
                }
                ElseIf($Script:ObfuscatedCommand -eq '')
                {
                    Write-Host "`n`nERROR: There isn't anything to write out to disk.`n       Just enter" -NoNewLine -ForegroundColor Red
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at" -NoNewLine -ForegroundColor Red
                    Write-Host " ObfuscatedCommand." -ForegroundColor Red
                }
            }
            ElseIf($CopyToClipboardInputOptions[0]  -Contains $UserInput)
            {
                If(($Script:ObfuscatedCommand -ne '') -AND ($Script:ObfuscatedCommand -eq $Script:ScriptBlock))
                {
                    Write-Host "`n`nWARNING: You haven't applied any obfuscation.`n         Just enter" -NoNewLine -ForegroundColor Red
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at" -NoNewLine -ForegroundColor Red
                    Write-Host " ObfuscatedCommand." -ForegroundColor Red
                }
                ElseIf($Script:ObfuscatedCommand.Length -gt $CmdMaxLength)
                {
                    Write-Host "`n`nERROR: ObfuscatedCommand length (" -NoNewLine -ForegroundColor Red
                    Write-Host "$($Script:ObfuscatedCommand.Length)" -NoNewLine -ForegroundColor Yellow
                    Write-Host ") exceeds cmd.exe limit ($CmdMaxLength)." -ForegroundColor Red
                    Write-Host "       Enter" -NoNewLine -ForegroundColor Red
                    Write-Host " OUT" -NoNewLine -ForegroundColor Yellow
                    Write-Host " to write ObfuscatedCommand out to disk." -NoNewLine -ForegroundColor Red
                }
                ElseIf($Script:ObfuscatedCommand -ne '')
                {
                    # Copy ObfuscatedCommand to clipboard.
                    $null = [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
                    [Windows.Forms.Clipboard]::SetText($Script:ObfuscatedCommand) 
                    
                    If($Script:LauncherApplied)
                    {
                        Write-Host "`n`nSuccessfully copied ObfuscatedCommand to clipboard. Ready to paste into cmd.exe." -ForegroundColor Cyan
                    }
                    Else
                    {
                        Write-Host "`n`nSuccessfully copied ObfuscatedCommand to clipboard.`nNo Launcher has been applied, so command can only be pasted into powershell.exe." -ForegroundColor Cyan
                    }
                }
                ElseIf($Script:ObfuscatedCommand -eq '')
                {
                    Write-Host "`n`nERROR: There isn't anything to copy to your clipboard.`n       Just enter" -NoNewLine -ForegroundColor Red
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at" -NoNewLine -ForegroundColor Red
                    Write-Host " ObfuscatedCommand." -ForegroundColor Red
                }
                
            }
            ElseIf($ExecutionInputOptions[0]        -Contains $UserInput)
            {
                If($Script:LauncherApplied)
                {
                    Write-Host "`n`nERROR: Cannot execute because you have applied a Launcher.`n       Enter" -NoNewLine -ForegroundColor Red
                    Write-Host " COPY" -NoNewLine -ForeGroundColor Yellow
                    Write-Host "/" -NoNewLine -ForeGroundColor Red
                    Write-Host "CLIP" -NoNewLine -ForeGroundColor Yellow
                    Write-Host " and paste into cmd.exe.`n       Or enter" -NoNewLine -ForeGroundColor Red
                    Write-Host " RESET" -NoNewLine -ForeGroundColor Yellow
                    Write-Host " to remove obfuscation from ObfuscatedCommand." -ForeGroundColor Red
                }
                ElseIf($Script:ObfuscatedCommand -ne '')
                {
                    If($Script:ObfuscatedCommand -eq $Script:ScriptBlock) {Write-Host "`n`nInvoking (though you haven't obfuscated anything yet):"}
                    Else {Write-Host "`n`nInvoking:"}
                    
                    Out-ScriptContents $Script:ObfuscatedCommand
                    Write-Host ''
                    $null = Invoke-Expression $Script:ObfuscatedCommand
                }
                Else {
                    Write-Host "`n`nERROR: Cannot execute because you have not set ScriptPath or ScriptBlock.`n       Enter" -NoNewLine -ForegroundColor Red
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " to set ScriptPath or ScriptBlock." -ForegroundColor Red
                }
            }
            Else
            {
                Write-Host "`n`nERROR: You entered an invalid option. Enter" -NoNewLine -ForegroundColor Red
                Write-Host " HELP" -NoNewLine -ForegroundColor Yellow
                Write-Host " for more information." -ForegroundColor Red

                # Output all available/acceptable options for current menu if invalid input was entered.
                If($AcceptableInput.Count -gt 1)
                {
                    $Message = 'Valid options for current menu include:'
                }
                Else
                {
                    $Message = 'Valid option for current menu includes:'
                }
                Write-Host "       $Message " -NoNewLine -ForegroundColor Red

                $Counter=0
                ForEach($AcceptableOption in $AcceptableInput)
                {
                    $Counter++

                    # Change color and verbiage if acceptable options will execute an obfuscation function.
                    If($SelectionContainsCommand)
                    {
                        $ColorToOutput = 'Green'
                    }
                    Else
                    {
                        $ColorToOutput = 'Yellow'
                    }

                    Write-Host $AcceptableOption -NoNewLine -ForegroundColor $ColorToOutput
                    If(($Counter -lt $AcceptableInput.Length) -AND ($AcceptableOption.Length -gt 0))
                    {
                        Write-Host ', ' -NoNewLine
                    }
                }
                Write-Host ''
            }
        }
        
    }
    
    Return $UserInput.ToLower()
}


Function Show-OptionsMenu
{
<#
.SYNOPSIS

HELPER FUNCTION :: Displays options menu for Invoke-Obfuscation.

Invoke-Obfuscation Function: Show-OptionsMenu
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Show-OptionsMenu displays options menu for Invoke-Obfuscation.

.EXAMPLE

C:\PS> Show-OptionsMenu

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    # Set potentially-updated script-level values in $Script:OptionsMenu before displaying.
    $Counter = 0
    ForEach($Line in $Script:OptionsMenu)
    {
        If($Line[0].ToLower().Trim() -eq 'scriptpath')            {$Script:OptionsMenu[$Counter][1] = $Script:ScriptPath}
        If($Line[0].ToLower().Trim() -eq 'scriptblock')           {$Script:OptionsMenu[$Counter][1] = $Script:ScriptBlock}
        If($Line[0].ToLower().Trim() -eq 'executioncommands')     {$Script:OptionsMenu[$Counter][1] = $Script:ExecutionCommands}
        If($Line[0].ToLower().Trim() -eq 'obfuscatedcommand')
        {
            # Only add obfuscatedcommand if it is different than scriptblock (to avoid showing obfuscatedcommand before it has been obfuscated).
            If($Script:ObfuscatedCommand -ne $Script:ScriptBlock) {$Script:OptionsMenu[$Counter][1] = $Script:ObfuscatedCommand}
            Else {$Script:OptionsMenu[$Counter][1] = ''}
        }
        If($Line[0].ToLower().Trim() -eq 'obfuscationlength')
        {
            # Only set/display ObfuscationLength if there is an obfuscated command.
            If(($Script:ObfuscatedCommand.Length -gt 0) -AND ($Script:ObfuscatedCommand -ne $Script:ScriptBlock)) {$Script:OptionsMenu[$Counter][1] = $Script:ObfuscatedCommand.Length}
            Else {$Script:OptionsMenu[$Counter][1] = ''}
        }

        $Counter++
    }
    
    # Output menu.
    Write-Host "`n`nSHOW OPTIONS" -NoNewLine -ForegroundColor Cyan
    Write-Host " ::" -NoNewLine
    Write-Host " Yellow" -NoNewLine -ForegroundColor Yellow
    Write-Host " options can be set by entering" -NoNewLine
    Write-Host " SET OPTIONNAME VALUE" -NoNewLine -ForegroundColor Green
    Write-Host ".`n"
    ForEach($Option in $Script:OptionsMenu)
    {
        $OptionTitle = $Option[0]
        $OptionValue = $Option[1]
        $CanSetValue = $Option[2]
        
        Write-Host $LineSpacing -NoNewLine
        
        # For options that can be set by user, output as Yellow.
        If($CanSetValue) {Write-Host $OptionTitle -NoNewLine -ForegroundColor Yellow}
        Else {Write-Host $OptionTitle -NoNewLine}
        Write-Host ": " -NoNewLine
        
        # Handle coloring and multi-value output for ExecutionCommands and ObfuscationLength.
        If($OptionTitle -eq 'ObfuscationLength')
        {
            Write-Host $OptionValue -ForegroundColor Cyan
        }
        ElseIf($OptionTitle -eq 'ScriptBlock')
        {
            Out-ScriptContents $OptionValue
        }
        ElseIf($OptionTitle -eq 'ExecutionCommands')
        {
            # ExecutionCommands output.
            If($Script:ExecutionCommands -ne '') {Write-Host ''}
            $Counter = 0
            ForEach($ExecutionCommand in $Script:ExecutionCommands.Split(';'))
            {
                $Counter++
                If($ExecutionCommand.Length -eq 0) {Write-Host ""; Continue}
            
                $ExecutionCommand = $ExecutionCommand.Replace('$ScriptBlock','~').Split('~')
                Write-Host "    $($ExecutionCommand[0])" -NoNewLine -ForegroundColor Cyan
                Write-Host '$ScriptBlock' -NoNewLine -ForegroundColor Magenta
                
                # Handle output formatting when SHOW OPTIONS is run.
                If(($Script:ExecutionCommands.Split(';').Count-1 -gt 0) -AND ($Counter -lt $Script:ExecutionCommands.Split(';').Count-1))
                {
                    Write-Host " $($ExecutionCommand[1])" -ForegroundColor Cyan
                }
                Else
                {
                    Write-Host " $($ExecutionCommand[1])" -NoNewLine -ForegroundColor Cyan
                }

            }
        }
        ElseIf($OptionTitle -eq 'ObfuscatedCommand')
        {
            Out-ScriptContents $OptionValue
        }
        Else
        {
            Write-Host $OptionValue -ForegroundColor Magenta
        }
    }
    
}


Function Show-HelpMenu
{
<#
.SYNOPSIS

HELPER FUNCTION :: Displays help menu for Invoke-Obfuscation.

Invoke-Obfuscation Function: Show-HelpMenu
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Show-HelpMenu displays help menu for Invoke-Obfuscation.

.EXAMPLE

C:\PS> Show-HelpMenu

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    # Show Help Menu.
    Write-Host "`n`nHELP MENU" -NoNewLine -ForegroundColor Cyan
    Write-Host " :: Available" -NoNewLine
    Write-Host " options" -NoNewLine -ForegroundColor Yellow
    Write-Host " shown below:`n"
    ForEach($InputOptionsList in $AllAvailableInputOptionsLists)
    {
        $InputOptionsCommands    = $InputOptionsList[0]
        $InputOptionsDescription = $InputOptionsList[1]

        # Add additional coloring to string encapsulated by <> if it exists in $InputOptionsDescription.
        If($InputOptionsDescription.Contains('<') -AND $InputOptionsDescription.Contains('>'))
        {
            $FirstPart  = $InputOptionsDescription.SubString(0,$InputOptionsDescription.IndexOf('<'))
            $MiddlePart = $InputOptionsDescription.SubString($FirstPart.Length+1)
            $MiddlePart = $MiddlePart.SubString(0,$MiddlePart.IndexOf('>'))
            $LastPart   = $InputOptionsDescription.SubString($FirstPart.Length+$MiddlePart.Length+2)
            Write-Host "$LineSpacing $FirstPart" -NoNewLine
            Write-Host $MiddlePart -NoNewLine -ForegroundColor Cyan
            Write-Host $LastPart -NoNewLine
        }
        Else
        {
            Write-Host "$LineSpacing $InputOptionsDescription" -NoNewLine
        }
        
        $Counter = 0
        ForEach($Command in $InputOptionsCommands)
        {
            $Counter++
            Write-Host $Command.ToUpper() -NoNewLine -ForegroundColor Yellow
            If($Counter -lt $InputOptionsCommands.Count) {Write-Host ',' -NoNewLine}
        }
        Write-Host ''
    }
}


Function Show-Tutorial
{
<#
.SYNOPSIS

HELPER FUNCTION :: Displays tutorial information for Invoke-Obfuscation.

Invoke-Obfuscation Function: Show-Tutorial
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Show-Tutorial displays tutorial information for Invoke-Obfuscation.

.EXAMPLE

C:\PS> Show-Tutorial

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    Write-Host "`n`nTUTORIAL" -NoNewLine -ForegroundColor Cyan
    Write-Host " :: Here is a quick tutorial showing you how to get your obfuscation on:"
    
    Write-Host "`n1) " -NoNewLine -ForegroundColor Cyan
    Write-Host "Load a scriptblock (SET SCRIPTBLOCK) or a script path/URL (SET SCRIPTPATH)."
    Write-Host "   SET SCRIPTBLOCK Write-Host 'This is my test command' -ForegroundColor Green" -ForegroundColor Green
    
    Write-Host "`n2) " -NoNewLine -ForegroundColor Cyan
    Write-Host "Navigate through the obfuscation menus where the options are in" -NoNewLine
    Write-Host " YELLOW" -NoNewLine -ForegroundColor Yellow
    Write-Host "."
    Write-Host "   GREEN" -NoNewLine -ForegroundColor Green
    Write-Host " options apply obfuscation."
    Write-Host "   Enter" -NoNewLine
    Write-Host " BACK" -NoNewLine -ForegroundColor Yellow
    Write-Host "/" -NoNewLine
    Write-Host "CD .." -NoNewLine -ForegroundColor Yellow
    Write-Host " to go to previous menu and" -NoNewLine
    Write-Host " HOME" -NoNewline -ForegroundColor Yellow
    Write-Host "/" -NoNewline
    Write-Host "MAIN" -NoNewline -ForegroundColor Yellow
    Write-Host " to go to home menu.`n   E.g. Enter" -NoNewLine
    Write-Host " ENCODING" -NoNewLine -ForegroundColor Yellow
    Write-Host " & then" -NoNewLine
    Write-Host " 5" -NoNewLine -ForegroundColor Green
    Write-Host " to apply SecureString obfuscation."
    
    Write-Host "`n3) " -NoNewLine -ForegroundColor Cyan
    Write-Host "Enter" -NoNewLine
    Write-Host " TEST" -NoNewLine -ForegroundColor Yellow
    Write-Host "/" -NoNewLine
    Write-Host "EXEC" -NoNewLine -ForegroundColor Yellow
    Write-Host " to test the obfuscated command locally.`n   Enter" -NoNewLine
    Write-Host " SHOW" -NoNewLine -ForegroundColor Yellow
    Write-Host " to see the currently obfuscated command."
    
    Write-Host "`n4) " -NoNewLine -ForegroundColor Cyan
    Write-Host "Enter" -NoNewLine
    Write-Host " COPY" -NoNewLine -ForegroundColor Yellow
    Write-Host "/" -NoNewLine
    Write-Host "CLIP" -NoNewLine -ForegroundColor Yellow
    Write-Host " to copy obfuscated command out to your clipboard."
    Write-Host "   Enter" -NoNewLine
    Write-Host " OUT" -NoNewLine -ForegroundColor Yellow
    Write-Host " to write obfuscated command out to disk."
    
    Write-Host "`n5) " -NoNewLine -ForegroundColor Cyan
    Write-Host "Enter" -NoNewLine
    Write-Host " RESET" -NoNewLine -ForegroundColor Yellow
    Write-Host " to remove all obfuscation and start over.`n   Enter" -NoNewLine
    Write-Host " HELP" -NoNewLine -ForegroundColor Yellow
    Write-Host "/" -NoNewLine
    Write-Host "?" -NoNewLine -ForegroundColor Yellow
    Write-Host " for help menu."
    
    Write-Host "`nAnd finally the obligatory `"Don't use this for evil, please`"" -NoNewLine -ForegroundColor Cyan
    Write-Host " :)" -ForegroundColor Green
}


Function Out-ScriptContents
{
<#
.SYNOPSIS

HELPER FUNCTION :: Displays current obfuscated command for Invoke-Obfuscation.

Invoke-Obfuscation Function: Out-ScriptContents
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-ScriptContents displays current obfuscated command for Invoke-Obfuscation.

.PARAMETER ScriptContents

Specifies the string containing your payload.

.PARAMETER PrintWarning

Switch to output redacted form of ScriptContents if they exceed 8,190 characters.

.EXAMPLE

C:\PS> Out-ScriptContents

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $ScriptContents,

        [Switch]
        $PrintWarning
    )

    If($ScriptContents.Length -gt $CmdMaxLength)
    {
        # Output ScriptContents, handling if the size of ScriptContents exceeds $CmdMaxLength characters.
        $RedactedPrintLength = $CmdMaxLength/5
        
        # Handle printing redaction message in middle of screen. #OCD
        $CmdLineWidth = (Get-Host).UI.RawUI.BufferSize.Width
        $RedactionMessage = "<REDACTED: ObfuscatedLength = $($ScriptContents.Length)>"
        $CenteredRedactionMessageStartIndex = (($CmdLineWidth-$RedactionMessage.Length)/2) - "[*] ObfuscatedCommand: ".Length
        $CurrentRedactionMessageStartIndex = ($RedactedPrintLength % $CmdLineWidth)
        
        If($CurrentRedactionMessageStartIndex -gt $CenteredRedactionMessageStartIndex)
        {
            $RedactedPrintLength = $RedactedPrintLength-($CurrentRedactionMessageStartIndex-$CenteredRedactionMessageStartIndex)
        }
        Else
        {
            $RedactedPrintLength = $RedactedPrintLength+($CenteredRedactionMessageStartIndex-$CurrentRedactionMessageStartIndex)
        }
    
        Write-Host $ScriptContents.SubString(0,$RedactedPrintLength) -NoNewLine -ForegroundColor Magenta
        Write-Host $RedactionMessage -NoNewLine -ForegroundColor Yellow
        Write-Host $ScriptContents.SubString($ScriptContents.Length-$RedactedPrintLength) -ForegroundColor Magenta
    }
    Else
    {
        Write-Host $ScriptContents -ForegroundColor Magenta
    }

    # Make sure final command doesn't exceed cmd.exe's character limit.
    If($ScriptContents.Length -gt $CmdMaxLength)
    {
        If($PSBoundParameters['PrintWarning'])
        {
            Write-Host "`nWARNING: This command exceeds the cmd.exe maximum length of $CmdMaxLength." -ForegroundColor Red
            Write-Host "         Its length is" -NoNewLine -ForegroundColor Red
            Write-Host " $($ScriptContents.Length)" -NoNewLine -ForegroundColor Yellow
            Write-Host " characters." -ForegroundColor Red
        }
    }
}          


Function Show-AsciiArt
{
<#
.SYNOPSIS

HELPER FUNCTION :: Displays random ASCII art for Invoke-Obfuscation.

Invoke-Obfuscation Function: Show-AsciiArt
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Show-AsciiArt displays random ASCII art for Invoke-Obfuscation, and also displays ASCII art during script startup.

.EXAMPLE

C:\PS> Show-AsciiArt

.NOTES

Credit for ASCII art font generation: http://patorjk.com/software/taag/
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>
    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $Random
    )

    # Create multiple ASCII art title banners.
    $Spacing = "`t"
    $InvokeObfuscationAscii  = @()
    $InvokeObfuscationAscii += $Spacing + '    ____                 __                              '
    $InvokeObfuscationAscii += $Spacing + '   /  _/___ _   ______  / /_____                         '
    $InvokeObfuscationAscii += $Spacing + '   / // __ \ | / / __ \/ //_/ _ \______                  '
    $InvokeObfuscationAscii += $Spacing + ' _/ // / / / |/ / /_/ / ,< /  __/_____/                  '
    $InvokeObfuscationAscii += $Spacing + '/______ /__|_________/_/|_|\___/         __  _           '
    $InvokeObfuscationAscii += $Spacing + '  / __ \/ /_  / __/_  ________________ _/ /_(_)___  ____ '
    $InvokeObfuscationAscii += $Spacing + ' / / / / __ \/ /_/ / / / ___/ ___/ __ `/ __/ / __ \/ __ \'
    $InvokeObfuscationAscii += $Spacing + '/ /_/ / /_/ / __/ /_/ (__  ) /__/ /_/ / /_/ / /_/ / / / /'
    $InvokeObfuscationAscii += $Spacing + '\____/_.___/_/  \__,_/____/\___/\__,_/\__/_/\____/_/ /_/ '
    
    # Ascii art to run only during script startup.
    If(!$PSBoundParameters['Random'])
    {
        $ArrowAscii  = @()
        $ArrowAscii += '  |  '
        $ArrowAscii += '  |  '
        $ArrowAscii += ' \ / '
        $ArrowAscii += '  V  '

        # Show actual obfuscation example (generated with this tool) in reverse.
        Write-Host "`nIEX( ( '36{78Q55@32t61_91{99@104X97{114Q91-32t93}32t93}32t34@110m111@105}115X115-101m114_112@120@69-45{101@107X111m118m110-73Q124Q32X41Q57@51-93Q114_97_104t67t91{44V39Q112_81t109@39}101{99@97}108{112}101}82_45m32_32X52{51Q93m114@97-104{67t91t44t39V98t103V48t39-101}99}97V108}112t101_82_45{32@41X39{41_112t81_109_39m43{39-110t101@112{81t39X43@39t109_43t112_81Q109t101X39Q43m39}114Q71_112{81m109m39@43X39V32Q40}32m39_43_39{114-111m108t111t67{100m110{117Q39_43m39-111-114Q103_101t114@39m43-39{111t70-45}32m41}98{103V48V110Q98t103{48@39{43{39-43{32t98m103_48{111@105t98@103V48-39@43{39_32-32V43V32}32t98t103@48X116m97V99t98X103t48_39V43m39@43-39X43Q39_98@103@48}115V117V102Q98V79m45@98m39Q43{39X103_39X43Q39V48}43-39}43t39}98-103{48V101_107Q39t43X39_111X118X110V39X43}39t98_103{48@43}32_98{103}48{73{98-39@43t39m103_39}43{39{48Q32t39X43X39-32{40V32t41{39Q43V39m98X103{39_43V39{48-116{115Q79{39_43_39}98}103m48{39Q43t39X32X43{32_98@103-39@43m39X48_72-39_43t39V45m39t43Q39_101Q98}103_48-32_39Q43V39V32t39V43}39m43Q32V98X39Q43_39@103_48V39@43Q39@116X73t82V119m98-39{43_39}103Q48X40_46_32m39}40_40{34t59m91@65V114V114@97_121}93Q58Q58V82Q101Q118Q101{114}115_101m40_36_78m55@32t41t32-59{32}73{69V88m32{40t36V78t55}45Q74m111@105-110m32X39V39-32}41'.SpLiT( '{_Q-@t}mXV' ) |ForEach-Object { ([Int]`$_ -AS [Char]) } ) -Join'' )" -ForegroundColor Cyan
        Start-Sleep -Milliseconds 650
        ForEach($Line in $ArrowAscii) {Write-Host $Line -NoNewline; Write-Host $Line -NoNewline; Write-Host $Line -NoNewline; Write-Host $Line}
        Start-Sleep -Milliseconds 100
        
        Write-Host "`$N7 =[char[ ] ] `"noisserpxE-ekovnI| )93]rahC[,'pQm'ecalpeR-  43]rahC[,'bg0'ecalpeR- )')pQm'+'nepQ'+'m+pQme'+'rGpQm'+' ( '+'roloCdnu'+'orger'+'oF- )bg0nbg0'+'+ bg0oibg0'+'  +  bg0tacbg0'+'+'+'bg0sufbO-b'+'g'+'0+'+'bg0ek'+'ovn'+'bg0+ bg0Ib'+'g'+'0 '+' ( )'+'bg'+'0tsO'+'bg0'+' + bg'+'0H'+'-'+'ebg0 '+' '+'+ b'+'g0'+'tIRwb'+'g0(. '((`";[Array]::Reverse(`$N7 ) ; IEX (`$N7-Join '' )" -ForegroundColor Magenta
        Start-Sleep -Milliseconds 650
        ForEach($Line in $ArrowAscii) {Write-Host $Line -NoNewline; Write-Host $Line -NoNewline; Write-Host $Line}
        Start-Sleep -Milliseconds 100

        Write-Host ".(`"wRIt`" +  `"e-H`" + `"Ost`") (  `"I`" +`"nvoke`"+`"-Obfus`"+`"cat`"  +  `"io`" +`"n`") -ForegroundColor ( 'Gre'+'en')" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 650
        ForEach($Line in $ArrowAscii) {Write-Host $Line -NoNewline;  Write-Host $Line}
        Start-Sleep -Milliseconds 100

        Write-Host "Write-Host `"Invoke-Obfuscation`" -ForegroundColor Green" -ForegroundColor White
        Start-Sleep -Milliseconds 650
        ForEach($Line in $ArrowAscii) {Write-Host $Line}
        Start-Sleep -Milliseconds 100
        
        # Write out below string in interactive format.
        Start-Sleep -Milliseconds 100
        ForEach($Char in [Char[]]'Invoke-Obfuscation')
        {
            Start-Sleep -Milliseconds (Get-Random -Input @(25..200))
            Write-Host $Char -NoNewline -ForegroundColor Green
        }
        
        Start-Sleep -Milliseconds 900
        Write-Host ""
        Start-Sleep -Milliseconds 300
        Write-Host

        # Display primary ASCII art title banner.
        $RandomColor = (Get-Random -Input @('Green','Cyan','Yellow'))
        ForEach($Line in $InvokeObfuscationAscii)
        {
            Write-Host $Line -ForegroundColor $RandomColor
        }
    }
    Else
    {
        # ASCII option in Invoke-Obfuscation interactive console.

    }

    # Output tool banner after all ASCII art.
    Write-Host ""
    Write-Host "`tTool    :: Invoke-Obfuscation" -ForegroundColor Magenta
    Write-Host "`tAuthor  :: Daniel Bohannon (DBO)" -ForegroundColor Magenta
    Write-Host "`tTwitter :: @danielhbohannon" -ForegroundColor Magenta
    Write-Host "`tBlog    :: http://danielbohannon.com" -ForegroundColor Magenta
    Write-Host "`tGithub  :: https://github.com/danielbohannon/Invoke-Obfuscation" -ForegroundColor Magenta
    Write-Host "`tVersion :: 1.1" -ForegroundColor Magenta
    Write-Host "`tLicense :: Apache License, Version 2.0" -ForegroundColor Magenta
    Write-Host "`tNotes   :: If(!`$Caffeinated) {Exit}" -ForegroundColor Magenta
}