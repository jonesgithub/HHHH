#include "NDGameApplication.h"
#include "NDDirector.h"
#include "SMLoginScene.h"
#include "CCEGLView.h"
#include "NDPath.h"
#include "ScriptCommon.h"
#include "ScriptGlobalEvent.h"
#include "ScriptNetMsg.h"
#include "ScriptUI.h"
#include "ScriptGameLogic.h"
#include "SMGameScene.h"
#include "GameScene.h"
#include "ScriptTimer.h"
#include "NDPlayer.h"
#include "CCPointExtension.h"
#include "NDConstant.h"
#include "NDNpc.h"
#include "ScriptDrama.h"
#include <ScriptGameLogic.h>
#include "NDSocket.h"
#include "NDMapMgr.h"
#include "LuaStateMgr.h"
#include "NDBeforeGameMgr.h"
#include "ScriptGameData.h"
#include "NDDebugOpt.h"
#include "NDClassFactory.h"
#include "Battle.h"
#include "NDProfile.h"
#include "NDBaseDirector.h"
#include "WorldMapScene.h"
#include "NDUILoad.h"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
#include "Foundation/NSAutoreleasePool.h"
#import "EAGLView.h"
static NDBaseDirector s_NDBaseDirector;
#endif

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include <jni.h>
#include <android/log.h>

#define  LOG_TAG    "DaHuaLongJiang"
#define  LOGD(...)  __android_log_print(ANDROID_LOG_DEBUG,LOG_TAG,__VA_ARGS__)
#define  LOGERROR(...)  __android_log_print(ANDROID_LOG_ERROR,LOG_TAG,__VA_ARGS__)
#else
#define  LOG_TAG    "DaHuaLongJiang"
#define  LOGD(...)
#define  LOGERROR(...)
#endif

#if 0
#include "HelloWorldScene.h" //@todo
#endif
#include "BattleMgr.h"
#include "NDBaseBattleMgr.h"
#include "NDNetMsg.h"
#include "NDBaseNetMgr.h"
#include "NDBaseScriptMgr.h"
#include "ScriptMgr.h"
#include "NDBaseGlobalDialog.h"
#include "GlobalDialog.h"
#include "UIItemButton.h"
#include "UIEquipItem.h"
#include "NDUIBaseItemButton.h"
#include "UIItemButton.h"

NS_NDENGINE_BGN
using namespace NDEngine;

NDGameApplication::NDGameApplication()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	NDConsole::GetSingletonPtr()->RegisterConsoleHandler(this,"script ");
#endif
}
NDGameApplication::~NDGameApplication()
{
}

bool NDGameApplication::applicationDidFinishLaunching()
{
	CCDirector* pDirector = CCDirector::sharedDirector();
	CCAssert(pDirector, "applicationDidFinishLaunching");
	pDirector->setOpenGLView(CCEGLView::sharedOpenGLView());

	TargetPlatform target = getTargetPlatform();

	if (target == kTargetIpad)
	{
		// ipad

		CCFileUtils::sharedFileUtils()->setResourceDirectory("iphonehd");

		// don't enable retina because we don't have ipad hd resource
		CCEGLView::sharedOpenGLView()->setDesignResolutionSize(960, 640, kResolutionNoBorder);
	}
	else if (target == kTargetIphone)
	{
		// iphone

		// try to enable retina on device
		if (true == CCDirector::sharedDirector()->enableRetinaDisplay(true))
		{
			// iphone hd
			CCFileUtils::sharedFileUtils()->setResourceDirectory("iphonehd");
		}
		else 
		{
			CCFileUtils::sharedFileUtils()->setResourceDirectory("iphone");
		}
	}
	else if(target == kTargetAndroid)
	{
		CCLog("Entryu setDesignResolutionSize");
		CCEGLView::sharedOpenGLView()->setDesignResolutionSize(1196, 720, kResolutionNoBorder);
	}
	else 
	{
		// android, windows, blackberry, linux or mac
		// use 960*640 resources as design resolution size
		//CCFileUtils::sharedFileUtils()->setResourceDirectory("iphonehd");
		//CCEGLView::sharedOpenGLView()->setDesignResolutionSize(480*2, 320*2, kResolutionNoBorder);//@todo
		CCDirector::sharedDirector()->enableRetinaDisplay(true);//@retina

#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)

		// initialize socket
		InitSocket();
#endif
	}

	// turn on display FPS
	//pDirector->setDisplayStats(true); //@fps 

	// set FPS. the default value is 1.0/60 if you don't call this
	//pDirector->setAnimationInterval(1.0 / 60);
	pDirector->setAnimationInterval(1.0 / 24);

#if 0 //@todo @hello
 	// create a scene. it's an autorelease object
 	CCScene *pScene = HelloWorld::scene();
 
 	// run
 	pDirector->runWithScene(pScene);
	//////////////////////////////////////////////
#else
	this->MyInit();
#endif


	return true;
}

void NDGameApplication::MyInit()
{
	LOGD("Start MyInit");

	REGISTER_CLASS(NDBaseBattle,Battle);
	REGISTER_CLASS(NDBaseFighter,Fighter);
	REGISTER_CLASS(NDBaseBattleMgr,BattleMgr);
	REGISTER_CLASS(NDSprite,NDPlayer);
	REGISTER_CLASS(NDBaseNetMgr,NDNetMsgPool);
	REGISTER_CLASS(NDBaseScriptMgr,ScriptMgr);
	REGISTER_CLASS(NDBaseGlobalDialog,CIDFactory);
	//REGISTER_CLASS(CUIItemButton,CUIEquipItem);
	REGISTER_CLASS(NDUIBaseItemButton,CUIItemButton);
	REGISTER_CLASS(NDUIBaseItemButton,CUIEquipItem);

	LOGD("REGISTER_CLASS Over");

	NDMapMgr& kMapMgr = NDMapMgrObj;

	LOGD("kMapMgr get Over");
	//ScriptMgr &kScriptManager = ScriptMgr::GetSingleton();
	NDBeforeGameMgrObj;

	LOGD("NDBeforeGameMgrObj Over");

	NDDirector* pkDirector = NDDirector::DefaultDirector();

	LOGD("pkDirector get Over,%d",(int)pkDirector);

	pkDirector->Initialization();

	LOGD("pkDirector Initialization Over");

	pkDirector->RunScene(CSMLoginScene::Scene());

	LOGD("pkDirector->RunScene(CSMLoginScene::Scene()); Over");

//	kMapMgr.processChangeRoom(0,0);

#if 0 //@todo
	ScriptNetMsg* pkNetMsg = new ScriptNetMsg;
	ScriptObjectGameLogic* pkLogic = new ScriptObjectGameLogic;
	NDScriptGameData* pkData = new NDScriptGameData;
	//ScriptGlobalEvent* pkGlobalEvent = new ScriptGlobalEvent;
	ScriptObjectCommon* pkCommon = new ScriptObjectCommon;
	ScriptObjectUI* pkScriptUI = new ScriptObjectUI;
	ScriptTimerMgr* pkTimerManager = new ScriptTimerMgr;
	ScriptObjectDrama* pkDrama = new ScriptObjectDrama;

	pkData->Load();
	pkTimerManager->OnLoad();
	pkNetMsg->OnLoad();
	pkLogic->OnLoad();
	pkDrama->OnLoad();
	pkCommon->OnLoad();
	ScriptGlobalEvent::Load();
	//pkGlobalEvent->OnLoad();
	pkScriptUI->OnLoad();
#endif

	//kScriptManager.Load();
	ScriptMgrObj.Load();

	LOGD("ScriptMgrObj.Load(); Over");

	//CC_SAFE_DELETE(pkNetMsg);

	//ScriptGlobalEvent::OnEvent (GE_GENERATE_GAMESCENE);
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	LOGD("Start ScriptGlobalEvent::OnEvent(GE_LOGIN_GAME)");
	ScriptGlobalEvent::OnEvent(GE_LOGIN_GAME);
#endif

	LOGD("End MyInit");

	//NDPlayer::pugeHero();
	//NDPlayer& kPlayer = NDPlayer::defaultHero(1);

	//int x = 100;
	//int y = 100;

 // 	kPlayer.SetPosition(ccp(528, 512));		///< x * 32 + 16, y * 32 + 16
 // 	kPlayer.SetServerPositon(x, y);
 // 	kPlayer.m_nID = 1;
 // 	kPlayer.m_strName = "白富美";
 // 	kPlayer.SetLoadMapComplete();
 // 
 //  	CSMGameScene* pkScene = (CSMGameScene*)pkDirector->GetRunningScene();
 //  	NDNode* pkNode = pkScene->GetChild(MAPLAYER_TAG);
 //  
 //  	if (!pkNode->IsKindOfClass(RUNTIME_CLASS(NDMapLayer)))
 //  	{
 //  		return false;
 //  	}
 //  
 //  	NDMapLayer* pkLayer = (NDMapLayer*) pkNode;
 //  	pkLayer->AddChild(&kPlayer, 111, 1000);
 //  	kPlayer.standAction(true);
 //  	//pkScene->setUpdatePlayer(&kPlayer);
 // 
 //  	//add by ZhangDi 120904
 //  	//DramaObj.Start();
 //  
 //   //	DramaCommandScene* commandScene = new DramaCommandScene;
 //   //	commandScene->InitWithLoadDrama(5);
 //  	//DramaObj.AddCommond(commandScene);
 //  
 //  
 //  	//DramaCommandSprite* commandSprite = new DramaCommandSprite;
 //  	//commandSprite->InitWithAdd(31000112, ST_NPC, FALSE, "华佗");
 //  	////commandSprite->InitWithSetPos(command->GetKey(), 9, 11);
 //  	//DramaObj.AddCommond(commandSprite);
 // 
 // 
 // 	for (int i = 0; i < 4; i++)
 // 	{
 // 		NDNpc* npc = new NDNpc;
 // 		npc->m_nID = 10001 + i;
 // 		//npc->col = 9;
 // 		//npc->row = 11;
 // 		//npc->look = 31000112;
 // 
 // 		switch (i)
 // 		{
 // 		case 0:
 // 			npc->m_strName = "郭嘉";
 // 			break;
 // 		case 1:
 // 			npc->m_strName = "华佗";
 // 			break;
 // 		case 2:
 // 			npc->m_strName = "袁绍";
 // 			break;
 // 		case 3:
 // 			npc->m_strName = "刘表";
 // 			break;
 // 		default:
 // 			npc->m_strName = "西门无名";
 // 			break;
 // 		}
 // 
 // 		npc->Initialization(111 + i);		//31000112
 // 		npc->SetPosition(
 // 				ccp((5 + i * 6) * MAP_UNITSIZE + DISPLAY_POS_X_OFFSET,
 // 						11 * MAP_UNITSIZE + DISPLAY_POS_Y_OFFSET));
 // 
 // 		//npc->dataStr = "哈哈";
 // 		//npc->talkStr = "你想知道什么？";
 // 		npc->SetType(0);
 // 		//npc->SetActionOnRing(FALSE);
 // 		//npc->SetDirectOnTalk(FALSE);
 // 		//npc->initUnpassPoint();
 // 
 // 		if (!pkLayer->ContainChild(npc))
 // 		{
 // 			pkLayer->AddChild((NDNode *) npc, 100 + i, 10001 + i);
 // 			//npc->HandleNpcMask(TRUE);
 // 		}
 // 
 // 		NDPlayer::defaultHero().UpdateFocus();
 // 	}

	// 现在这里登陆
	// SwichKeyToServer("121.207.239.91", 9500/*9528*/, "285929910", "", "xx");
}

void NDGameApplication::applicationDidEnterBackground()
{
#ifdef USE_MGSDK
    [MBGPlatform pause];
#endif
	CCDirector::sharedDirector()->stopAnimation();

	// if you use SimpleAudioEngine, it must be pause
	// SimpleAudioEngine::sharedEngine()->pauseBackgroundMusic();
}

void NDGameApplication::applicationWillEnterForeground()
{
#ifdef USE_MGSDK
    [MBGPlatform resume];
#endif
	CCDirector::sharedDirector()->startAnimation();

	// if you use SimpleAudioEngine, it must resume here
	// SimpleAudioEngine::sharedEngine()->resumeBackgroundMusic();
}

//@pm
bool NDGameApplication::processConsole( const char* pszInput )
{
	if (0 == pszInput || !*pszInput)
	{
		return false;
	}

	LuaStateMgrObj.GetState().m_state->DoString(pszInput);

	return true;
}

//@pm
bool NDGameApplication::processPM(const char* cmd) 
{
	if (cmd == 0 || cmd[0] == 0) return false;

#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	int val = 0;
	char szDebugOpt[50] = {0};

	HANDLE hOut = NDConsole::GetSingletonPtr()->getOutputHandle();

	if (stricmp(cmd, "opt help") == 0)
	{
		TCHAR help[] =	L"syntax: opt arg 0/1\r\n"
			L"arg can be: tick, script, network, mainloop, drawhud, drawui, drawmap, drawrole, drawrolenpc, drawrolemonster, drawroleplayer, drawrolemanual.\r\n";

		DWORD n = 0;
		WriteConsoleW( hOut, help, sizeof(help)/sizeof(TCHAR), &n, NULL );
	}
	else if (sscanf(cmd, "opt %s %d", szDebugOpt, &val) == 2)
	{
		if (stricmp(szDebugOpt, "tick") == 0)
			NDDebugOpt::setTickEnabled( val != 0 );

		else if (stricmp(szDebugOpt, "script") == 0)
			NDDebugOpt::setScriptEnabled( val != 0 );

		else if (stricmp(szDebugOpt, "network") == 0)
			NDDebugOpt::setNetworkEnabled( val != 0 );

		else if (stricmp(szDebugOpt, "mainloop") == 0)
			NDDebugOpt::setMainLoopEnabled( val != 0 );

		else if (stricmp(szDebugOpt, "drawhud") == 0)
			NDDebugOpt::setDrawHudEnabled( val != 0 );

		else if (stricmp(szDebugOpt, "drawui") == 0)
			NDDebugOpt::setDrawUIEnabled( val != 0 );

		else if (stricmp(szDebugOpt, "drawmap") == 0)
			NDDebugOpt::setDrawMapEnabled( val != 0 );

		else if (stricmp(szDebugOpt, "drawcell") == 0)
			NDDebugOpt::setDrawCellEnabled( val != 0 );

		else if (stricmp(szDebugOpt, "drawrole") == 0)
			NDDebugOpt::setDrawRoleEnabled( val != 0 );

		else if (stricmp(szDebugOpt, "drawrolenpc") == 0 ||
					stricmp(szDebugOpt, "drawnpc") == 0)
		{
			NDDebugOpt::setDrawRoleNpcEnabled( val != 0 );
		}
		else if (stricmp(szDebugOpt, "drawrolemonster") == 0 ||
					stricmp(szDebugOpt, "drawmonster") == 0)
		{
			NDDebugOpt::setDrawRoleMonsterEnabled( val != 0 );
		}
		else if (stricmp(szDebugOpt, "drawroleplayer") == 0 ||
					stricmp(szDebugOpt, "drawplayer") == 0)
		{
			NDDebugOpt::setDrawRolePlayerEnabled( val != 0 );
		}
		else if (stricmp(szDebugOpt, "drawrolemanual") == 0 ||
					stricmp(szDebugOpt, "drawmanual") == 0)
		{
			NDDebugOpt::setDrawRoleManualEnabled( val != 0 );
		}
	}
	else if (sscanf(cmd, "openmap %d", &val) == 1)
	{
		//NDMapMgrObj.Hack_loadSceneByMapDocID( val );
	}
	else if (stricmp(cmd, "profile") == 0)
	{
		NDProfileReport::report();
	}
	else if (stricmp(cmd, "profile dump") == 0)
	{
		NDProfileReport::dump();
	}
	else if (stricmp(cmd, "dumprole") == 0)
	{
		NDScene* pScene = NDDirector::DefaultDirector()->GetRunningScene();
		int childrenCount = pScene->GetChildren().size();
		for (int i = 0; i < childrenCount; i++)
		{
			NDNode* pNode = pScene->GetChildren().at(i);
			if (pNode && pNode->IsKindOfClass(RUNTIME_CLASS(NDMapLayer)))
			{
				NDMapLayer* pLayer = (NDMapLayer*)pNode;
				pLayer->dumpRole();
			}
		}	
	}
	else if (stricmp(cmd, "showhero") == 0)
	{
		CCPoint posScreen = NDPlayer::defaultHero().GetPosition();
		DWORD n = 0;
		char msg[500] = "";
		sprintf( msg, "hero pos(%d, %d)\r\n", (int)posScreen.x, (int)posScreen.y );
		WriteConsoleA( hOut, msg, sizeof(msg), &n, NULL );		
	}
	else if (stricmp(cmd, "info") == 0)
	{
		CCPoint posScreen = NDPlayer::defaultHero().GetPosition();
		DWORD n = 0;
		char msg[500] = "";

		// dump NDDirector & CCDirector
		{
			LOGD( msg, 
				"hero pos(%d, %d)\r\n"
				"[CCDirector] size in Points  (%d, %d)\r\n"
				"[CCDirector] size in Pixels  (%d, %d)\r\n"
				"[CCDirector] content scale = %.1f\r\n"
				,
				(int)posScreen.x, (int)posScreen.y, //screen pos in pixels.

				(int)CCDirector::sharedDirector()->getWinSize().width,
				(int)CCDirector::sharedDirector()->getWinSize().height,

				(int)CCDirector::sharedDirector()->getWinSizeInPixels().width,
				(int)CCDirector::sharedDirector()->getWinSizeInPixels().height,

				CCDirector::sharedDirector()->getContentScaleFactor()
				);

			sprintf( msg, 
				"hero pos(%d, %d)\r\n"
				"[CCDirector] size in Points  (%d, %d)\r\n"
				"[CCDirector] size in Pixels  (%d, %d)\r\n"
				"[CCDirector] content scale = %.1f\r\n"
				,
				(int)posScreen.x, (int)posScreen.y, //screen pos in pixels.

				(int)CCDirector::sharedDirector()->getWinSize().width,
				(int)CCDirector::sharedDirector()->getWinSize().height,

				(int)CCDirector::sharedDirector()->getWinSizeInPixels().width,
				(int)CCDirector::sharedDirector()->getWinSizeInPixels().height,

				CCDirector::sharedDirector()->getContentScaleFactor()
				);

			WriteConsoleA( hOut, msg, strlen(msg), &n, NULL );		
		}

		// dump EGL view
		{
			CCEGLView* eglView = CCDirector::sharedDirector()->getOpenGLView();
			if (eglView)
			{
				LOGD(msg,
					"\r\n"
					"[EGLVIEW] frame     size (%d, %d)\r\n"
					"[EGLVIEW] designed  size (%d, %d)\r\n"
					"[EGLVIEW] viewport  size (%d, %d)\r\n"
					"[EGLVIEW] visible   org  (%d, %d)\r\n"
					"[EGLVIEW] visible   size (%d, %d)\r\n"
					"[EGLVIEW] scale (%.1f, %.1f)\r\n"
					//"[EGLVIEW] resolution policy (%d)\r\n"
					"[EGLVIEW] retina enabled (%d)\r\n"
					,
					/*frame*/	(int)eglView->getFrameSize().width,			(int)eglView->getFrameSize().height, 
					/*designed*/(int)eglView->getSize().width,				(int)eglView->getSize().height, 
					/*viewport*/(int)eglView->getViewPortRect().origin.x,	(int)eglView->getViewPortRect().origin.y, //in origin, not in size!
					/*vis org*/	(int)eglView->getVisibleOrigin().x,			(int)eglView->getVisibleOrigin().y,
					/*vis size*/(int)eglView->getVisibleSize().width,		(int)eglView->getVisibleSize().height,
					/*scale*/	eglView->getScaleX(), eglView->getScaleY(),
					/*policy*/
					/*retina*/	(int)eglView->isRetinaEnabled()
					);
				sprintf( msg, 
					"\r\n"
					"[EGLVIEW] frame     size (%d, %d)\r\n"
					"[EGLVIEW] designed  size (%d, %d)\r\n"
					"[EGLVIEW] viewport  size (%d, %d)\r\n"
					"[EGLVIEW] visible   org  (%d, %d)\r\n"
					"[EGLVIEW] visible   size (%d, %d)\r\n"
					"[EGLVIEW] scale (%.1f, %.1f)\r\n"
					//"[EGLVIEW] resolution policy (%d)\r\n"
					"[EGLVIEW] retina enabled (%d)\r\n"
					,
					/*frame*/	(int)eglView->getFrameSize().width,			(int)eglView->getFrameSize().height, 
					/*designed*/(int)eglView->getSize().width,				(int)eglView->getSize().height, 
					/*viewport*/(int)eglView->getViewPortRect().origin.x,	(int)eglView->getViewPortRect().origin.y, //in origin, not in size!
					/*vis org*/	(int)eglView->getVisibleOrigin().x,			(int)eglView->getVisibleOrigin().y,
					/*vis size*/(int)eglView->getVisibleSize().width,		(int)eglView->getVisibleSize().height,
					/*scale*/	eglView->getScaleX(), eglView->getScaleY(),
					/*policy*/
					/*retina*/	(int)eglView->isRetinaEnabled()
					);

				WriteConsoleA( hOut, msg, strlen(msg), &n, NULL );		
			}
		}

		// dump map layer
		{
			extern NDMapLayer* g_pMapLayer; //for debug only.
			if (g_pMapLayer)
			{
				sprintf( msg, 
					"\r\n"
					"[NDMapLayer] content size (%d, %d)\r\n"
					"[NDMapLayer] screen center (%d, %d)\r\n", 
					(int)g_pMapLayer->GetContentSize().width,
					(int)g_pMapLayer->GetContentSize().height,
					(int)g_pMapLayer->GetScreenCenter().x,
					(int)g_pMapLayer->GetScreenCenter().y
					);

				WriteConsoleA( hOut, msg, strlen(msg), &n, NULL );	
			}
		}

		// dump world map layer
		{
			extern WorldMapLayer* g_pWorldMapLayer; //for debug only.
			if (g_pWorldMapLayer)
			{
				sprintf( msg, 
					"\r\n"
					"[WorldMapLayer] content size (%d, %d)\r\n", 
					(int)g_pWorldMapLayer->GetContentSize().width,
					(int)g_pWorldMapLayer->GetContentSize().height
					);

				WriteConsoleA( hOut, msg, strlen(msg), &n, NULL );	
			}
		}
	}
	else if (sscanf(cmd, "slowdown %d", &val) == 1)
	{
		extern int g_slowDownMul;
		g_slowDownMul = max(1,val);
	}
	else if (
		sscanf(cmd, "drawdebug %d", &val) == 1 ||
		sscanf(cmd, "debugdraw %d", &val) == 1 ||
		sscanf(cmd, "enablefocus %d", &val) == 1)
	{
		NDDebugOpt::setDrawDebugEnabled(val);
	}
	else if (stricmp(cmd, "test") == 0) //open test ui (test.ini)
	{
		NDScene* pScene = NDDirector::DefaultDirector()->GetRunningScene();
		if (pScene)
		{
			pScene->RemoveAllChildren( false );

			NDUILayer *	pLayer	= new NDUILayer();
			if (pLayer)
			{
				pLayer->Initialization();
				pLayer->SetFrameRect( CCRectMake(0, 0, 960, 640));
				pLayer->SetTag( 0x100 );
				pScene->AddChild(pLayer,10);

				NDUILoad loader;
				loader.Load( "test.ini", pLayer, NULL );
			}
		}
	}
	else
	{
		DWORD n = 0;
		TCHAR msg[] = L"err: unknown cmd.\r\n";
		WriteConsole( hOut, msg, sizeof(msg)/sizeof(TCHAR), &n, NULL );
	}
#endif
	return true;
}

NS_NDENGINE_END