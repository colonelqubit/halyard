# Microsoft Developer Studio Project File - Name="Common" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=Common - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "Common.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "Common.mak" CFG="Common - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "Common - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "Common - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "Common - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /I "\dev\Quicktime\QT501SDK\SDK\CIncludes" /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /Yu"THeader.h" /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"..\Bin\Common.lib"

!ELSEIF  "$(CFG)" == "Common - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /YX /FD /GZ /c
# ADD CPP /nologo /W3 /Gm /GX /ZI /Od /I "\dev\Quicktime\QT501SDK\SDK\CIncludes" /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /Yu"THeader.h" /FD /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"..\BinD\Common.lib"

!ENDIF 

# Begin Target

# Name "Common - Win32 Release"
# Name "Common - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\TArray.cpp
# End Source File
# Begin Source File

SOURCE=.\TBTree.cpp
# End Source File
# Begin Source File

SOURCE=.\THeader.cpp
# ADD CPP /Yc"THeader.h"
# End Source File
# Begin Source File

SOURCE=.\TLogger.cpp
# End Source File
# Begin Source File

SOURCE=.\TObject.cpp
# End Source File
# Begin Source File

SOURCE=.\TPoint.cpp
# End Source File
# Begin Source File

SOURCE=.\TRect.cpp
# End Source File
# Begin Source File

SOURCE=.\TString.cpp
# End Source File
# Begin Source File

SOURCE=.\TURL.cpp
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=.\TArray.h
# End Source File
# Begin Source File

SOURCE=.\TBTree.h
# End Source File
# Begin Source File

SOURCE=.\TCommon.h
# End Source File
# Begin Source File

SOURCE=.\TDictionary.h
# End Source File
# Begin Source File

SOURCE=.\TDList.h
# End Source File
# Begin Source File

SOURCE=.\THeader.h
# End Source File
# Begin Source File

SOURCE=.\TList.h
# End Source File
# Begin Source File

SOURCE=.\TLogger.h
# End Source File
# Begin Source File

SOURCE=.\TObject.h
# End Source File
# Begin Source File

SOURCE=.\TPoint.h
# End Source File
# Begin Source File

SOURCE=.\TRandom.h
# End Source File
# Begin Source File

SOURCE=.\TRect.h
# End Source File
# Begin Source File

SOURCE=.\TString.h
# End Source File
# Begin Source File

SOURCE=.\TURL.h
# End Source File
# End Group
# End Target
# End Project
