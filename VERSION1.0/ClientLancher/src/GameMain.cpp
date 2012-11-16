/*
*
*/

#include "GameApp.h"
#include "CCString.h"
#include "XMLReader.h"
#include <NDGameApplication.h>
#include <LuaPlus.h>
#include <NDBaseDirector.h>
#include "NDConsole.h"
#include "NDSharedPtr.h"
#include "NDBaseNetMgr.h"
#include "MsgDefine\inc\NDNetMsg.h"
#include "GameLauncher.h"

using namespace cocos2d;
using namespace NDEngine;
using namespace LuaPlus;

#ifndef CC_TARGET_PLATFORM
#define CC_TARGET_PLATFORM CC_PLATFORM_WIN32
#endif

int WINAPI WinMain (HINSTANCE hInstance, 
					HINSTANCE hPrevInstance, 
					PSTR szCmdLine,
					int iCmdShow)
{
 	UNREFERENCED_PARAMETER(hPrevInstance);
 	UNREFERENCED_PARAMETER(szCmdLine);

	NDConsole kConsole;
	kConsole.BeginReadLoop();

    // �ֻ�ƽ̨��ջ��Ƚ�С, �Ժ�Ҫ����new ///< �Ѿ���Ϊnew ����
 	NDSharedPtr<GameLauncher> spGameLauncher = new GameLauncher;
	spGameLauncher->BeginGame();
    NDBaseDirector kBaseDirector;
 
 	return CCApplication::sharedApplication().run();
}