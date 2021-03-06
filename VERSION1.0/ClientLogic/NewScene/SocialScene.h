/*
 *  SocialScene.h
 *  DragonDrive
 *
 *  Created by jhzheng on 11-8-24.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef _SOCIAL_SCENE_H_
#define _SOCIAL_SCENE_H_

#include "NDCommonScene.h"
#include "SocialElement.h"

enum 
{
	eSyndicateBegin = 0,
	eSyndicateList = eSyndicateBegin,
	eSyndicateInfo,		// 军团信息（含公告，辞职，退出军团）
	eSyndicateDonate,	// 捐献
	eSyndicateMbrList,	// "军团成员"
	eSyndicateVote,		// "投票箱"
	eSyndicateUpgrade,	// "军团升级"
	eSyndicateApprove,	// "人员审核"
	eSyndicateElection,	// "职位竞选"
	eSyndicateEnd,
};

using namespace NDEngine;

class SocialScene :
public NDCommonSocialScene,
public HFuncTabDelegate
{
	DECLARE_CLASS(SocialScene)
	
	SocialScene();
	
	~SocialScene();
	
public:
	
	static SocialScene* Scene();
	
	void Initialization(); override
	
	void OnButtonClick(NDUIButton* button); override
	
	void OnHFuncTabSelect(NDHFuncTab* tab, unsigned int lastIndex, unsigned int curIndex);
	
private:
	bool m_bSynInit;
	
private:
	void OnTabLayerSelect(TabLayer* tab, unsigned int lastIndex, unsigned int curIndex); override
	
	void InitTutor(NDUIClientLayer* client);
	void InitFriend(NDUIClientLayer* client);
	void InitMail(NDUIClientLayer* client);
	void InitSyndicate(NDUIClientLayer* client);
	
public:
	static void ProcessSocicalInfoData(NDTransData& data);
	static map_social_data m_mapSocialData;
	static bool GetSocialData(int iID, SocialData& data);
	static bool hasSocialData(int iID);
};

#endif // _SOCIAL_SCENE_H_

