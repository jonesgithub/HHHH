/*
 *  ScriptCommon.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 12-1-9.
 *  Copyright 2012 (����)DeNA. All rights reserved.
 *
 */

#include "ScriptCommon.h"
#include "ScriptInc.h"
#include <sstream>

using namespace LuaPlus;

using namespace NDEngine;

int LuaLogInfo(LuaState* state)
{
	LuaStack args(state);
	LuaObject str = args[1];
	
	if (str.IsString())
	{
		ScriptMgrObj.DebugOutPut("%s", str.GetString());
	}
	
	return 0;
}

int LuaLogError(LuaState* state)
{
	LuaStack args(state);
	LuaObject str = args[1];
	
	if (str.IsString())
	{
		ScriptMgrObj.DebugOutPut("Error:%s", str.GetString());
	}
	
	return 0;
}

int DoFile(LuaState* state)
{
	LuaStack args(state);
	LuaObject str = args[1];
	
	if (str.IsString())
	{
		//state->DoFile(GetScriptPath(str.GetString())); ///< ��ʱ��ע�� ����
	}
	
	return 0;
}
	
int LeftShift(int x, int y)
{
	return x<<y;
}	
	
int RightShift(int x, int y)
{
	return x>>y;
}
	
int BitwiseAnd(int x, int y)
{
	return x&y;
}
    
////////////////////////////////////////////////////////////
//std::string g_strTmpWords;
////////////////////////////////////////////////////////////

void ScriptObjectCommon::OnLoad()
{
	ETLUAFUNC("LuaLogInfo", LuaLogInfo);
	
	ETLUAFUNC("LuaLogError", LuaLogError);
	
	ETLUAFUNC("DoFile", DoFile);
	
	ETCFUNC("LeftShift", LeftShift)
	
	ETCFUNC("RightShift", RightShift)
	
	ETCFUNC("BitwiseAnd", BitwiseAnd)
    //ETCFUNC("GetRandomWords", GetRandomWords);
}