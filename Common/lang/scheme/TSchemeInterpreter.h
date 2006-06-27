// -*- Mode: C++; tab-width: 4; c-basic-offset: 4; -*-
// @BEGIN_LICENSE
//
// Tamale - Multimedia authoring and playback system
// Copyright 1993-2004 Trustees of Dartmouth College
// 
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//
// @END_LICENSE

#if !defined (_TSchemeInterpreter_h_)
#define _TSchemeInterpreter_h_

#include "TInterpreter.h"
#include "TPrimitives.h"
#include "FileSystem.h"
#include "TSchemePtr.h"
#include "TSchemeCallback.h"
#include "TSchemeConv.h"

BEGIN_NAMESPACE_FIVEL

class TPercent;


//////////
/// A TInterpreterManager for our Scheme interpreter.  This handles
/// reloading scripts and other fun stuff that involves creating
/// and destroying interpreters.
///
class TSchemeInterpreterManager : public TInterpreterManager
{
	Scheme_Env *mGlobalEnv;
    shared_ptr<ScriptEditorDB> mScriptEditorDB;

public:
	TSchemeInterpreterManager(TInterpreter::SystemIdleProc inIdleProc);

    virtual ScriptEditorDB *GetScriptEditorDBInternal();
	virtual void BeginScript();

private:
	void LoadFile(const FileSystem::Path &inFile);

protected:
	virtual TInterpreter *MakeInterpreter();
};


//////////
/// The interface to our Scheme interpreter.  Since this is a singleton
/// class, we store a lot of variables as static data to ease implementation.
///
class TSchemeInterpreter : public TInterpreter
{
	friend class TSchemeInterpreterManager;
	friend class TSchemeCallback;

	static Scheme_Env *sGlobalEnv;
	static Scheme_Env *sScriptEnv;
	static TSchemePtr<Scheme_Object> sLoaderModule;
	static TSchemePtr<Scheme_Object> sKernelModule;

    struct BucketKey {
        TSchemePtr<Scheme_Env> env;
        TSchemePtr<Scheme_Object> module;
        std::string name;

        BucketKey(TSchemePtr<Scheme_Env> inEnv,
                  TSchemePtr<Scheme_Object> inModule,
                  std::string inName)
            : env(inEnv), module(inModule), name(inName) {}
        
        bool operator<(const BucketKey &inRight) const {
            return ((env < inRight.env)
                    || (env == inRight.env
                        && (module < inRight.module ||
                            (module == inRight.module
                             && name < inRight.name))));
        }
    };
    typedef std::map<BucketKey, TSchemePtr<Scheme_Bucket> > BucketMap;
    static BucketMap sBucketMap;

	static SystemIdleProc sSystemIdleProc;

	static void InitializeModuleNames();

    static Scheme_Bucket *FindBucket(Scheme_Env *inEnv,
                                     Scheme_Object *inModule,
                                     const char *inFuncName);

    /// Call a primitive function.  This function may only use PLT-style
    /// error handling, *not* C++ exceptions.
	static Scheme_Object *Call5LPrim(int inArgc, Scheme_Object **inArgv);
    /// This function may only use C++ exceptions, *not* PLT-style error
    /// handling.
    static bool
    TSchemeInterpreter::Call5LPrimInternal(const char *inPrimName,
                                           int inArgc, Scheme_Object **inArgv,
                                           Scheme_Object **outResult,
                                           char *outErrorMessage,
                                           size_t inErrorMessageMaxLength);

public:
	TSchemeInterpreter(Scheme_Env *inGlobalEnv);
	virtual ~TSchemeInterpreter();

	// TODO - factor entirely into TInterpreter.
	void DoIdle(bool block) {
		ASSERT(sSystemIdleProc);
		(*sSystemIdleProc)(block);
	}

	static Scheme_Object *CallSchemeEx(Scheme_Env *inEnv,
									   Scheme_Object *inModule,
									   const char *inFuncName,
									   int inArgc, Scheme_Object **inArgv);
	static Scheme_Object *CallScheme(const char *inFuncName,
									 int inArgc, Scheme_Object **inArgv);
	static Scheme_Object *CallSchemeSimple(const char *inFuncName);

	static Scheme_Object *MakeSchemePoint(const TPoint &inPoint);
	static Scheme_Object *MakeSchemeRect(const TRect &inRect);
	static Scheme_Object *MakeSchemeColor(const GraphicsTools::Color &inColor);
	static Scheme_Object *MakeSchemePolygon(const TPolygon &inPoly);
	static Scheme_Object *MakeSchemePercent(const TPercent &inPercent);

	// For documentation of these virtual methods, see TInterpreter.h.
	virtual void Run(SystemIdleProc inIdleProc);
	virtual void KillInterpreter();
	virtual void Stop();
	virtual bool IsStopped();
	virtual void Go(const char *inCard);
    virtual bool CanSuspend();
	virtual void Pause(void);
	virtual void WakeUp(void);
	virtual bool Paused(void);
	virtual void Timeout(const char *inName, int32 inTime);
	virtual void Nap(int32 inTime);
	virtual bool Napping(void);
	virtual void KillNap(void);
	virtual void KillCurrentCard(void);
	virtual void JumpToCardByName(const char *inName);
	virtual std::string CurCardName(void);
	virtual std::string PrevCardName(void);
	virtual bool IsValidCard(const char *inCardName);
	virtual bool Eval(const std::string &inExpression,
					  std::string &outResultText);
    virtual std::vector<TScriptIdentifier> GetKnownIdentifiers();
    static TScriptIdentifier::Type IdentifierType(const std::string &type_str);
};

END_NAMESPACE_FIVEL

#endif // TSchemeInterpreter
