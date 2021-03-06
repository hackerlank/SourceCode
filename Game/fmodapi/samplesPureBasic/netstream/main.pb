;===============================================================================================
; netstream.exe
; Copyright (c), Firelight Technologies Pty, Ltd, 1999-2003.
;
; This example shows how To play internet streams (SHOUTcast/Icecast2/HTTP)
;===============================================================================================
; PureBasic Port by KarLKoX 
; mail to KarLKoX@ifrance.com for bugs/suggestions

    
XIncludeFile "../../api/PureBasic/con_struc.pbi"
XIncludeFile "../../api/PureBasic/fmod_proc.pbi"

; 1 = windows 2 = linux
#OS = 1

Global artist.s, title.s
Global metanum.l

;
;[
;    [DESCRIPTION]
;    
;    [PARAMETERS]
;    
;    [RETURN_VALUE]
;    
;    [REMARKS]
;    
;    [SEE_ALSO]
;    ]
;    
Procedure.l metacallback(name.l, value.l, userdata.l)
    m_lpstrValue.s = PeekS(name)
    If (m_lpstrValue = "ARTIST")
      artist = PeekS(value)
      ProcedureReturn #True      
    EndIf
    
    If (m_lpstrValue = "TITLE")
      title = PeekS(value)
      metanum + 1
      ProcedureReturn #True      
    EndIf
    
  ProcedureReturn #True
EndProcedure


    OpenConsole()
    ClearConsole()
    ConsoleTitle ("PureBasic - FMOD Simple Example")
    
    LoadFMOD()
    
    result.f = FSOUND_GetVersion()
    ; call fpu register and store (pop) the value
    !FSTP dword [esp]   
    !POP [v_result]
    If (StrF(result, 2) <> StrF(FMOD_VERSION, 2)) 
      PrintN("Error : You are using the wrong DLL version!  You should be using FMOD " + StrF(FMOD_VERSION, 2))
      Delay(2000)
      CloseConsole()
      End
    EndIf

    filename.s = ProgramParameter() 
    If (filename = "") And (Left(filename, 5) <> "http:")
      PrintN("-------------------------------------------------------------")
      PrintN("PureBasic - FMOD netstream example.")
      PrintN("Copyright (c) Firelight Technologies Pty, Ltd, 1999-2003.")
      PrintN("-------------------------------------------------------------")
      PrintN("Syntax: netstream <url>")
      PrintN("Example: netstream http://www.fmod.org/stream.mp3")
      PrintN("")
      Delay(2000)
      CloseConsole()
      End
    EndIf
    
    If #OS = 1
      FSOUND_SetOutput(#FSOUND_OUTPUT_WINMM)
    ElseIf #OS = 2
      FSOUND_SetOutput(#FSOUND_OUTPUT_OSS)
    EndIf
    
    ;Select DRIVER
    
    ;  The following list are the drivers For the output method selected above.
    PrintN("---------------------------------------------------------")    
    
    Select FSOUND_GetOutput()
      Case #FSOUND_OUTPUT_NOSOUND
        Print("NoSound ")
      
      Case #FSOUND_OUTPUT_WINMM
        Print("Windows Multimedia Waveout ")
      
      Case #FSOUND_OUTPUT_DSOUND
        Print("Direct Sound ")

      Case #FSOUND_OUTPUT_A3D  
        Print("A3D ")  
      
      Case #FSOUND_OUTPUT_OSS
        Print("Open Sound System")
      
      Case #FSOUND_OUTPUT_ESD
        Print("Enlightment Sound Daemon")
      
      Case #FSOUND_OUTPUT_ALSA
        Print("ALSA")

    EndSelect    
    
    PrintN("Driver list")
    PrintN("---------------------------------------------------------")
    
    For i = 0 To FSOUND_GetNumDrivers() - 1
      PrintN(Str(i + 1) + " - " + PeekS(FSOUND_GetDriverName(i)) )
    Next i
    PrintN("---------------------------------------------------------")
    PrintN("Press a corresponding number or ESC to quit")      
    
    Repeat     
      driver.s = Left(Inkey(),1)          
      If Asc(driver) = 27
        PrintN(FMOD_ErrorString(FSOUND_GetError()))
        FSOUND_Close()
        Delay(1000)
        CloseConsole()
        End
      EndIf
      Delay(1)
    Until ( Val(driver) > 0 ) And ( Val(driver) <= FSOUND_GetNumDrivers() )
    
    FSOUND_SetDriver(Val(driver) - 1)                     ; Select sound card (0 = default)    
    
    ; INITIALIZE          
    If FSOUND_Init(44100, 32, 0) <= 0
      PrintN("FSOUND_Init() Error!")
      PrintN(FMOD_ErrorString(FSOUND_GetError()))
      FSOUND_Close()
      CloseFMOD()
      Delay(2000)
      CloseConsole()
      End
    EndIf
    
    ; internet streams can work with a much smaller stream buffer than normal streams because they
    ; use another level of buffering on top of the stream buffer.
    FSOUND_Stream_SetBufferSize(100)
    
    ; Here's where we set the size of the network buffer and some buffering parameters.
    ; In This Case we want a network buffer of 64k, we want it To prebuffer 60% of that when we first
    ; connect, And we want it To rebuffer 80% of that whenever we encounter a buffer underrun.
    FSOUND_Stream_Net_SetBufferProperties(64000, 60, 80)
    
    ; Open the stream using FSOUND_NONBLOCKING because the connect/buffer process might take a long time    
    stream = FSOUND_Stream_Open(@filename, #FSOUND_NORMAL | #FSOUND_NONBLOCKING, 0, 0)    
    If stream <= 0
      PrintN("FSOUND_Stream_Open() Error!")
      PrintN(FMOD_ErrorString(FSOUND_GetError()))
      FSOUND_Close()
      CloseFMOD()
      Delay(1000)
      CloseConsole()
      End
    EndIf       
    
    PrintN("")    
    PrintN("Press ESC to quit...")
    PrintN("")
    
    Dim status_str.s(5)
    status_str(0) = "NOTCONNECTED"
    status_str(1) = "CONNECTING  "
    status_str(2) = "BUFFERING   "    
    status_str(3) = "READY       "    
    status_str(4) = "ERROR       "        
    
    artist.s = Space$(256)
    title.s  = Space$(256)
    s.s      = Space$(256)
    metanum.l = 0
    channel  = -1
    
    Repeat
      String$ = Inkey()
      keys.s = Left(Inkey(),1)      
      
      ; play the stream If it's not already playing
      If (channel < 0)
        channel = FSOUND_Stream_PlayEx(#FSOUND_FREE, stream, #Null, #True)
        FSOUND_SetPaused(channel, #False)
        
        If (channel <> -1)
          FSOUND_Stream_Net_SetMetadataCallback(stream, @metacallback(), 0)
        EndIf
      EndIf
      
      openstate = FSOUND_Stream_GetOpenState(stream)
      If ((openstate = -1) And (openstate = -3))
        PrintN("")
        PrintN("ERROR: failed to open stream!")
        PrintN("SERVER: " +  PeekS(FSOUND_Stream_Net_GetLastServerStatus()))
        Break
      EndIf
      
      FSOUND_Stream_Net_GetStatus(stream, @status, @read_percent, @bitrate, @flags)
      
      ; Show how much of the net buffer is used And what the status is
      If (metanum)
        ConsoleLocate(0, 10)          
        PrintN(artist + " - " + title)
        metanum = 0
      EndIf
      s = LSet$("=",(read_percent >> 1) + (read_percent & 1), "=")
      s + LSet(" ", (100 - read_percent) >> 1)
      ConsoleLocate(0, 11)
      Print("|" + s + "| " + Str(read_percent) + "% " + status_str(status))
      
      Delay(16)
    Until String$ <> ""      
    PrintN("")
    
    FSOUND_Stream_Close(stream)
    FSOUND_Close()
    CloseFMOD()
    CloseConsole()
    End 
; jaPBe Version=1.4.4.25
; Build=74
; FirstLine=186
; CursorPosition=133
; ExecutableFormat=Console
; Executable=E:\Gravure\Prog\Vb\SoundZ\Fmod\fmodapi372win32\fmodapi372win\samplesPureBasic\netstream\netstream.exe
; DontSaveDeclare
; EOF