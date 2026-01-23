_LVORexx    EQU -30	       ; Main entry point
_LVOrxParse    EQU -36	       ; (private)
_LVOrxInstruct    EQU -42       ; (private)
_LVOrxSuspend    EQU -48        ; (private)
_LVOEvalOp    EQU -54	       ; (private)

_LVOAssignValue    EQU -60      ; (private)
_LVOEnterSymbol    EQU -66      ; (private)
_LVOFetchValue    EQU -72       ; (private)
_LVOLookUpValue    EQU -78      ; (private)
_LVOSetValue    EQU -84	       ; (private)
_LVOSymExpand    EQU -90        ; (private)

_LVOErrorMsg    EQU -96
_LVOIsSymbol    EQU -102
_LVOCurrentEnv    EQU -108
_LVOGetSpace    EQU -114
_LVOFreeSpace    EQU -120

_LVOCreateArgstring    EQU -126
_LVODeleteArgstring    EQU -132
_LVOLengthArgstring    EQU -138
_LVOCreateRexxMsg    EQU -144
_LVODeleteRexxMsg    EQU -150
_LVOClearRexxMsg    EQU -156
_LVOFillRexxMsg    EQU -162
_LVOIsRexxMsg    EQU -168

_LVOAddRsrcNode    EQU -174
_LVOFindRsrcNode    EQU -180
_LVORemRsrcList    EQU -186
_LVORemRsrcNode    EQU -192
_LVOOpenPublicPort    EQU -198
_LVOClosePublicPort    EQU -204
_LVOListNames    EQU -210

_LVOClearMem    EQU -216
_LVOInitList    EQU -222
_LVOInitPort    EQU -228
_LVOFreePort    EQU -234

_LVOCmpString    EQU -240
_LVOStcToken    EQU -246
_LVOStrcmpN    EQU -252
_LVOStrcmpU    EQU -258
_LVOStrcpyA    EQU -264	       ; obsolete
_LVOStrcpyN    EQU -270
_LVOStrcpyU    EQU -276
_LVOStrflipN    EQU -282
_LVOStrlen    EQU -288
_LVOToUpper    EQU -294

_LVOCVa2i    EQU -300
_LVOCVi2a    EQU -306
_LVOCVi2arg    EQU -312
_LVOCVi2az    EQU -318
_LVOCVc2x    EQU -324
_LVOCVx2c    EQU -330

_LVOOpenF    EQU -336
_LVOCloseF    EQU -342
_LVOReadStr    EQU -348
_LVOReadF    EQU -354
_LVOWriteF    EQU -360
_LVOSeekF    EQU -366
_LVOQueueF    EQU -372
_LVOStackF    EQU -378
_LVOExistF    EQU -384

_LVODOSCommand    EQU -390
_LVODOSRead    EQU -396
_LVODOSWrite    EQU -402
_LVOCreateDOSPkt    EQU -408     ; obsolete
_LVODeleteDOSPkt    EQU -414     ; obsolete
_LVOSendDOSPkt    EQU -420       ; (private)
_LVOWaitDOSPkt    EQU -426       ; (private)
_LVOFindDevice    EQU -432       ; (private)

_LVOAddClipNode    EQU -438
_LVORemClipNode    EQU -444
_LVOLockRexxBase    EQU -450
_LVOUnlockRexxBase    EQU -456
_LVOCreateCLI    EQU -462        ; (private)
_LVODeleteCLI    EQU -468        ; (private)
_LVOCVs2i    EQU -474
