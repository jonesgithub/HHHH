/*
 *  SocialScene.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-8-24.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "SocialScene.h"
#include "NDUtility.h"
#include "TutorUILayer.h"
#include "NewFriendList.h"
#include "NewMail.h"
#include "SyndicateUILayer.h"
#include "NDPlayer.h"
#include "SynInfoUILayer.h"
#include "SynDonateUILayer.h"
#include "SynMbrListUILayer.h"
#include "SynVoteUILayer.h"
#include "SynUpgradeUILayer.h"
#include "SynApproveUILayer.h"
#include "SynElectionUILayer.h"
#include "NDUISynLayer.h"

enum 
{
	eSocialBegin = 0,
	eSocialMail = eSocialBegin,
	eSocialFriend,
	eSocialMaster,
	eSocialSyndicate,
	eSocialEnd,
};

IMPLEMENT_CLASS(SocialScene, NDCommonSocialScene)

SocialScene::SocialScene()
{
	m_bSynInit = false;
}

SocialScene::~SocialScene()
{
	m_mapSocialData.clear();
}

SocialScene* SocialScene::Scene()
{
	SocialScene *scene = new SocialScene;
	
	scene->Initialization();
	
	return scene;
}

void SocialScene::Initialization()
{
	NDCommonSocialScene::Initialization();
	
	InitTab(eSocialEnd);
	
	for(int j = eSocialBegin; j < eSocialEnd; j++)
	{
		TabNode* tabnode = GetTabNode(j);
		
		NDPicture *pic = NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("newui_text.png"));
		NDPicture *picFocus = NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("newui_text.png"));
		
		int startX = 18*(11+j);
		
		pic->Cut(CGRectMake(startX, 36, 18, 36));
		picFocus->Cut(CGRectMake(startX, 0, 18, 36));
		
		tabnode->SetTextPicture(pic, picFocus);
	}
	
	SetClientLayerBackground(eSocialMaster);
	InitTutor(GetClientLayer(eSocialMaster));
	
	SetClientLayerBackground(eSocialFriend);
	InitFriend(GetClientLayer(eSocialFriend));
	
	SetClientLayerBackground(eSocialMail);
	InitMail(GetClientLayer(eSocialMail));
}

void SocialScene::OnButtonClick(NDUIButton* button)
{
	if (OnBaseButtonClick(button)) return;
}

void SocialScene::OnTabLayerSelect(TabLayer* tab, unsigned int lastIndex, unsigned int curIndex)
{
	NDCommonSocialScene::OnTabLayerSelect(tab, lastIndex, curIndex);
	
	if (curIndex == 3 && !m_bSynInit) {
		this->InitSyndicate(GetClientLayer(eSocialSyndicate));
	}
}

const char *TAB_TITLES[eSyndicateEnd] = 
{
	NDCommonCString("JunTuanList"),	// eSyndicateList
	NDCommonCString("JunTuan"),		// eSyndicateInfo	// 军团信息（含公告，辞职，退出军团）
	NDCommonCString("donate"),		// eSyndicateDonate,	// 捐献
	NDCommonCString("member"),		// eSyndicateMbrList,	// "军团成员"
	NDCommonCString("vote"),		// eSyndicaetVote,		// "投票箱"
	NDCommonCString("up"),		// eSyndicateUpgrade,	// "军团升级"
	NDCommonCString("shenghe"),		// eSyndicateApprove,	// "人员审核"
	NDCommonCString("jingxuan"),		// eSyndicateElection,	// "职位竞选"
};

void SocialScene::InitSyndicate(NDUIClientLayer* client)
{
	if (!client) return;
	
	m_bSynInit = true;
	
	vector<int> vTabs;
	
	CGSize sizeClient = client->GetFrameRect().size;
	NDHFuncTab *tab = new NDHFuncTab;
	
	NDPlayer& role = NDPlayer::defaultHero();
	int synRank = role.getSynRank();
	switch (synRank) {
		case SYNRANK_NONE:
		{
			// 军团列表(含应征)
			tab->Initialization(1, CGSizeMake(140, 34));
			TabNode* tabnode = tab->GetTabNode(0);
			tabnode->SetText(TAB_TITLES[eSyndicateList]);
			
			SyndicateUILayer* syn = new SyndicateUILayer;
			syn->Initialization();
			
			tab->GetClientLayer(0)->AddChild(syn);
			client->AddChild(tab);
			return;
		}
			break;
		case SYNRANK_LEADER:
		{
			vTabs.push_back(eSyndicateInfo);
			vTabs.push_back(eSyndicateDonate);
			vTabs.push_back(eSyndicateMbrList);
			vTabs.push_back(eSyndicateVote);
			vTabs.push_back(eSyndicateUpgrade);
			vTabs.push_back(eSyndicateApprove);
		}
			break;
		default:
		{
			for (int i = eSyndicateInfo; i < eSyndicateEnd; i++) {
				if (i == eSyndicateUpgrade) {// "军团升级"，副团及以上有权限
					if (synRank < SYNRANK_VICE_LEADER) {
						continue;
					}
				} else if (i == eSyndicateApprove) {//"人员审核"，门主及以上有权限
					if (synRank < SYNRANK_MENZHU_SHENG) {
						continue;
					}
				}
				vTabs.push_back(i);
			}
		}
			break;
	}
	tab->Initialization(vTabs.size(), CGSizeMake(54, 34));
	client->AddChild(tab);
	
	int i = 0;
	for (vector<int>::iterator it = vTabs.begin(); it != vTabs.end(); it++) {
		TabNode* tabnode = tab->GetTabNode(i);
		tabnode->SetText(TAB_TITLES[*it]);
		tabnode->SetTag(*it);
		
		NDUILayer* layer = NULL;
		switch (*it) {
			case eSyndicateInfo:
			{
				layer = new SynInfoUILayer;
			}
				break;
			case eSyndicateDonate:
			{
				layer = new SynDonateUILayer;
			}
				break;
			case eSyndicateMbrList:
			{
				layer = new SynMbrListUILayer;
			}
				break;
			case eSyndicateVote:
			{
				layer = new SynVoteUILayer;
			}
				break;
			case eSyndicateUpgrade:
			{
				layer = new SynUpgradeUILayer;
			}
				break;
			case eSyndicateApprove:
			{
				layer = new SynApproveUILayer;
			}
				break;
			case eSyndicateElection:
			{
				layer = new SynElectionUILayer;
			}
				break;
			default:
				break;
		}
		layer->Initialization();
		tab->GetClientLayer(i)->AddChild(layer);
		i++;
	}
	tab->SetDelegate(this);
	tab->SetTabFocusOnIndex(0);
}

void SocialScene::OnHFuncTabSelect(NDHFuncTab* tab, unsigned int lastIndex, unsigned int curIndex)
{
	int tag = tab->GetTabNode(curIndex)->GetTag();
	switch (tag) {
		case eSyndicateMbrList:
		{
			SynMbrListUILayer* mbrList = SynMbrListUILayer::GetCurInstance();
			if (mbrList) {
				mbrList->Query();
			}
		}
			break;
		case eSyndicateElection:
		{
			SynElectionUILayer* election = SynElectionUILayer::GetCurInstance();
			if (election) {
				election->Query();
			}
		}
			break;
		case eSyndicateVote:
		{	
			SynVoteUILayer* vote = SynVoteUILayer::GetCurInstance();
			if (vote) {
				vote->Query();
			}
		}
			break;
		case eSyndicateApprove:
		{
			SynApproveUILayer* approve = SynApproveUILayer::GetCurInstance();
			if (approve) {
				approve->Query();
			}
			break;
		}
		case eSyndicateUpgrade:
		{
			SynUpgradeUILayer* upgrade = SynUpgradeUILayer::GetCurInstance();
			if (upgrade) {
				upgrade->Query();
			}
			break;
		}
		case eSyndicateDonate:
		{
			SynDonateUILayer* donate = SynDonateUILayer::GetCurInstance();
			if (donate) {
				donate->Query();
			}
			break;
		}
		default:
			break;
	}
}

void SocialScene::InitTutor(NDUIClientLayer* client)
{	
	if (!client) return;
	
	TutorUILayer* tutor = new TutorUILayer;
	
	tutor->Initialization();
	
	tutor->SetFrameRect(CGRectMake(0, 0, 480, 320));
	
	client->AddChild(tutor);
}

void SocialScene::InitFriend(NDUIClientLayer* client)
{
	if (!client) return;
	
	NewGoodFriendUILayer* goodfriend = new NewGoodFriendUILayer;
	
	goodfriend->Initialization();
	
	goodfriend->SetFrameRect(CGRectMake(0, 0, 480, 320));
	
	client->AddChild(goodfriend);
}

void SocialScene::InitMail(NDUIClientLayer* client)
{
	if (!client) return;
	
	NewMailUILayer* mail = new NewMailUILayer;
	
	mail->Initialization();
	
	mail->SetFrameRect(CGRectMake(0, 0, 480, 320));
	
	client->AddChild(mail);
}

void SocialScene::ProcessSocicalInfoData(NDTransData& data)
{
	int amount;
	
	amount = data.ReadShort();
	
	for (int i = 0; i < amount; i++) 
	{
		int iID = data.ReadInt();
		
		SocialData& socialdata = m_mapSocialData[iID];
		
		socialdata.SynName = "";
		socialdata.rank = "";
		socialdata.junxian = "";
		
		socialdata.iId = iID;
		socialdata.lvl = data.ReadByte();
		socialdata.lookface = data.ReadInt();
		
		int sex = socialdata.lookface / 100000000 % 10; // 人物性别，1-男性，2-女性；
		
		if (sex == SpriteSexMale)
		{
			socialdata.sex = NDCommonCString("male");
		}
		else
		{
			socialdata.sex = NDCommonCString("female");
		}
		
		int byEquitAmount = data.ReadShort();
		
		socialdata.equips.clear();
		
		for (int j = 0; j < byEquitAmount; j++) 
		{
			socialdata.equips.push_back(data.ReadInt());
		}
		
		int bsShow = data.ReadByte();
		
		if (bsShow & 0x01)
		{ // 有军团
			socialdata.SynName = data.ReadUnicodeString();
			socialdata.rank = getRankStr(data.ReadByte());
		}
		
		if (bsShow & 0x04)
		{
			socialdata.junxian = data.ReadUnicodeString();
		}
	}
	
	TutorUILayer::processSocialData();
	
	NewGoodFriendUILayer::processSocialData();
	
	CloseProgressBar;
}

bool SocialScene::GetSocialData(int iID, SocialData& data)
{
	if (m_mapSocialData.find(iID) == m_mapSocialData.end()) return false;
	
	data = m_mapSocialData[iID];
	
	return true;
}

bool SocialScene::hasSocialData(int iID)
{
	return m_mapSocialData.find(iID) != m_mapSocialData.end();
}

map_social_data SocialScene::m_mapSocialData;
