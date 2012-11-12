//
//  NDPlayer.mm
//  DragonDrive
//
//  Created by xiezhenghai on 10-12-27.
//  Copyright 2010 (网龙)DeNA. All rights reserved.
//

#include "NDPlayer.h"
#include "NDConstant.h"
#include "NDTransData.h"
#include "NDDataTransThread.h"
#include "NDMapLayer.h"
#include "NDMsgDefine.h"
#include "NDDirector.h"
#include "GameSceneLoading.h"
#include "ItemMgr.h"
#include "NDItemType.h"
#include "CCPointExtension.h"
///< #include "NDMapMgr.h" 临时性注释 郭浩
#include "NDNpc.h"
#include "NDUISynLayer.h"
#include "NDAutoPath.h"
#include "BattleMgr.h"
#include "BattleSkill.h"
#include "EnumDef.h"
#include "GameScene.h"
#include "VendorBuyUILayer.h"
#include "HarvestEvent.h"
#include "DirectKey.h"
#include "AutoPathTip.h"
///< #include "NDMapMgr.h" 临时性注释 郭浩
#include "QuickInteraction.h"
#include "NDString.h"

#include "ScriptMgr.h"
#include "ScriptTask.h"
#include <sstream>

#include "SMGameScene.h"
#include "ScriptGlobalEvent.h"
#include "NDUtil.h"

namespace NDEngine
{
#define MAX_DACOITY_STEP (5)

#define MAX_BATTLEFIELD_STEP (5)

#define INVALID_FOCUS_NPC_ID (0)

//劫匪与捕块判断距离
#define DACOITY_JUDGE_DISTANCE (0)

//战场中对立方判断距离( (cellX1-cellX2)^2+(cellY1-cellY2)^2 )
#define BATTLEFIELD_DISTANCE (1)

NDMapLayer* M_GetMapLayer()
{
	//return NDMapMgrObj.getMapLayerOfScene(NDDirector::DefaultDirector()->GetScene(RUNTIME_CLASS(CSMGameScene))); ///< 临时性注释 郭浩

	return 0; ///< 临时性的加上，到时候要去掉 郭浩
}

static NDPlayer* g_pkDefaultHero = NULL;

IMPLEMENT_CLASS(NDPlayer, NDManualRole)

bool NDPlayer::ms_bFirstUse = true;

NDPlayer::NDPlayer() :
//money(0),
m_nEMoney(0),
m_nPhyPoint(0),
m_nDexPoint(0),
m_nMagPoint(0),
m_nDefPoint(0),
m_nLevelUpExp(0),
m_nSP(0),
m_nSWCountry(0),
m_nSWCamp(0),
m_nHonour(0),
//synRank(-1),
m_nSynMoney(0),
m_nSynContribute(0),
m_nSynSelfContribute(0),
m_nSynSelfContributeMoney(0),
m_nCurMapID(0)
{
	phyAdd = 0;

	/** 敏捷附加 */
	dexAdd = 0;

	/** 体力附加 */
	defAdd = 0;

	/** 智力附加 */
	magAdd = 0;

	/** 物攻附加 */
	wuGongAdd = 0;

	/** 物防附加 */
	wuFangAdd = 0;

	/** 法攻附加 */
	faGongAdd = 0;

	/** 法防附加 */
	faFangAdd = 0;

	/** 闪避附加 */
	sanBiAdd = 0;

	/** 暴击附加 */
	baoJiAdd = 0;

	/** 物理命中附加 */
	wuLiMingZhongAdd = 0;

	m_nGamePoints = 0;

	m_nServerCol = -1;
	m_nServerRow = -1;
	m_nStorgeMoney = 0;
	m_nStorgeEmoney = 0;
	m_nSkillPoint = 0;

	// 装备直接属性增加值
	m_eAtkSpd = 0;
	m_eAtk = 0;
	m_eDef = 0;
	m_eHardAtk = 0;
	m_eSkillAtk = 0;
	m_eSkillDef = 0;
	m_eSkillHard = 0;
	m_eDodge = 0;
	m_ePhyHit = 0;

	m_iTmpPhyPoint = 0;
	m_iTmpDexPoint = 0;
	m_iTmpMagPoint = 0;
	m_iTmpDefPoint = 0;
	m_iTmpRestPoint = 0;

	m_nBeginProtectedTime = 0;

	m_iFocusManuRoleID = -1;
	//m_npcFocus = NULL;

	m_nTargetIndex = 0;
	m_bCollide = false;
	m_pkTimer = new NDTimer();
	m_kGatherDlg = NULL;

	memset(&m_caclData, 0, sizeof(m_caclData));

	m_bRequireDacoity = false;
	m_iDacoityStep = 0;
	m_iBattleFieldStep = 0;

	InvalidNPC();

	m_nActivityValue = 0;
	m_nActivityValueMax = 0;
	m_nExpendHonour = 0;
	m_nMaxSlot = 0;
	m_nVipLev = 0;
	m_nLookface = 0;
	m_bLocked = false;
}

NDPlayer::~NDPlayer()
{
	g_pkDefaultHero = NULL;
	
	SAFE_DELETE(m_pkTimer);
}

NDPlayer& NDPlayer::defaultHero(int lookface/* = 0*/,
		bool bSetLookFace/*=false*/)
{
	if (ms_bFirstUse)
	{
		ms_bFirstUse = false;
	}

	if (!g_pkDefaultHero)
	{
		g_pkDefaultHero = new NDPlayer();
		g_pkDefaultHero->Initialization(lookface, false);
		g_pkDefaultHero->SetLookface(lookface);
	}

	return *g_pkDefaultHero;
}

void NDPlayer::pugeHero()
{
	SAFE_DELETE_NODE (g_pkDefaultHero);
}

void NDPlayer::SendNpcInteractionMessage(unsigned int uiNPCID)
{
	// 转到脚本处理
	ScriptMgr& kScript = ScriptMgr::GetSingleton();
	std::stringstream ssNpcFunc;
	ssNpcFunc << "NPC_CLICK_" << uiNPCID;
	bool bRet = kScript.IsLuaFuncExist(ssNpcFunc.str().c_str(), "NPC");

	if (bRet)
	{
 		bRet = kScript.excuteLuaFunc(ssNpcFunc.str().c_str(), "NPC", uiNPCID);
		kScript.excuteLuaFunc("AttachTask", "NPC", uiNPCID);
	}
	else
	{
		bRet = kScript.excuteLuaFunc("NPC_CLICK_COMMON", "NPC", uiNPCID);
	}

	return;

	ShowProgressBar;
	NDTransData kTranslateData(_MSG_NPC);
	kTranslateData << (int) uiNPCID << (unsigned char) 0 << (unsigned char) 0 << int(123);
	NDDataTransThread::DefaultThread()->GetSocket()->Send(&kTranslateData);
}

bool NDPlayer::DealClickPointInSideNpc(CGPoint point)
{
	bool bDeal = false;

	/***
	 * 临时性注释 郭浩
	 * begin
	 */

// 		NDMapMgr::VEC_NPC& npclist = NDMapMgrObj.m_vNpc;
// 		for (NDMapMgr::vec_npc_it it = npclist.begin(); it != npclist.end(); it++) 
// 		{
// 			NDNpc* npc = *it;
// 
// 			if (!npc)
// 			{
// 				continue;
// 			}
// 
// 			if (npc->IsPointInside(point))
// 			{
// 				bDeal = true;
// 
// 				npc->ShowHightLight(true);
// 			}
// 			else
// 			{
// 				npc->ShowHightLight(false);
// 			}
// 		}
	/***
	 * 临时性注释 郭浩
	 * end
	 */

	NDDirector* pkDirector = NDDirector::DefaultDirector();
	NDScene* pkScene = pkDirector->GetRunningScene();
	NDNode* pkMapLayerNode = pkScene->GetChild(MAPLAYER_TAG);

	if (!pkMapLayerNode->IsKindOfClass(RUNTIME_CLASS(NDMapLayer)))
	{
		return false;
	}

	NDMapLayer* pkLayer = (NDMapLayer*) pkMapLayerNode;
	for(int i = 10001; i < 10001 + 4; i++)
	{
		NDNode* pkNpcNode = pkLayer->GetChild(i);
		if (pkNpcNode && pkNpcNode->IsKindOfClass(RUNTIME_CLASS(NDNpc)))
		{
			NDNpc* npc = (NDNpc*)pkNpcNode;
			if (npc->IsPointInside(point))
			{
				bDeal = true;
				npc->ShowHightLight(true);
			}
			else
			{
				npc->ShowHightLight(false);
			}
		}
	}

	return bDeal;
}

bool NDPlayer::CancelClickPointInSideNpc()
{
	/***
	 * 临时性注释 郭浩
	 * all
	 */

	// 		NDMapMgr::VEC_NPC& npclist = NDMapMgrObj.m_vNpc;
// 		for (NDMapMgr::vec_npc_it it = npclist.begin(); it != npclist.end(); it++) 
// 		{
// 			NDNpc* npc = *it;
// 			
// 			if (!npc)
// 			{
// 				continue;
// 			}
// 			
// 			npc->ShowHightLight(false);
// 		}

	NDDirector* pkDirector = NDDirector::DefaultDirector();
	NDScene* pkScene = pkDirector->GetRunningScene();
	NDNode* pkMapLayerNode = pkScene->GetChild(MAPLAYER_TAG);

	if (!pkMapLayerNode->IsKindOfClass(RUNTIME_CLASS(NDMapLayer)))
	{
		return false;
	}

	NDMapLayer* pkLayer = (NDMapLayer*) pkMapLayerNode;
	for(int i = 10001; i < 10001 + 4; i++)
	{
		NDNode* pkNpcNode = pkLayer->GetChild(i);
		if (pkNpcNode && pkNpcNode->IsKindOfClass(RUNTIME_CLASS(NDNpc)))
		{
			NDNpc* npc = (NDNpc*)pkNpcNode;
			npc->ShowHightLight(false);
		}
	}

	return true;

}

bool NDPlayer::ClickPoint(CGPoint point, bool bLongTouch, bool bPath/*=true*/)
{
	CCLog("Clicked");

	/***
	 * 临时性注释 郭浩
	 **/

	if (AutoPathTipObj.IsWorking())
	{
		AutoPathTipObj.Stop();
	}
	//
	//if (ScriptMgrObj.excuteLuaFunc("CloseMainUI", ""))
	//{
	//	this->stopMoving();
	//	return false;
	//}
	//
	//if (bLongTouch && bPath)
	//{
	//	//长按不执行其它操作
	//	NDPlayer::defaultHero().Walk(point, SpriteSpeedStep4);
	//	return true;
	//}
	//
	//bool bNpcPath = false;
	//
	NDScene* pkRunningScene = NDDirector::DefaultDirector()->GetRunningScene();
	if (pkRunningScene->IsKindOfClass(RUNTIME_CLASS(CSMGameScene)))
	{
		CSMGameScene* gameScene = (CSMGameScene*)pkRunningScene;
		if (!NDUISynLayer::IsShown())// && !gameScene->IsUIShow())
		{
			int a = 10;
		}
	}
// 
// 
// 				if (bDealed)
// 				{
// 					break;
// 				}
// 					
// 				// 2.再处理角色
// 				//other role
// 				if ( m_iFocusManuRoleID != -1 )
// 				{
// 					NDManualRole *otherplayer = NDMapMgrObj.GetManualRole(m_iFocusManuRoleID);
// 					if (otherplayer && CGRectContainsPoint(otherplayer->GetFocusRect(), point)) 
// 					{
// 						if ( otherplayer->IsInState(USERSTATE_BOOTH) )
// 						{ //与其摆摊玩家交互
// 							NDUISynLayer::Show();
// 							VendorBuyUILayer::s_idVendor = otherplayer->m_id;
// 							
// 							NDTransData bao(_MSG_BOOTH);
// 							bao << Byte(BOOTH_QUEST) << otherplayer->m_id << int(0);
// 							// SEND_DATA(bao);
// 						}
// 						
// 						QuickInteraction::RefreshOptions();
// 						
// 						return false;
// 					}
// 				}
// 				else
// 				{
// 					NDMapMgr::map_manualrole& roles = NDMapMgrObj.GetManualRoles();
// 					
// 					bool find = false;
// 					for (NDMapMgr::map_manualrole_it it = roles.begin(); it != roles.end(); it++) 
// 					{
// 						NDManualRole* role = it->second;
// 						
// 						if (role->bClear) continue;
// 						
// 						if ( !CGRectContainsPoint(role->GetFocusRect(), point)) continue;
// 						
// 						find = true;
// 						
// 						SetFocusRole(role);
// 						
// 						return false;
// 					}
// 				}
// 				
// 				}while(0);
// 			}
// 		}
// 		
 		if (bPath)
 		{
 			NDPlayer::defaultHero().Walk(point, SpriteSpeedStep4);
 		}
// 		
// 		if (m_pointList.empty())
// 		{
// 			NDMapLayer* layer = M_GetMapLayer();
// 			if (layer)
// 			{
// 				layer->ShowRoadSign(false);
// 			}
// 			
// 			return false;
// 		}
	/***
	 * 临时性注释 郭浩
	 * end
	 */

	return true;
}

void NDPlayer::stopMoving(bool bResetPos/*=true*/, bool bResetTeamPos/*=true*/)
{
	/***
	 * 临时性注释 郭浩
	 * all
	 */

	// 		NDMapLayer* maplayer = M_GetMapLayer();
// 		if (maplayer)
// 		{
// 			maplayer->ShowRoadSign(false);
// 		}
// 		
 		NDManualRole::stopMoving(bResetPos, bResetTeamPos);
// 		
 		m_kTargetPos = CGPointZero;
// 		
 		//NDScene *scene = NDDirector::DefaultDirector()->GetScene(RUNTIME_CLASS(CSMGameScene));
 		//if (scene) 
 		//{
 		//	NDMapLayer* layer = NDMapMgrObj.getMapLayerOfScene(scene);
 		//	layer->SetScreenCenter(this->GetPosition());
 		//}
 		
 		if (AutoPathTipObj.IsWorking()) 
 		{
 			AutoPathTipObj.Stop();
 		}
}

Task* NDPlayer::GetPlayerTask(int idTask)
{
	Task* task = NULL;

	for (vec_task_it it = m_vPlayerTask.begin(); it != m_vPlayerTask.end();
			it++)
	{
		task = *it;

		if (task->m_nTaskID == idTask)
		{
			return task;
		}
	}

	return NULL;
}

int NDPlayer::GetOrder()
{
	if (m_pkRidePet)
	{
		return m_pkRidePet->GetOrder() + 1;
	}

	return NDManualRole::GetOrder();

}

void NDPlayer::Walk(CGPoint toPos, SpriteSpeed speed, bool mustArrive/*=false*/)
{
	/***
	* 临时性注释 郭浩
	* begin
	*/
// 	if (!isRoleCanMove())
// 	{
// 		return;
// 	}
	/***
	* 临时性注释 郭浩
	* end
	*/

	CGPoint kPos = CGPointMake(
			int(toPos.x) / MAP_UNITSIZE * MAP_UNITSIZE + DISPLAY_POS_X_OFFSET,
			int(toPos.y) / MAP_UNITSIZE * MAP_UNITSIZE + DISPLAY_POS_Y_OFFSET);

	CGPoint kCurrentPosition = GetPosition();

	if (((int) kCurrentPosition.x - DISPLAY_POS_X_OFFSET) % MAP_UNITSIZE != 0
			|| ((int) kCurrentPosition.y - DISPLAY_POS_Y_OFFSET) % MAP_UNITSIZE != 0)
	{ // Cell没走完,又设置新的目标
		m_kTargetPos = kPos;
	}
	else
	{
		std::vector < CGPoint > vPos;
		//kPos = ccpAdd(kPos,kPos);
		vPos.push_back(kPos);
		this->WalkToPosition(vPos, speed, true, mustArrive);
	}

	ResetFocusRole();
}

void NDPlayer::SetPosition(CGPoint newPosition)
{
	int nNewCol = (newPosition.x - DISPLAY_POS_X_OFFSET) / MAP_UNITSIZE;
	int nNewRow = (newPosition.y - DISPLAY_POS_Y_OFFSET) / MAP_UNITSIZE;
	int nOldCol = (GetPosition().x - DISPLAY_POS_X_OFFSET) / MAP_UNITSIZE;
	int nOldRow = (GetPosition().y - DISPLAY_POS_Y_OFFSET) / MAP_UNITSIZE;

	NDManualRole::SetPosition(newPosition);

	if (!isTeamLeader() && isTeamMember())
	{
		return;
	}

	if (nNewCol != nOldCol || nNewRow != nOldRow)
	{
		if (nOldCol == 0 && nOldRow == 0)
		{
		}
		else
		{
			/*
			 int dir = nNewCol != nOldCol ? ( nNewCol > nOldCol ? 3 : 2 ) :
			 ( nNewRow != nOldRow ? (nNewRow > nOldRow ? 1 : 0 ) : -1 );
			 */
			int dir = this->GetPathDir(nOldCol, nOldRow, nNewCol, nNewRow);

			if (dir != -1)
			{
				/***
				 * 临时性注释 郭浩
				 * begin
				 */

// 					if(NDMapMgrObj.GetMotherMapID()/100000000!=9)
// 					{
// 						NDTransData data(_MSG_WALK_EX);
// 						
// 						data << m_id << (unsigned short)nNewCol 
// 						<< (unsigned short)nNewRow << (unsigned char)dir;
// 						
// 						NDDataTransThread::DefaultThread()->GetSocket()->Send(&data);
// 					}
// 					serverCol = nNewCol;
// 					serverRow = nNewRow;
// 					//SetServerDir(dir);
// 					
// 					if (isTeamLeader()) 
// 					{
// 						teamSetServerDir(dir);
// 					}
// 				
 					//processSwitch();
// 					
// 					if (m_iDacoityStep < MAX_DACOITY_STEP) m_iDacoityStep++;
// 					
// 					if (m_iBattleFieldStep < MAX_BATTLEFIELD_STEP) m_iBattleFieldStep++;
				/***
				 * 临时性注释 郭浩
				 * end
				 */
			}
		}
	}
}

void NDPlayer::Update(unsigned long ulDiff)
{
	NDManualRole::Update(ulDiff);

	/***
	 * 临时性注释 郭浩
	 * all
	 */

//		if (isSafeProtected) 
//		{
//			int intervalTime = [NSDate timeIntervalSinceReferenceDate] - beginProtectedTime;
//			if (intervalTime > BEGIN_PROTECTED_TIME)
//			{
//				setSafeProtected(false);
//			}
//		}
//		
//		NDMapMgr& mgr = NDMapMgrObj;
//		if (mgr.GetBattleMonster()) 
//		{
//			m_targetPos = CGPointZero;
//			return;
//		}
//		
//		if (!m_bRequireBattleField && m_iBattleFieldStep >= MAX_BATTLEFIELD_STEP)
//		{
//			HandleStateBattleField();
//		}
//		
//		if (IsInDacoity() && !m_bRequireDacoity && m_iDacoityStep >= MAX_DACOITY_STEP) 
//		{
//			HandleStateDacoity();
//		}
//		
//		// 采集
//		//if (!m_bCollide)
//		//{
//		//	map_gather_point& mapgp = mgr.m_mapGP;
//		//	map_gather_point_it it = mapgp.begin();
//		//	for (; it != mapgp.end(); it++)
//		//	{
//		//		GatherPoint *gp = it->second;
//		//		if (doGatherPointCollides(gp))
//		//		{
//		//			std::string str;
//		//			str += NDCommonCString("GatherOrNot"); str += gp->getName(); str += "?";
//		//			m_dlgGather = new NDUIDialog;
//		//			m_dlgGather->Initialization();
//		//			m_dlgGather->SetDelegate(this);
//		//			m_dlgGather->Show(NDCommonCString("WenXinTip"), str.c_str(), NDCommonCString("Cancel"), NDCommonCString("gather"), NULL);
//		//			m_gp = gp;
//		//			m_bCollide = true;
//		//			break;
//		//		}
//		//	}
//		//}
//		
//		CGPoint pos = GetPosition();
//		if (int(m_targetPos.x) != 0 
//			&& int(m_targetPos.y) != 0
//			&& ( (int)pos.x-DISPLAY_POS_X_OFFSET) % 32 == 0
//			&& ( (int)pos.y-DISPLAY_POS_Y_OFFSET) % 32 == 0
//			)
//		{
//			//if (this->GetParent()) 
////			{
////				NDLayer* layer = (NDLayer *)this->GetParent();
////				if (layer->IsKindOfClass(RUNTIME_CLASS(NDMapLayer))) 
////				{
////					m_movePathIndex = 0;
////					NDAutoPath::sharedAutoPath()->autoFindPath(m_position, m_targetPos, (NDMapLayer*)layer, m_iSpeed);
////					m_pointList = NDAutoPath::sharedAutoPath()->getPathPointVetor();
////					m_targetPos = CGPointZero;
////				}		
////			}
//			std::vector<CGPoint> vec_pos; vec_pos.push_back(m_targetPos);
//			this->WalkToPosition(vec_pos, SpriteSpeedStep4, true);
//			m_targetPos = CGPointZero;
//			ResetFocusRole();
//		}
//		
//		HandleDirectKey();
//		
//		updateFlagOfQiZhi();
}

void NDPlayer::OnMoving(bool bLastPos)
{
	NDManualRole::OnMoving(bLastPos);

	ScriptGlobalEvent::OnEvent (GE_ONMOVE);
}

void NDPlayer::OnMoveBegin()
{
	NDMapLayer* maplayer = M_GetMapLayer();
	if (!maplayer || m_kPointList.size() == 0)
	{
		return;
	}

	CGPoint pos = m_kPointList[m_kPointList.size() - 1];
	int nX = (pos.x - DISPLAY_POS_X_OFFSET) / MAP_UNITSIZE;
	int nY = (pos.y - DISPLAY_POS_Y_OFFSET) / MAP_UNITSIZE;

	maplayer->ShowRoadSign(true, nX, nY);
}

void NDPlayer::OnMoveEnd()
{
	//ScriptGlobalEvent::OnEvent (GE_ONMOVE);

	NDMapLayer* pkMaplayer = M_GetMapLayer();
	if (pkMaplayer)
	{
		pkMaplayer->ShowRoadSign(false);
	}

	if (!isTeamLeader() && isTeamMember())
	{
		return;
	}

	//SetAction(false);
	//SetCurrentAnimation(MANUELROLE_STAND,false);
	NDManualRole::OnMoveEnd();
// 	if (isTeamLeader())
// 	{
// 		teamMemberAction(false);
// 	}

	SetCurrentAnimation(MANUELROLE_STAND,m_bReverse);

	//玩家停下来的时候 做聚焦改变处理	npc加载完成后,也做一次聚焦改变处理
	UpdateFocus();

	if (AutoPathTipObj.IsWorking())
	{
		AutoPathTipObj.Arrive();
	}
}

void NDPlayer::OnDrawEnd(bool bDraw)
{
	NDManualRole::OnDrawEnd(bDraw);
	//	HarvestEventMgrObj.OnTimer(0); ///< 临时性注释 郭浩
}

void NDPlayer::CaclEquipEffect()
{
	m_eAtkSpd = 0;
	m_eAtk = 0;
	m_eDef = 0;
	m_eHardAtk = 0;
	m_eSkillAtk = 0;
	m_eSkillDef = 0;
	m_eSkillHard = 0;
	m_eDodge = 0;
	m_ePhyHit = 0;

	for (int i = Item::eEP_Begin; i < Item::eEP_End; i++)
	{
		if (ItemMgrObj.EquipHasNotEffect((Item::eEquip_Pos) i) == true)
		{
			continue;
		}

		Item* pkItem = ItemMgrObj.GetEquipItemByPos((Item::eEquip_Pos) i);
		if (pkItem == NULL)
		{
			continue;
		}

		NDItemType *itemtype = ItemMgrObj.QueryItemType(pkItem->m_nItemType);
		if (itemtype == NULL)
		{
			continue;
		}

		m_eAtkSpd += itemtype->m_data.m_atk_speed + pkItem->getInlayAtk_speed();

		m_eAtk += pkItem->getAdditionResult(itemtype->m_data.m_enhancedId,
				pkItem->m_nAddition, itemtype->m_data.m_atk) + pkItem->getInlayAtk();
		m_eDef += pkItem->getAdditionResult(itemtype->m_data.m_enhancedId,
				pkItem->m_nAddition, itemtype->m_data.m_def) + pkItem->getInlayDef();
		m_eHardAtk += itemtype->m_data.m_hard_hitrate
				+ pkItem->getInlayHard_hitrate();
		m_eSkillAtk += pkItem->getAdditionResult(itemtype->m_data.m_enhancedId,
				pkItem->m_nAddition, itemtype->m_data.m_mag_atk)
				+ pkItem->getInlayMag_atk();
		m_eSkillDef += pkItem->getAdditionResult(itemtype->m_data.m_enhancedId,
				pkItem->m_nAddition, itemtype->m_data.m_mag_def)
				+ pkItem->getInlayMag_def();
		m_eSkillHard += itemtype->m_data.m_mana_limit
				+ pkItem->getInlayMana_limit();
		m_eDodge += itemtype->m_data.m_dodge + pkItem->getInlayDodge();
		m_ePhyHit += itemtype->m_data.m_hitrate + pkItem->getInlayHitrate(); // 物理命中
	}
}

void NDPlayer::NextFocusTarget()
{
	/***
	 * 临时性注释 郭浩
	 * all
	 */
// 		if ( isTeamMember() && !isTeamLeader() )
// 		{
// 			return;
// 		}
// 		
// 		if (!this->GetParent() || !this->GetParent()->IsKindOfClass(RUNTIME_CLASS(NDMapLayer)))
// 		{
// 			return;
// 		}
// 		
// 		SetFocusRole(NDMapMgrObj.GetNextTarget(FOCUS_JUDGE_DISTANCE));
}

void NDPlayer::UpdateFocus()
{

	/***
	 * 临时性注释 郭浩
	 * all
	 */
	// 		if ( isTeamMember() && !isTeamLeader() )
// 		{
// 			return;
// 		}
// 		
// 		if (!this->GetParent() || !this->GetParent()->IsKindOfClass(RUNTIME_CLASS(NDMapLayer)))
// 		{
// 			return;
// 		}
// 		
// 		SetFocusRole(NDMapMgrObj.GetRoleNearstPlayer(FOCUS_JUDGE_DISTANCE));
}

void NDPlayer::SetFocusRole(NDBaseRole *baserole)
{
	CSMGameScene* gs =
			(CSMGameScene*) NDDirector::DefaultDirector()->GetSceneByTag(
					SMGAMESCENE_TAG);
	/*if (gs) {
	 gs->SetTargetHead(baserole);
	 gs->RefreshQuickInterationBar(baserole);
	 }*/

	if (!baserole)
	{
		ResetFocusRole();
		return;
	}

	if (baserole->IsKindOfClass(RUNTIME_CLASS(NDNpc)))
	{
		ResetFocusRole();
		m_iFocusNpcID = baserole->m_nID;
		baserole->SetFocus(true);
		return;
	}

	/***
	 * 临时性注释 郭浩
	 * begin
	 */
// 		if (baserole->IsKindOfClass(RUNTIME_CLASS(NDManualRole)))
// 		{
// 			ResetFocusRole();
// 			m_iFocusManuRoleID = baserole->m_id;
// 			NDManualRole *otherplayer = NDMapMgrObj.GetManualRole(m_iFocusManuRoleID);
// 			if (!otherplayer)
// 			{
// 				ResetFocusRole();
// 			}
// 			
// 			otherplayer->SetFocus(true);
// 			return;
// 		}
	/***
	 * 临时性注释 郭浩
	 * end
	 */
}

void NDPlayer::UpdateFocusPlayer()
{
	/***
	 * 临时性注释 郭浩
	 * all
	 */

	// 		if ( m_iFocusManuRoleID != -1 )
// 		{
// 			NDManualRole *otherplayer = NDMapMgrObj.GetManualRole(m_iFocusManuRoleID);
// 			if ( !otherplayer || otherplayer->bClear) SetFocusRole(NULL);
// 		}
}

void NDPlayer::ResetFocusRole()
{
	/***
	 * 临时性注释 郭浩
	 * all
	 */

// 		if ( m_iFocusManuRoleID != -1 )
// 		{
// 			NDManualRole *otherplayer = NDMapMgrObj.GetManualRole(m_iFocusManuRoleID);
// 			if ( otherplayer ) otherplayer->SetFocus(false);
// 		}
// 		
// 		m_iFocusManuRoleID = -1;
// 		
// 		if (IsFocusNpcValid()) 
// 		{
// 			NDNpc *focusNpc = GetFocusNpc();
// 			
// 			if (focusNpc) focusNpc->SetFocus(false);
// 			
// 			InvalidNPC();
// 		}
}

void NDPlayer::AddSkill(OBJID idSkill)
{
	BattleMgr& kBattleMgr = BattleMgrObj;
	BattleSkill* pkSkill = kBattleMgr.GetBattleSkill(idSkill);

	if (!pkSkill)
	{
		return;
	}

	if (pkSkill->getType() == SKILL_TYPE_ATTACK)
	{
		this->m_setActSkill.insert(idSkill);
	}
	else if (pkSkill->getType() == SKILL_TYPE_PASSIVE)
	{
		this->m_setPasSkill.insert(idSkill);
	}
}

void NDPlayer::DelSkill(OBJID idSkill)
{
	if (this->m_setActSkill.count(idSkill) > 0)
	{
		this->m_setActSkill.erase(idSkill);
	}
	else
	{
		this->m_setPasSkill.erase(idSkill);
	}
}

SET_BATTLE_SKILL_LIST& NDPlayer::GetSkillList(SKILL_TYPE type)
{
	if (type == SKILL_TYPE_ATTACK)
	{
		return this->m_setActSkill;
	}
	else
	{
		return this->m_setPasSkill;
	}
}

bool NDPlayer::IsBattleSkillLearned(OBJID idSkill)
{
	return this->m_setActSkill.count(idSkill) > 0
			|| this->m_setPasSkill.count(idSkill) > 0;
}

//bool NDPlayer::doGatherPointCollides(GatherPoint *se)
//{
//	if ( this->IsInState(USERSTATE_FIGHTING)
//	    || this->IsSafeProtected() || this->IsInState(USERSTATE_DEAD) )
//		return false;
//
//	if (NDMapMgrObj.GetBattleMonster())
//	{
//		return false;
//	}
//
//	if (!se)
//	{
//		return false;
//	}
//
//	if (!se->isAlive()) {
//		return false;
//	}
//
//	bool collides = se->isCollides(GetPosition().x, GetPosition().y-8,
//									 8, 8);
//
//	if (collides) {
//		if (!se->isJustCollided()) { // 防止一直碰到采集点
//			se->setJustCollided(true);
//			return true;
//		}
//	} else {
//		se->setJustCollided(false);
//	}
//	return false;
//}

bool NDPlayer::DirectSwitch(int iSwitchCellX, int iSwitchCellY, int iPassIndex)
{
	if (!CanSwitch(iSwitchCellX, iSwitchCellY))
	{
		return false;
	}

	AutoPathTipObj.Stop();
	this->stopMoving();
	ScriptGlobalEvent::OnEvent(GE_SWITCH, iPassIndex);
	/*
	 NDTransData // SEND_DATA;

	 // SEND_DATA.WriteShort(_MSG_POSITION);
	 // SEND_DATA.WriteInt(m_id);
	 // SEND_DATA.WriteShort(iSwitchCellX);
	 // SEND_DATA.WriteShort(iSwitchCellY);
	 // SEND_DATA.WriteInt(iPassIndex);
	 // SEND_DATA.WriteInt(_POSITION_MAPCHANGE);

	 NDDataTransThread::DefaultThread()->GetSocket()->Send(&// SEND_DATA);

	 isLoadingMap = true;

	 NDDirector::DefaultDirector()->PushScene(GameSceneLoading::Scene());

	 this->stopMoving();
	 */

	return true;
}

bool NDPlayer::CanSwitch(int iSwitchCellX, int iSwitchCellY)
{

	int x = (int(this->GetPosition().x) - DISPLAY_POS_X_OFFSET) / MAP_UNITSIZE;
	int y = (int(this->GetPosition().y) - DISPLAY_POS_Y_OFFSET) / MAP_UNITSIZE;

	/*
	 if (x == iSwitchCellX && y == iSwitchCellY)
	 {
	 return true;
	 }
	 */

	if (abs(x - iSwitchCellX) <= 2 && abs(y - iSwitchCellY) <= 0)
	{
		return true;
	}

	return false;
}

void NDPlayer::processSwitch()
{
	// 遍历所有切屏点

	/***
	 * 临时性注释 郭浩
	 * all
	 */
// 		CSMGameScene* scene = (CSMGameScene*)NDDirector::DefaultDirector()->GetSceneByTag(SMGAMESCENE_TAG);
// 		
// 		if (!scene) return;
// 		
// 		NDMapLayer *maplayer = NDMapMgrObj.getMapLayerOfScene(scene);
// 		
// 		if (!maplayer) return;
// 		
// 		NDMapData *mapdata = maplayer->GetMapData();
// 		
// 		if (mapdata && mapdata.switchs)
// 		{
// 			cocos2d::CCArray	*switchs = mapdata.switchs;
// 			
// 			for (int i = 0; i < (int)[switchs count]; i++)
// 			{
// 				NDMapSwitch *mapswitch = [switchs objectAtIndex:i];
// 				
// 				if (!mapswitch) continue;
// 				if (DirectSwitch(mapswitch.x, mapswitch.y, mapswitch.passIndex)) 
// 					break;
// 			}
// 		}
}

bool NDPlayer::isRoleCanMove()
{
	return !IsInState(USERSTATE_BOOTH) && (isTeamLeader() || !isTeamMember())
			&& !m_bLocked;
}

void NDPlayer::OnDialogClose(NDUIDialog* dialog)
{
	m_bCollide = false;
	//m_gp = NULL;
}

void NDPlayer::OnDialogButtonClick(NDUIDialog* dialog, unsigned int buttonIndex)
{
	//if (m_bCollide && m_gp)
	//{
	//	NDUISynLayer::ShowWithTitle(NDCommonCString("gathering"));
	//	m_timer->SetTimer(this, 101, 5.0f);
	//	dialog->SetVisible(false);
	//}
}

void NDPlayer::OnTimer(OBJID tag)
{
	//if (m_bCollide && m_gp)
	//{
	//	m_timer->KillTimer(this, 101);
	//	m_gp->sendCollection();
	//	if (m_dlgGather)
	//	{
	//		m_dlgGather->Close();
	//	}
	//}
}

void NDPlayer::HandleDirectKey()
{
	NDScene* pkScene = NDDirector::DefaultDirector()->GetRunningScene();

	if (!pkScene || !pkScene->IsKindOfClass(RUNTIME_CLASS(GameScene)))
	{
		return;
	}

	if (!this->GetParent()
			|| !this->GetParent()->IsKindOfClass(RUNTIME_CLASS(NDMapLayer)))
	{
		return;
	}

	/***
	 * 临时性注释 郭浩
	 * begin
	 */
//		DirectKey* dk = ((GameScene*)scene)->GetDirectKey();
// 		if (!dk)
// 		{
// 			return;
// 		}
	/***
	 * 临时性注释 郭浩
	 * end
	 */

	dk_vec_pos kPosVector;

//		if (!dk->GetPosList(vpos)) return; ///< 临时性注释 郭浩

	//dk->ClearPosList();

	this->WalkToPosition(kPosVector, SpriteSpeedStep4, true);
}

void NDPlayer::HandleStateDacoity()
{
	/***
	 * 临时性注释 郭浩
	 * all
	 */
	//if (this->IsInState(USERSTATE_FIGHTING)
	//	|| this->IsInState(USERSTATE_DEAD)
	//	|| this->IsInState(USERSTATE_PVE)
	//	|| (isTeamMember() && !isTeamLeader())
	//	|| this->IsInState(USERSTATE_BATTLEFIELD)
	//	)
	//{
	//	return;
	//}
	//
	//NDMapMgr& mapmgr = NDMapMgrObj;
	//
	//if (!(mapmgr.canPk()))
	//{
	//	return;
	//}
	//
	//NDScene *scene = NDDirector::DefaultDirector()->GetRunningScene();
	//if (!scene || !scene->IsKindOfClass(RUNTIME_CLASS(GameScene)))
	//{
	//	return;
	//}
	//
	////与其它玩家碰撞检测
	//NDManualRole* role = mapmgr.NearestDacoityManualrole(*this, DACOITY_JUDGE_DISTANCE);
	//
	//if (!role) return;
	//
	////发送战斗消息
	//NDTransData bao(_MSG_BATTLEACT);
	//bao << (unsigned char)BATTLE_ACT_USER_COLLIDE; // Action值
	//bao << (unsigned char)0; // btturn
	//bao << (unsigned char)1; // datacount
	//bao << int(role->m_id);
	//// SEND_DATA(bao);
	//
	//m_bRequireDacoity = true;
	//
	//m_iDacoityStep = 0;
}

void NDPlayer::HandleStateBattleField()
{
	/***
	 * 临时性注释 郭浩
	 * all
	 */

//		if (!this->IsInState(USERSTATE_BATTLEFIELD) ||
//		    this->IsInState(USERSTATE_BF_WAIT_RELIVE)
//			) 
//		{
//			return;
//		}
//		
//		NDMapMgr& mapmgr = NDMapMgrObj;
//		
////		if (!(mapmgr.canPk())) 
////		{
////			return;
////		}
//		
//		NDScene *scene = NDDirector::DefaultDirector()->GetRunningScene();
//		if (!scene || !scene->IsKindOfClass(RUNTIME_CLASS(GameScene)))
//		{
//			return;
//		}
//		
//		//与其它玩家碰撞检测
//		NDManualRole* role = mapmgr.NearestBattleFieldManualrole(*this, BATTLEFIELD_DISTANCE);
//		
//		if (!role) return;
//		
//		//发送战斗消息
//		NDTransData bao(_MSG_BATTLEACT);
//		bao << (unsigned char)BATTLE_ACT_USER_COLLIDE; // Action值
//		bao << (unsigned char)0; // btturn
//		bao << (unsigned char)1; // datacount
//		bao << int(role->m_id);
//		// SEND_DATA(bao);
//		
//		m_bRequireBattleField = true;
//		
//		m_iBattleFieldStep = 0;
}

void NDPlayer::BattleStart()
{
	m_bRequireDacoity = true;

	m_bRequireBattleField = true;
}

void NDPlayer::BattleEnd(int iResult)
{
	m_bRequireDacoity = false;

	m_bRequireBattleField = false;
}

bool NDPlayer::canUnpackRidePet()
{
	/***
	 * 临时性注释 郭浩
	 * begin
	 */

// 		NDMapMgr& mgr = NDMapMgrObj;
// 		
// 		NDMapLayer * maplayer = mgr.getMapLayerOfScene(NDDirector::DefaultDirector()->GetScene(RUNTIME_CLASS(GameScene)));
// 		
// 		if (maplayer && IsInState(USERSTATE_FLY) && mgr.canFly())
// 		{
// 			NDMapData *mapdata = maplayer->GetMapData();
// 			
// 			if (!mapdata || !mapdata.switchs || int([mapdata.switchs count]) == 0)
// 			{
// 				return true;
// 			}
// 			
// 			NDMapSwitch* mapswitch = [mapdata.switchs objectAtIndex:0];
// 			
// 			if (!mapswitch) return true;
// 			
// 			// 不能自动寻路到切屏点 todo
// 			CGPoint from = ccp(serverCol*MAP_UNITSIZE+DISPLAY_POS_X_OFFSET, serverRow*MAP_UNITSIZE+DISPLAY_POS_Y_OFFSET);
// 			CGPoint to = ccp(mapswitch.x*MAP_UNITSIZE+DISPLAY_POS_X_OFFSET, mapswitch.y*MAP_UNITSIZE+DISPLAY_POS_Y_OFFSET);
// 			return NDAutoPath::sharedAutoPath()->autoFindPath(from, to , maplayer,IsInState(USERSTATE_SPEED_UP) ? SpriteSpeedStep8 : SpriteSpeedStep4, false);
// 		}
	/***
	 * 临时性注释 郭浩
	 * end
	 */

	return true;
}

// NPC焦点相关操作
NDNpc* NDPlayer::GetFocusNpc()
{
	if (!IsFocusNpcValid())
	{
		return NULL;
	}

	//return NDMapMgrObj.GetNpcByID(m_iFocusNpcID); ///< 临时性注释 郭浩
}

int NDPlayer::GetFocusNpcID()
{
	return m_iFocusNpcID;
}

bool NDPlayer::IsFocusNpcValid()
{
	return m_iFocusNpcID != INVALID_FOCUS_NPC_ID;
}

void NDPlayer::InvalidNPC()
{
	m_iFocusNpcID = INVALID_FOCUS_NPC_ID;
}

int NDPlayer::GetCanUseRepute()
{
//		if (honour < expendHonour)
//			return 0;
//			
//		return honour - expendHonour;
	return m_nExpendHonour;
}

void NDPlayer::SetLookface(int nLookface)
{
	m_nLookface = nLookface;
}

int NDPlayer::GetLookface()
{
	return m_nLookface;
}

NDBattlePet* NDPlayer::GetShowPet()
{
	return 0;
}

}
