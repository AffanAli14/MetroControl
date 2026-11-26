TITLE MetroControl32 - Railway Operations Control Center

INCLUDE Irvine32.inc

MAX_TRAINS = 8
MAX_TRACKS = 3
LAST_ROUND = 19

COLOR_HEAD = 11
COLOR_TEXT = 7
COLOR_HOT = 14
COLOR_OK = 10
COLOR_STOP = 12
COLOR_DIM = 8

.data

; Shared game state
trainPriority BYTE 3,1,4,2,1,5,3,2
trainArrival  BYTE 1,1,2,3,4,5,6,7
trainState    BYTE MAX_TRAINS DUP(0)
trainTrack    BYTE MAX_TRAINS DUP(0)

trackSignal   BYTE MAX_TRACKS DUP(1)
trackTrain    BYTE MAX_TRACKS DUP(0)
trackTimer    BYTE MAX_TRACKS DUP(0)
trackLength   BYTE 2,3,4
trackRow      BYTE 7,10,13
queueRow      BYTE 7,8,9,10,11,12,13,14

eventLog      BYTE 4 DUP(0)

roundNo       DWORD 1
teamScore     DWORD 0
completedNo   DWORD 0
bestTrain     BYTE 0
bestPriority  BYTE 255
chosenTrain   BYTE 0
movingNo      DWORD 0
waitingNo     DWORD 0
quitFlag      BYTE 0

; Lead's ending screen
lineTop BYTE "+--------------------------------------------------+",0
endTitle BYTE "===== RAILWAY SHIFT COMPLETE =====",0
winText BYTE "SUCCESS: ALL EIGHT TRAINS DELIVERED.",0
lossText BYTE "SHIFT ENDED: TRAINS REMAINING.",0
quitText BYTE "SHIFT ABORTED BY OPERATOR.",0
scoreText BYTE "FINAL TEAM SCORE: ",0
doneText BYTE "TRAINS DELIVERED: ",0
againText BYTE "PLAY AGAIN? [1] yes  [0] no: ",0

; Temporary setup text
setupMsg BYTE "MetroControl32 - Core Module",0
roundMsg BYTE "Round: ",0
bestMsg BYTE "Recommended Train: ",0

.code

ResetGame PROC USES eax ecx esi
    mov roundNo,1
    mov teamScore,0
    mov completedNo,0
    mov movingNo,0
    mov waitingNo,0
    mov bestTrain,0
    mov bestPriority,255
    mov quitFlag,0
    mov chosenTrain,0

    mov esi,0
    mov ecx,MAX_TRAINS

ResetTrainLoop:
    mov trainState[esi],0
    mov trainTrack[esi],0
    inc esi
    loop ResetTrainLoop

    mov esi,0
    mov ecx,MAX_TRACKS

ResetTrackLoop:
    mov trackSignal[esi],1
    mov trackTrain[esi],0
    mov trackTimer[esi],0
    inc esi
    loop ResetTrackLoop

    mov esi,0
    mov ecx,4

ResetEventsLoop:
    mov eventLog[esi],0
    inc esi
    loop ResetEventsLoop
    ret
ResetGame ENDP

FindBest PROC USES eax ebx ecx esi
    mov bestTrain,0
    mov bestPriority,255
    mov waitingNo,0
    mov movingNo,0

    mov esi,0
    mov ecx,MAX_TRAINS

BestLoop:
    cmp trainState[esi],1
    jne BestNotMoving

    inc movingNo
    jmp BestNext

BestNotMoving:
    cmp trainState[esi],0
    jne BestNext

    movzx eax,trainArrival[esi]
    cmp eax,roundNo
    ja BestNext

    inc waitingNo

    ; Equal priorities retain the earlier train.
    mov bl,trainPriority[esi]
    cmp bl,bestPriority
    jae BestNext

    mov bestPriority,bl
    mov eax,esi
    inc eax
    mov bestTrain,al

BestNext:
    inc esi
    loop BestLoop
    ret
FindBest ENDP

AdvanceTrains PROC USES eax ecx esi
    mov esi,0
    mov ecx,MAX_TRACKS

AdvanceLoop:
    cmp trackTrain[esi],0
    je AdvanceNext

    cmp trackTimer[esi],0
    je AdvanceNext

    dec trackTimer[esi]

    cmp trackTimer[esi],0
    jne AdvanceNext

    movzx eax,trackTrain[esi]
    dec eax

    mov trainState[eax],2
    mov trackTrain[esi],0

    inc completedNo
    add teamScore,15

    mov al,7
    call LogEvent

AdvanceNext:
    inc esi
    loop AdvanceLoop
    ret
AdvanceTrains ENDP

ShowEnding PROC USES ebx edx esi
    call Clrscr

    mov esi,OFFSET lineTop
    mov ebx,0502h
    mov eax,COLOR_HEAD
    call PrintAt

    mov esi,OFFSET endTitle
    mov ebx,0709h
    mov eax,COLOR_HOT
    call PrintAt

    cmp quitFlag,1
    je EndingQuit

    cmp completedNo,MAX_TRAINS
    je EndingWin

    mov esi,OFFSET lossText
    jmp EndingPrint

EndingQuit:
    mov esi,OFFSET quitText
    jmp EndingPrint

EndingWin:
    mov esi,OFFSET winText

EndingPrint:
    mov ebx,0A09h
    mov eax,COLOR_TEXT
    call PrintAt

    mov esi,OFFSET scoreText
    mov ebx,0D09h
    mov eax,COLOR_OK
    call PrintAt

    mov ebx,0D1Bh
    mov eax,teamScore
    call PrintNumberAt

    mov esi,OFFSET doneText
    mov ebx,0F09h
    mov eax,COLOR_TEXT
    call PrintAt

    mov ebx,0F1Bh
    mov eax,completedNo
    call PrintNumberAt

    mov esi,OFFSET againText
    mov ebx,1309h
    mov eax,COLOR_HOT
    call PrintAt

    call ReadDec
    ret
ShowEnding ENDP

main PROC

NewShift:
    call ResetGame
    call ShowWelcome

ShiftLoop:
    cmp roundNo,LAST_ROUND
    ja ShiftEnding

    call AdvanceTrains
    call FindBest
    call DrawDashboard

    cmp completedNo,MAX_TRAINS
    je ShiftEnding

    call ControllerTurn
    cmp quitFlag,1
    je ShiftEnding

    call FindBest
    call DrawDashboard
    call DispatcherTurn

    cmp quitFlag,1
    je ShiftEnding

    inc roundNo
    jmp ShiftLoop

ShiftEnding:
    call ShowEnding

    cmp eax,1
    je NewShift

    exit
main ENDP

; Temporary stubs - replace with member implementations.
ShowWelcome PROC
    mov edx,OFFSET setupMsg
    call WriteString
    call Crlf
    ret
ShowWelcome ENDP

DrawDashboard PROC
    mov edx,OFFSET roundMsg
    call WriteString
    mov eax,roundNo
    call WriteDec
    call Crlf

    mov edx,OFFSET bestMsg
    call WriteString
    movzx eax,bestTrain
    call WriteDec
    call Crlf
    ret
DrawDashboard ENDP

ControllerTurn PROC
    ret
ControllerTurn ENDP

DispatcherTurn PROC
    ret
DispatcherTurn ENDP

LogEvent PROC
    ret
LogEvent ENDP

PrintAt PROC USES eax edx
    mov edx,esi
    call WriteString
    call Crlf
    ret
PrintAt ENDP

PrintNumberAt PROC
    call WriteDec
    call Crlf
    ret
PrintNumberAt ENDP

END main