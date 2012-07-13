/*
 *  BattleFieldApply.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-11-7.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "BattleFieldApply.h"
#include "NDUtility.h"
#include "CGPointExtension.h"
#include "BattleFieldMgr.h"
#include "NDDirector.h"
#include "NDUISynLayer.h"
#include "NDPlayer.h"
#include <sstream>

#pragma mark 战场报名列表Cell

IMPLEMENT_CLASS(BFApplyCell, NDUINode)

BFApplyCell::BFApplyCell()
{
	m_lbName = m_lbLvlAttach1 = m_lbLvlAttach2 = NULL;
	
	m_btnLvl = NULL;
	
	m_lbRank = NULL;
	
	m_picBg = m_picFocus = NULL;
}

BFApplyCell::~BFApplyCell()
{
}

void BFApplyCell::Initialization(CGSize size/*=CGSizeMake(238, 23)*/)
{
	NDUINode::Initialization();
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	this->SetFrameRect(CGRectMake(0, 0, size.width, size.height));
	
	m_picBg = pool.AddPicture(GetImgPathNew("attr_listitem_bg.png"), size.width, size.height);
	
	m_picFocus = pool.AddPicture(GetImgPathNew("selected_item_bg.png"), size.width, 0);
	
	m_lbName = new NDUILabel;
	m_lbName->Initialization();
	m_lbName->SetFontColor(ccc4(79, 79, 79, 255));
	m_lbName->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbName->SetFontSize(12);
	this->AddChild(m_lbName);
	
	std::stringstream ssLvl;
	ssLvl << "(" << NDCommonCString("level");
	CGSize sizeStr = getStringSize(ssLvl.str().c_str(), 12);
	m_lbLvlAttach1 = new NDUILabel;
	m_lbLvlAttach1->Initialization();
	m_lbLvlAttach1->SetFontColor(ccc4(0, 0, 0, 255));
	m_lbLvlAttach1->SetText(ssLvl.str().c_str());
	m_lbLvlAttach1->SetFontSize(12);
	m_lbLvlAttach1->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbLvlAttach1->SetFrameRect(CGRectMake(0, 0, sizeStr.width, sizeStr.height));
	this->AddChild(m_lbLvlAttach1);
	
	sizeStr = getStringSize(")", 12);
	m_lbLvlAttach2 = new NDUILabel;
	m_lbLvlAttach2->Initialization();
	m_lbLvlAttach2->SetFontColor(ccc4(0, 0, 0, 255));
	m_lbLvlAttach2->SetText(")");
	m_lbLvlAttach2->SetFontSize(12);
	m_lbLvlAttach2->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbLvlAttach2->SetFrameRect(CGRectMake(0, 0, sizeStr.width, sizeStr.height));
	this->AddChild(m_lbLvlAttach2);
	
	m_lbRank = new NDUILabel;
	m_lbRank->Initialization();
	m_lbRank->SetFontColor(ccc4(255, 0, 0, 255));
	m_lbRank->SetFontSize(12);
	m_lbRank->SetTextAlignment(LabelTextAlignmentRight);
	this->AddChild(m_lbRank);
}

void BFApplyCell::draw()
{
	if (!this->IsVisibled()) return;
	
	CGRect scrRect = this->GetScreenRect();
	
	NDNode *parent = this->GetParent();
	
	NDPicture * pic = NULL;
	
	if (parent && parent->IsKindOfClass(RUNTIME_CLASS(NDUILayer)) && ((NDUILayer*)parent)->GetFocus() == this)
	{
		pic = m_picFocus;
	}
	else 
	{
		pic = m_picBg;
	}
	
	if (!pic) return;
	
	CGSize size = pic->GetSize();
	pic->DrawInRect(CGRectMake(scrRect.origin.x+(scrRect.size.width-size.width)/2, 
							   scrRect.origin.y+(scrRect.size.height-size.height)/2, 
							   size.width, size.height));
	
	size.height += (scrRect.size.height-size.height)/2;
	
	CGSize sizeName = getStringSize(m_lbName->GetText().c_str(), 12);
	CGRect rectName = m_lbName->GetFrameRect();
	
	rectName.origin = ccp(4, (size.height-sizeName.height)/2);
	rectName.size = sizeName;
	m_lbName->SetFrameRect(rectName);
									  
	CGRect rectAttach1 = m_lbLvlAttach1->GetFrameRect();
	rectAttach1.origin = ccp(rectName.origin.x+rectName.size.width+2, (size.height-rectAttach1.size.height)/2);
	m_lbLvlAttach1->SetFrameRect(rectAttach1);
	
	CGRect rectBtn = m_btnLvl->GetFrameRect();
	rectBtn.origin = ccp(rectAttach1.origin.x+rectAttach1.size.width+1, (size.height-rectBtn.size.height)/2);
	m_btnLvl->SetFrameRect(rectBtn);
	
	CGRect rectAttach2 = m_lbLvlAttach2->GetFrameRect();
	rectAttach2.origin = ccp(rectBtn.origin.x+rectBtn.size.width+1, (size.height-rectAttach2.size.height)/2);
	m_lbLvlAttach2->SetFrameRect(rectAttach2);
	
	CGRect rectRank = m_lbRank->GetFrameRect();
	rectRank.origin = ccp(0, (size.height-rectRank.size.height)/2);
	rectRank.size = CGSizeMake(size.width-4, rectRank.size.height);
	m_lbRank->SetFrameRect(rectRank);
}

void BFApplyCell::ChangeApply(BFPlayerInfo& bfApply)
{
	if (!m_btnLvl)
	{
		NDPicture *picLvl = NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("level_bg.png"));
		m_btnLvl = new NDUIButton;
		m_btnLvl->Initialization();
		m_btnLvl->EnableEvent(false);
		m_btnLvl->SetFrameRect(CGRectMake(0, 0, picLvl->GetSize().width, picLvl->GetSize().height));
		m_btnLvl->SetFontSize(10);
		m_btnLvl->SetFontColor(ccc4(254, 225, 107, 255));
		m_btnLvl->SetImage(picLvl, false, CGRectZero, true); 
		this->AddChild(m_btnLvl);
		
		if (!this->IsVisibled())
			m_btnLvl->SetVisible(false);
	}
	
	CGSize sizename = getStringSize(bfApply.name.c_str(), 14);
	m_lbName->SetText(bfApply.name.c_str());
	m_lbName->SetFrameRect(CGRectMake(0, 0, sizename.width, sizename.height));
	
	stringstream ss; ss << bfApply.lvl;
	m_btnLvl->SetTitle(ss.str().c_str());
	
	CGSize sizerank = getStringSize(bfApply.rank.c_str(), 14);
	m_lbRank->SetText(bfApply.rank.c_str());
	m_lbRank->SetFrameRect(CGRectMake(0, 0, sizerank.width, sizerank.height));
}

void BFApplyCell::ResetApply()
{
	m_lbName->SetText("");
	m_lbLvlAttach1->SetText("");
	m_lbLvlAttach2->SetText("");
	m_lbRank->SetText("");
	
	SAFE_DELETE(m_btnLvl);
}

#pragma mark 战场报名信息

IMPLEMENT_CLASS(BattleFieldApplyInfo, NDUILayer)

#define TAG_TIMER_TIMECOUNT (100)						// 倒计时计数
#define TAG_TIMER_REQUESTMSG (TAG_TIMER_TIMECOUNT+1)	// 请求报名信息

#define TAG_BTN_APPLY (100)								// 报名按钮tag
#define TAG_BTN_DEAPPLY (TAG_BTN_APPLY+1)				// 取消报名按钮tag

#define TAG_REQUESTMSG_INTERVAL (5.0f)


BattleFieldApplyInfo::BattleFieldApplyInfo()
{
	m_ruleScroll = NULL;
	
	m_lbTime = m_lbTimeAttach = NULL;
	
	m_btnApply = NULL;
	
	m_tlApplyList = NULL;
	
	m_lbPlayer = NULL;
	
	m_bfType = 0;
	
	m_bApplyState = true;
	
	m_iTimeOutSecond = 0;
	
	m_bfSeq = 0;
	
	m_btnRefresh = NULL;
}

BattleFieldApplyInfo::~BattleFieldApplyInfo()
{
	
}

void BattleFieldApplyInfo::Initialization() override
{
	NDUILayer::Initialization();
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
	
	NDUILayer* layerLeft = new NDUILayer;
	layerLeft->Initialization();
	NDPicture* picBagLeftBg = pool.AddPicture(GetImgPathNew("bag_left_bg.png"));
	CGSize sizeBagLeftBg = picBagLeftBg->GetSize();
	layerLeft->SetBackgroundImage(picBagLeftBg, true);
	layerLeft->SetFrameRect(CGRectMake(0, 12, sizeBagLeftBg.width, sizeBagLeftBg.height));
	this->AddChild(layerLeft);
	
	NDUIImage *imageRes = new NDUIImage;
	imageRes->Initialization();
	imageRes->SetPicture(pool.AddPicture(GetImgPathNew("farmrheadtitle.png")), true);
	imageRes->SetFrameRect(CGRectMake(20, 12, 8, 8));
	layerLeft->AddChild(imageRes);
	
	NDUILabel* lbTitle = new NDUILabel;
	lbTitle->Initialization();
	lbTitle->SetFontSize(16);
	lbTitle->SetFontColor(ccc4(126, 0, 0, 255));
	lbTitle->SetTextAlignment(LabelTextAlignmentLeft);
	lbTitle->SetFrameRect(CGRectMake(35, 7, sizeBagLeftBg.width-4, 38));
	lbTitle->SetText(NDCString("BFRule"));
	layerLeft->AddChild(lbTitle);
	
	CGRect rectScroll = CGRectMake(0, 25, 194, 170);
	m_ruleScroll = new NDUIContainerScrollLayer;
	m_ruleScroll->Initialization();
	m_ruleScroll->SetBackgroundImage(pool.AddPicture(GetImgPathNew("attr_role_bg.png"), 194, 170));
	m_ruleScroll->SetFrameRect(rectScroll);
	m_ruleScroll->VisibleScroll(true);
	layerLeft->AddChild(m_ruleScroll);
	
	int attachStartX = 84, 
		attachStartY = rectScroll.origin.y + rectScroll.size.height+5,
		btnStartY = attachStartY + 20;
	
	m_lbTimeAttach = new NDUILabel;
	m_lbTimeAttach->Initialization();
	m_lbTimeAttach->SetFontSize(14);
	m_lbTimeAttach->SetFontColor(ccc4(0, 0, 0, 255));
	m_lbTimeAttach->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbTimeAttach->SetFrameRect(CGRectMake(attachStartX, attachStartY, sizeBagLeftBg.width-10, 38));
	m_lbTimeAttach->SetText(NDCString("AfterBFStart"));
	layerLeft->AddChild(m_lbTimeAttach);
	
	m_lbTime = new NDUILabel;
	m_lbTime->Initialization();
	m_lbTime->SetFontSize(14);
	m_lbTime->SetFontColor(ccc4(0, 0, 0, 255));
	m_lbTime->SetTextAlignment(LabelTextAlignmentRight);
	m_lbTime->SetFrameRect(CGRectMake(0, attachStartY, attachStartX, 38));
	m_lbTime->SetFontColor(ccc4(255, 0, 0, 255));
	layerLeft->AddChild(m_lbTime);
	
	int btnApplyX = (sizeBagLeftBg.width-10-10-120)/2;
	m_btnApply = new NDUIButton;
	m_btnApply->Initialization();
	m_btnApply->SetFrameRect(CGRectMake(btnApplyX, btnStartY, 60, 24));
	m_btnApply->SetFontSize(12);
	m_btnApply->CloseFrame();
	m_btnApply->SetFontColor(ccc4(255, 255, 255, 255));
	m_btnApply->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("bag_btn_normal.png")),
									  pool.AddPicture(GetImgPathNew("bag_btn_click.png")),
									  false, CGRectZero, true);
	m_btnApply->SetDelegate(this);
	m_btnApply->SetTitle(NDCommonCString("apply"));
	layerLeft->AddChild(m_btnApply);
	
	int startX = 212, endX = 451 , startScrollY = 66-44, endScrollY = 303-37;
	
	NDUILayer *layerApply = new NDUILayer;
	layerApply->Initialization();
	layerApply->SetFrameRect(CGRectMake(startX, startScrollY, endX-startX, 20));
	layerApply->SetBackgroundColor(ccc4(199, 155, 25, 255));
	this->AddChild(layerApply);
	
	lbTitle = new NDUILabel;
	lbTitle->Initialization();
	lbTitle->SetFontSize(14);
	lbTitle->SetFontColor(ccc4(126, 0, 0, 255));
	lbTitle->SetTextAlignment(LabelTextAlignmentLeft);
	lbTitle->SetFrameRect(CGRectMake(30, 3, winsize.width, winsize.height));
	lbTitle->SetText(NDCommonCString("ApplyList"));
	layerApply->AddChild(lbTitle);
	
	CGSize playerCountSize = getStringSize(NDCommonCString("RenShuMaoHao"), 16);
	lbTitle = new NDUILabel;
	lbTitle->Initialization();
	lbTitle->SetFontSize(14);
	lbTitle->SetFontColor(ccc4(126, 0, 0, 255));
	lbTitle->SetTextAlignment(LabelTextAlignmentLeft);
	lbTitle->SetFrameRect(CGRectMake(140, 3, winsize.width, winsize.height));
	lbTitle->SetText(NDCommonCString("RenShuMaoHao"));
	layerApply->AddChild(lbTitle);
	
	m_lbPlayer = new NDUILabel;
	m_lbPlayer->Initialization();
	m_lbPlayer->SetFontSize(14);
	m_lbPlayer->SetFontColor(ccc4(126, 0, 0, 255));
	m_lbPlayer->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbPlayer->SetFrameRect(CGRectMake(lbTitle->GetFrameRect().origin.x+playerCountSize.width, 3, winsize.width, winsize.height));
	layerApply->AddChild(m_lbPlayer);
	
	m_tlApplyList = new NDUITableLayer;
	m_tlApplyList->Initialization();
	m_tlApplyList->SetBackgroundColor(ccc4(0, 0, 0, 0));
	m_tlApplyList->VisibleSectionTitles(false);
	m_tlApplyList->SetFrameRect(CGRectMake(startX, startScrollY+25, endX-startX, endScrollY-startScrollY-25-30));
	//m_tlRecord->VisibleScrollBar(true);
	m_tlApplyList->SetCellsInterval(2);
	m_tlApplyList->SetCellsRightDistance(0);
	m_tlApplyList->SetCellsLeftDistance(0);
	//m_tlRecord->SetBackgroundColor(ccc4(0, 0, 0, 255));
	m_tlApplyList->SetDelegate(this);
	
	NDDataSource *dataSource = new NDDataSource;
	NDSection *section = new NDSection;
	section->UseCellHeight(true);
	
	dataSource->AddSection(section);
	m_tlApplyList->SetDataSource(dataSource);
	this->AddChild(m_tlApplyList);
	
	
	CGRect rectList = m_tlApplyList->GetFrameRect();
	CGRect rectRefresh = CGRectMake(btnApplyX+10+60, 
									btnStartY, 
									60, 24);
	
	m_btnRefresh = new NDUIButton;
	m_btnRefresh->Initialization();
	m_btnRefresh->SetFrameRect(rectRefresh);
	m_btnRefresh->SetFontSize(12);
	m_btnRefresh->CloseFrame();
	m_btnRefresh->SetFontColor(ccc4(255, 255, 255, 255));
	m_btnRefresh->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("bag_btn_normal.png")),
									 pool.AddPicture(GetImgPathNew("bag_btn_click.png")),
									 false, CGRectZero, true);
	m_btnRefresh->SetDelegate(this);
	m_btnRefresh->SetTitle(NDCommonCString("refresh"));
	layerLeft->AddChild(m_btnRefresh);
}

void BattleFieldApplyInfo::OnButtonClick(NDUIButton* button) override
{
	if (button == m_btnRefresh)
	{
		//if (!hasApply()) return;
		BattleFieldMgrObj.SendRequestApplyInfo(m_bfType, false);
		ShowProgressBar;
		return;
	}
	
	if (button != m_btnApply) return;
	
	int tag = button->GetTag();
	
	if (tag == TAG_BTN_APPLY)
	{
		if (!hasApply())
		{
			NDLog(@"====================报名时状态不一致");
			return;
		}
		
		BattleFieldMgrObj.SendSign(m_bfType, m_bfSeq, true);
	}
	else if (tag == TAG_BTN_DEAPPLY)
	{
		if (hasApply())
		{
			NDLog(@"====================取消报名时状态不一致");
			return;
		}
		
		BattleFieldMgrObj.SendSign(m_bfType, m_bfSeq, false);
		
		//m_bfSeq = 0;
	}
}

void BattleFieldApplyInfo::OnTimer(OBJID tag) override
{
	NDUILayer::OnTimer(tag);
	
	if (tag == TAG_TIMER_TIMECOUNT)
	{
		if (m_iTimeOutSecond > 0)
			m_iTimeOutSecond -= 1;
		else
			m_iTimeOutSecond = 0;
			
		RefreshTimeOutLabel();
	}
	else if (tag == TAG_TIMER_REQUESTMSG)
	{
		//if (!hasApply()) return;
		//BattleFieldMgrObj.SendRequestApplyInfo(m_bfType, false);
	}
}

void BattleFieldApplyInfo::SetVisible(bool visible)
{
	NDUILayer::SetVisible(visible);
	
	m_lbTime->SetVisible(visible && m_bfSeq != 0);
	
	m_lbTimeAttach->SetVisible(visible && m_bfSeq != 0);
}

//  重新设置战场规则,倒计时,报名信息,报名状态
void BattleFieldApplyInfo::ChangeApplyInfo(BFApplyInfo& bfApplyInfo)
{
	m_bfType = bfApplyInfo.typeId;
	
	SetBattleFieldRule(bfApplyInfo.rule.c_str());
	
	DealApplyState(bfApplyInfo, true);
	
	/*
	if (IsApply(bfApplyInfo.applyInfo))
	{
		m_bfSeq = 0;
	}
	else
	{
		m_bfSeq =  bfApplyInfo.seqId;
	}
	*/
	
	m_bfSeq =  bfApplyInfo.seqId;
	
	refreshApply(bfApplyInfo);
}

//  更新玩家报名状态,报名信息
void BattleFieldApplyInfo::UpdateApplyInfo(BFApplyInfo& bfApplyInfo)
{
	if (uint(m_bfType) != bfApplyInfo.typeId || uint(m_bfSeq) != bfApplyInfo.seqId) 
		return;
	
	DealApplyState(bfApplyInfo);
	 
	refreshApply(bfApplyInfo);
}

bool BattleFieldApplyInfo::IsEmptyContent()
{
	return m_bfType == 0;
}

// 包括报包括报名信息与报名人数信息
void BattleFieldApplyInfo::refreshApply(BFApplyInfo& bfApplyInfo)
{
	std::stringstream ss;
	
	ss << bfApplyInfo.applyCount << "/" << bfApplyInfo.playerLimit;
	
	m_lbPlayer->SetText(ss.str().c_str());
	
	NDDataSource *ds = m_tlApplyList->GetDataSource();
	
	if (!ds)
	{
		ds = new NDDataSource;
	}
	
	NDSection* sec = NULL;
	if (ds->Count() == 0)
	{
		sec = new NDSection;
		ds->AddSection(sec);
	}
	else
	{
		sec = ds->Section(0);
	}

	map_bf_apply& applyInfo = bfApplyInfo.applyInfo;
	
	std::vector<map_bf_apply_it> vApplyInfo;
	
	for(map_bf_apply_it it = applyInfo.begin(); it != applyInfo.end(); it++)
	{
		vApplyInfo.push_back(it);
	}
	
	size_t maxCount = sec->Count() > vApplyInfo.size() ? sec->Count() : vApplyInfo.size();
	
	unsigned int infoCount = 0;
	
	for (size_t i = 0; i < maxCount; i++) 
	{
		if (i < vApplyInfo.size())
		{
			map_bf_apply_it it = vApplyInfo[i];
			
			BFApplyCell* cell = NULL;
			
			if (infoCount < sec->Count())
				cell = (BFApplyCell *)sec->Cell(infoCount);
			else
			{
				cell = new BFApplyCell;
				cell->Initialization();
				sec->AddCell(cell);
			}
			
			cell->ChangeApply(it->second);
			
			infoCount++;
		}
		else
		{
			if (infoCount < sec->Count() && sec->Count() > 0)
			{
				sec->RemoveCell(sec->Count()-1);
			}
		}
	}
	
	m_tlApplyList->ReflashData();
	
	if (!this->IsVisibled()) 
	{
		m_tlApplyList->SetVisible(false);
	}
}

// 设置战场规则
void BattleFieldApplyInfo::SetBattleFieldRule(const char* text)
{
	if (m_ruleScroll)
	{
		m_ruleScroll->SetContent(text, ccc4(58, 58, 58, 255));
		
		if (!this->IsVisibled())
			m_ruleScroll->SetVisible(false);
	}
}

#pragma mark 倒计时
// 重新设置倒计时 (包括设置标签,重新打开定时器)
void BattleFieldApplyInfo::ResetTimeOut(int sec)
{
	m_iTimeOutSecond = sec;
	
	SetTimeOutTimer();
	
	RefreshTimeOutLabel();
}

// 根据当前保存的秒数设置定时器
void BattleFieldApplyInfo::SetTimeOutTimer()
{
	m_timer.KillTimer(this, TAG_TIMER_TIMECOUNT);
	
	if (m_iTimeOutSecond <= 0) 
	{
		m_iTimeOutSecond = 0;
		
		return;
	}
	
	m_timer.SetTimer(this, TAG_TIMER_TIMECOUNT, 1.0f);
}

// 刷新定时器标签
void BattleFieldApplyInfo::RefreshTimeOutLabel()
{
	std::stringstream ss;
	if (m_iTimeOutSecond <= 0) 
	{
		ss << "00:00";
	}
	else
	{
		int sec = m_iTimeOutSecond % 3600 % 60,
			minu = m_iTimeOutSecond % 3600 / 60,
			hour = m_iTimeOutSecond / 3600;
			
		if (hour > 0)
		{
			if (hour < 10)
				ss << "0";
			ss << hour << ":";
		}
		
		if (minu < 10)
			ss << "0";
		ss << minu << ":";
		
		if (sec < 10)
			ss << "0";
		ss << sec;
	}
	
	if (m_lbTime)
		m_lbTime->SetText(ss.str().c_str());
}

#pragma mark 报名状态
// 处理报名状态 (包括与原状作比较若状态不一样则切换状态,非报名状态重新设置倒计时以及主动请求报名信息定时器)
void BattleFieldApplyInfo::DealApplyState(BFApplyInfo& bfApplyInfo, bool forceSwitch/*=false*/)
{
	bool bSwitchApplyState = IsApply(bfApplyInfo.applyInfo);
	
	if (bSwitchApplyState == m_bApplyState && !forceSwitch) return;
	
	bool resetTimeCount = bfApplyInfo.seqId != m_bfSeq;/*(bSwitchApplyState == false) && (m_bApplyState == true);*/
	
	SwitchToApplyState(bSwitchApplyState);
	
	m_lbTime->SetVisible(this->IsVisibled() && bfApplyInfo.seqId != 0);
	
	m_lbTimeAttach->SetVisible(this->IsVisibled() && bfApplyInfo.seqId != 0);
	
	/*
	if (m_bApplyState)
	{
		ResetTimeOut(0);
	}
	else*/ if (resetTimeCount || (m_iTimeOutSecond == 0 && bfApplyInfo.seqId == m_bfSeq))
	{
		ResetTimeOut(bfApplyInfo.timeLeft);
	}
}

// 切换到指定报名状态(报名或取消报名) 处理包括(状态赋值,标签的显示与隐藏,定时器是否取消以及按钮名字)
void BattleFieldApplyInfo::SwitchToApplyState(bool apply)
{
	m_bApplyState = apply;
	
	if (!m_bApplyState)
	{
		//m_timer.KillTimer(this, TAG_TIMER_REQUESTMSG);
	}
		
	std::string strApply = m_bApplyState == true ? NDCommonCString("apply") : NDCString("CancelApply");
	
	m_btnApply->SetTitle(strApply.c_str());
	
	m_btnApply->SetTag(m_bApplyState ? TAG_BTN_APPLY : TAG_BTN_DEAPPLY);
}

// 根据传入的报名数据返回报名状态
bool BattleFieldApplyInfo::IsApply(map_bf_apply& applyInfo)
{
	NDPlayer& player = NDPlayer::defaultHero();
	
	for (map_bf_apply_it it = applyInfo.begin(); it != applyInfo.end(); it++) {
		if (it->second.name == player.m_name)
			return false;
	}
	
	return true;
}

// 获取保存的报名状态
bool BattleFieldApplyInfo::hasApply()
{
	return m_bApplyState;
}

#pragma mark 战场报名

IMPLEMENT_CLASS(BattleFieldApply, NDCommonLayer)

BattleFieldApply::BattleFieldApply()
{
}

BattleFieldApply::~BattleFieldApply()
{
	BattleField::mapApplyInfo.clear();
}

void BattleFieldApply::Initialization()
{
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	map_bf_desc& mapBfDesc = BattleField::mapApplyDesc;
	
	map_bf_apply_info& mapApplyInfo = BattleField::mapApplyInfo;
	
	
	float maxTitleLen = 0.0f;
	
	for(map_bf_desc_it it = mapBfDesc.begin(); it != mapBfDesc.end(); it++)
	{
		if (mapApplyInfo.find(it->first) == mapApplyInfo.end())
		{
			//NDLog(@"\n=================战场分类[%d]找不到", it->first);
			//continue;
		}
		
		CGSize textSize = getStringSize(it->second.c_str(), 18);
		
		if (textSize.width > maxTitleLen)
			maxTitleLen = textSize.width;
	}
	
	maxTitleLen += 36;
	
	NDCommonLayer::Initialization(maxTitleLen);
	
	int i = 0;
	
	for(map_bf_desc_it it = mapBfDesc.begin(); it != mapBfDesc.end(); it++)
	{
		TabNode* tabnode = this->AddTabNode();
		
		tabnode->SetImage(pool.AddPicture(GetImgPathNew("newui_tab_unsel.png"), maxTitleLen, 31), 
						  pool.AddPicture(GetImgPathNew("newui_tab_sel.png"), maxTitleLen, 34),
						  pool.AddPicture(GetImgPathNew("newui_tab_selarrow.png")));
		
		tabnode->SetText(it->second.c_str());
		
		tabnode->SetTextColor(ccc4(245, 226, 169, 255));
		
		tabnode->SetFocusColor(ccc4(173, 70, 25, 255));
		
		tabnode->SetTextFontSize(18);
		
		tabnode->SetTag(it->first);
		
		NDUIClientLayer *client = this->GetClientLayer(i);
		
		CGSize clientsize = this->GetClientSize();
		
		BattleFieldApplyInfo *info = new BattleFieldApplyInfo;
		info->Initialization();
		info->SetFrameRect(CGRectMake(0, 0, clientsize.width, clientsize.height));
		client->AddChild(info);
		
		map_bf_apply_info_it itApplyInfo = mapApplyInfo.find(it->first);
		if (itApplyInfo != mapApplyInfo.end())
		{
			info->ChangeApplyInfo(itApplyInfo->second);
		}
		
		m_vBfApply.push_back(ApplyInstance(it->first, info));
		
		i++;
	}
	
	this->SetTabFocusOnIndex(0, true);
}

void BattleFieldApply::OnTabLayerSelect(TabLayer* tab, unsigned int lastIndex, unsigned int curIndex) override
{
	NDCommonLayer::OnTabLayerSelect(tab, lastIndex, curIndex);
	
	TabNode* tabNode = tab->GetTabNode(curIndex);
	
	if (!tabNode) return;
	
	if (curIndex >= m_vBfApply.size()) return;
	
	int bfType = tabNode->GetTag();
	
	if (BattleField::mapApplyDesc.find(bfType) == 
	    BattleField::mapApplyDesc.end())
		return;
	
	BattleFieldApplyInfo* info = m_vBfApply[curIndex].info;
	
	if (!info || !info->IsEmptyContent()) return;
		
	BattleFieldMgrObj.SendRequestApplyInfo(bfType, true);
	
	ShowProgressBar;
}

void BattleFieldApply::ChangeBfApply(BFApplyInfo& bfApplyInfo)
{
	BattleFieldApplyInfo* info = GetBfApplyIns(bfApplyInfo.typeId);
	
	if (!info) return;
	
	info->ChangeApplyInfo(bfApplyInfo);
}

void BattleFieldApply::UpdateBfApply(BFApplyInfo& bfApplyInfo)
{
	BattleFieldApplyInfo* info = GetBfApplyIns(bfApplyInfo.typeId);
	
	if (!info) return;
	
	info->UpdateApplyInfo(bfApplyInfo);
}

BattleFieldApplyInfo* BattleFieldApply::GetBfApplyIns(int bfType)
{
	for_vec(m_vBfApply, vec_apply_ins_it)
	{
		if ((*it).bfType == bfType)
			return (*it).info;
	}
	
	return NULL;
}

#pragma mark 战场背景

IMPLEMENT_CLASS(BattleFieldBackStory, NDCommonLayer)

BattleFieldBackStory::BattleFieldBackStory()
{
}

BattleFieldBackStory::~BattleFieldBackStory()
{
}

void BattleFieldBackStory::Initialization()
{
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	map_bf_desc& mapBfDesc = BattleField::mapApplyDesc;
	
	float maxTitleLen = 0.0f;
	
	for(map_bf_desc_it it = mapBfDesc.begin(); it != mapBfDesc.end(); it++)
	{
		CGSize textSize = getStringSize(it->second.c_str(), 18);
		
		if (textSize.width > maxTitleLen)
			maxTitleLen = textSize.width;
	}
	
	maxTitleLen += 36;
	
	NDCommonLayer::Initialization(maxTitleLen);
	
	int i = 0;
	
	for(map_bf_desc_it it = mapBfDesc.begin(); it != mapBfDesc.end(); it++)
	{
		TabNode* tabnode = this->AddTabNode();
		
		tabnode->SetImage(pool.AddPicture(GetImgPathNew("newui_tab_unsel.png"), maxTitleLen, 31), 
						  pool.AddPicture(GetImgPathNew("newui_tab_sel.png"), maxTitleLen, 34),
						  pool.AddPicture(GetImgPathNew("newui_tab_selarrow.png")));
		
		tabnode->SetText(it->second.c_str());
		
		tabnode->SetTextColor(ccc4(245, 226, 169, 255));
		
		tabnode->SetFocusColor(ccc4(173, 70, 25, 255));
		
		tabnode->SetTextFontSize(18);
		
		tabnode->SetTag(it->first);
		
		NDUIClientLayer *client = this->GetClientLayer(i);
		
		CGSize clientsize = this->GetClientSize();
		
		NDUIContainerScrollLayer *scroll = new NDUIContainerScrollLayer;
		scroll->Initialization();
		scroll->SetFrameRect(CGRectMake(19, 20, clientsize.width-60, clientsize.height-40));
		client->AddChild(scroll);
		
		map_bf_desc_it itBackStory = BattleField::mapApplyBackStory.find(it->first);
		if (itBackStory != BattleField::mapApplyBackStory.end())
		{
			scroll->SetContent(itBackStory->second.c_str());
		}
		
		m_vBfBackStory.push_back(BFBackStory(it->first, scroll));
		
		i++;
	}
	
	this->SetTabFocusOnIndex(0, true);
}

void BattleFieldBackStory::OnTabLayerSelect(TabLayer* tab, unsigned int lastIndex, unsigned int curIndex) override
{
	NDCommonLayer::OnTabLayerSelect(tab, lastIndex, curIndex);
	
	TabNode* tabNode = tab->GetTabNode(curIndex);
	
	if (!tabNode) return;
	
	if (curIndex >= m_vBfBackStory.size()) return;
	
	int bfType = tabNode->GetTag();
	
	map_bf_desc_it itBackStory = BattleField::mapApplyBackStory.find(bfType);
	if (itBackStory != BattleField::mapApplyBackStory.end())
	{
		UpdateBfBackStory(bfType, itBackStory->second);
		return;
	}
		
	BattleFieldMgrObj.SendRequestBfBackStory(bfType);
	
	ShowProgressBar;
}

void BattleFieldBackStory::UpdateBfBackStory(int bfType, std::string str)
{
	for_vec(m_vBfBackStory, std::vector<BFBackStory>::iterator)
	{
		if ((*it).bfType == bfType && (*it).scroll)
		{
			(*it).scroll->SetContent(str.c_str(), ccc4(0, 0, 0, 255), 14);
			(*it).scroll->SetVisible(this->IsVisibled());
			break;
		}
	}
}
