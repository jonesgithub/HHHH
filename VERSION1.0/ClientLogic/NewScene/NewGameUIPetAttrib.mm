/*
 *  NewGameUIPetAttrib.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-8-23.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "NewGameUIPetAttrib.h"
#include <sstream>
#include <string>
#include "NDPlayer.h"
#import "NDPicture.h"
#import "NDManualRole.h"
#import "NDUILabel.h"
#import "NDUIButton.h"
#import "NDDirector.h"
#import "CGPointExtension.h"
#import "NDUIBaseGraphics.h"
#import "NDUITableLayer.h"
#import "NDUIImage.h"
#import "define.h"
#import "NDConstant.h"
#import "ItemMgr.h"
#import "EnumDef.h"
#import "NDMsgDefine.h"
#import "NDDataTransThread.h"
#import "GameScene.h"
#import "NDUtility.h"
#import "PlayerInfoScene.h"
#include "NDMapMgr.h"
#include "GameUIAttrib.h"

//using namespace std;
//using namespace NDEngine;

IMPLEMENT_CLASS(PetAttrInfo, AttrInfo)

void PetAttrInfo::OnClickNDScrollLayer(NDScrollLayer* layer)
{
	if (layer != m_lslText) return;
	
	//if (this->GetParent() && this->GetParent()->IsKindOfClass(RUNTIME_CLASS(NewGameUIPetAttrib))) 
//	{ 
//		NewGameUIPetAttrib *parent = (NewGameUIPetAttrib*)(this->GetParent());
//		parent->ShowAttrInfo(false);
//	}
}
	
void PetAttrInfo::OnButtonClick(NDUIButton* button)
{	
	if (button != m_btnClose) return ;
	
//	if (this->GetParent() && this->GetParent()->IsKindOfClass(RUNTIME_CLASS(NewGameUIPetAttrib))) 
//	{ 
//		NewGameUIPetAttrib *parent = (NewGameUIPetAttrib*)(this->GetParent());
//		parent->ShowAttrInfo(false);
//	}
}

#pragma mark 属性cell

IMPLEMENT_CLASS(NDPetPropCell, NDUINode)

NDPetPropCell::NDPetPropCell()
{
	m_lbKey = m_lbValue = NULL;
	
	m_picBg = m_picFocus = NULL;
	
	m_clrNormalText = ccc4(79, 79, 79, 255);
	m_clrFocusText = ccc4(146, 0, 0, 255);
	
	m_imageStateBar = NULL;
	
	m_uiCur = m_uiMax = 0;
	
	m_fPercent = 0.0f;
	
	m_rectProcess = NULL;
}

NDPetPropCell::~NDPetPropCell()
{
	
}

void NDPetPropCell::Initialization(std::string str, unsigned int uiCur, unsigned int uiMax)
{
	NDUINode::Initialization();
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	//int width = 238, height = 23;
	
	m_picBg = pool.AddPicture(GetImgPathNew("attr_listitem_bg.png"), 0, 23);
	
	CGSize sizeBg = m_picBg->GetSize();
	
	this->SetFrameRect(CGRectMake(0, 0, 238, 23));
	
	m_picFocus = pool.AddPicture(GetImgPathNew("selected_item_bg.png"), 238, 0);
	
	m_lbKey = new NDUILabel;
	m_lbKey->Initialization();
	m_lbKey->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbKey->SetFontSize(14);
	m_lbKey->SetFontColor(m_clrNormalText);
	m_lbKey->SetText(str.c_str());
	this->AddChild(m_lbKey);
	
	m_imageStateBar = new NDUIImage;
	m_imageStateBar->Initialization();
	m_imageStateBar->SetPicture(pool.AddPicture(GetImgPathNew("new_statebar.png"), 90, 0), true);
	m_imageStateBar->SetFrameRect(CGRectMake(238-90-4, 0, 90, 18));
	this->AddChild(m_imageStateBar);
	
	m_rectProcess = new NDUIRecttangle;
	m_rectProcess->Initialization();
	m_rectProcess->SetColor(ccc4(126, 0, 0, 255));
	m_imageStateBar->AddChild(m_rectProcess);
	
	m_lbValue = new NDUILabel;
	m_lbValue->Initialization();
	m_lbValue->SetTextAlignment(LabelTextAlignmentCenter);
	m_lbValue->SetFontSize(14);
	m_lbValue->SetFontColor(ccc4(255, 255, 255, 255));
	m_lbValue->SetFrameRect(CGRectMake(0, 0, 90, 18));
	m_imageStateBar->AddChild(m_lbValue);
	
	SetNum(uiCur, uiMax);
}

void NDPetPropCell::draw()
{
	if (!this->IsVisibled()) return;
	
	CGRect scrRect = this->GetScreenRect();
	
	NDNode *parent = this->GetParent();
	
	NDPicture * pic = NULL;
	
	if (parent && parent->IsKindOfClass(RUNTIME_CLASS(NDUILayer)) && ((NDUILayer*)parent)->GetFocus() == this)
	{
		pic = m_picFocus;
		if (m_lbKey) {
			m_lbKey->SetFontColor(m_clrFocusText);
		}
	}
	else
	{
		pic = m_picBg;
		if (m_lbKey) {
			m_lbKey->SetFontColor(m_clrNormalText);
		}
	}
	
	if (pic)
	{
		CGSize size = pic->GetSize();
		pic->DrawInRect(CGRectMake(scrRect.origin.x+(scrRect.size.width-size.width)/2, 
								   scrRect.origin.y+(scrRect.size.height-size.height)/2, 
								   size.width, size.height));
		
		size.height += (scrRect.size.height-size.height)/2;
		
		if (m_lbKey)
		{
			CGRect rect;
			rect.origin = ccp(2, (size.height-m_lbKey->GetFontSize())/2);
			rect.size = size;
			m_lbKey->SetFrameRect(rect);
		}
		
		if (m_imageStateBar)
		{
			CGRect rect = m_imageStateBar->GetFrameRect();
			rect.origin.y = (size.height-rect.size.height)/2;
			m_imageStateBar->SetFrameRect(rect);
		
			rect.size.width *= m_fPercent < 0.0f ? 0.0f : (m_fPercent > 1.0f ? 1.0f : m_fPercent);
			rect.origin = ccp(0.0f, 0.0f);
			if (m_rectProcess)
				m_rectProcess->SetFrameRect(rect);
		}
	}
	
}

void NDPetPropCell::SetNum(unsigned int uiCur, unsigned int uiMax)
{
	std::stringstream ss;
	
	ss << uiCur << "/" << uiMax;
	
	if (m_lbValue)
		m_lbValue->SetText(ss.str().c_str());
	
	m_uiCur = uiCur;
	
	m_uiMax = uiMax; 
	
	m_fPercent = uiMax == 0 ? 0.0f : ((float)uiCur/uiMax);
}

/////////////////////////////////////////

IMPLEMENT_CLASS(NDNamePropCell, NDPropCell)

void NDNamePropCell::Initialization()
{
	NDPropCell::Initialization(false);
}

/////////////////////////////////////////

//IMPLEMENT_CLASS(NewGamePetNode, NDUILayer)

//int NewGamePetNode::lookface = 0;

/*
NewGamePetNode::NewGamePetNode()
{
	m_faceRightPet = false;
	m_bSelf = true;
	m_Sprite = NULL;
}

NewGamePetNode::~NewGamePetNode()
{
	NDPlayer& player = NDPlayer::defaultHero();
	
	if (!player.battlepet || !player.battlepet->GetParent()) 
	{
		return;
	}
	
	if (!player.isTeamLeader() && player.isTeamMember()) 
	{
		NDManualRole *leader = NDMapMgrObj.GetTeamLeader(player.teamId);
		if (leader) leader->SetTeamToLastPos();
	}
	
	if (!m_bSelf) 
	{
		return;
	}
	
	if (player.battlepet)
	{
		player.battlepet->RemoveFromParent(false);
		player.battlepet->SetPositionEx(m_petPostion);
		player.battlepet->SetCurrentAnimation(MONSTER_MAP_STAND, m_faceRightPet);
		if (m_petParent) 
		{
			m_petParent->AddChild(player.battlepet);
		}
	}
	player.SetAction(false);
}
*/

//void NewGamePetNode::Initialization(bool bSelf/*=true*/)
/*
{
	m_bSelf = bSelf;
	
	NDUILayer::Initialization();
	this->SetBackgroundColor(ccc4(255, 255, 255, 0));
	this->SetTouchEnabled(false);
	
	if (bSelf) 
	{
		if (!NDPlayer::defaultHero().battlepet) 
		{
			NDLog(@"战宠不存在...");
			return;
		}
		
		m_petParent = NDPlayer::defaultHero().battlepet->GetParent();
		if (!m_petParent && bSelf) 
		{
			NDLog(@"战宠对象没有父结点...");
			return;
		}
		
		NDPlayer::defaultHero().stopMoving();
		
		m_faceRightPet	= NDPlayer::defaultHero().battlepet->m_faceRight;
		
		NDPlayer::defaultHero().SetCurrentAnimation(MANUELROLE_STAND, NDPlayer::defaultHero().m_faceRight);
		
		NDPlayer::defaultHero().battlepet->SetCurrentAnimation(MANUELROLE_STAND, m_faceRightPet);
		m_petPostion = NDPlayer::defaultHero().battlepet->GetPosition();
		
		NDPlayer::defaultHero().battlepet->RemoveFromParent(false);
		this->AddChild(NDPlayer::defaultHero().battlepet);
	}
	else 
	{
		//确保lookface存在
		m_Sprite = new NDSprite;
		m_Sprite->SetNormalAniGroup(lookface);
		m_Sprite->SetCurrentAnimation(0,true);
		this->AddChild(m_Sprite);
	}
	
}

void NewGamePetNode::draw()
{
	if (!this->IsVisibled()) return;
	
	if (m_bSelf) 
	{
		if ( NDPlayer::defaultHero().battlepet )
			NDPlayer::defaultHero().battlepet->RunAnimation(true);
	}
	else 
	{
		if (m_Sprite) 
		{
			m_Sprite->RunAnimation(true);
		}
	}
}

void NewGamePetNode::SetDisplayPos(CGPoint pos)
{
	if (m_bSelf) 
	{
		NDBattlePet *pet = NDPlayer::defaultHero().battlepet;
		if ( pet )
		{
			int iH = pet->GetHeight()-32;
			pet->SetPositionEx(ccp(pos.x, pos.y+iH));
		}
	}
	else 
	{
		if (m_Sprite) 
		{
			int iH = m_Sprite->GetHeight()-32;
			m_Sprite->SetPosition(ccp(pos.x, pos.y+iH));
		}
	}
}
*/
/////////////////////////////////////////////////////////

/*
#define prop_key_len (40)
#define prop_min_len (60)
#define prop_value_len (40)

std::vector<int> getPetColorList(int t) 
{
	std::vector<int> res;
	switch (t) {
		case 0:
		{ res.push_back(0x008aff); res.push_back(0x0066ff); } break;
		case 1:
		{ res.push_back(0x4258fd); res.push_back(0x0320f6); } break;
		case 2:
		{ res.push_back(0xfa69fc); res.push_back(0xf93afb); } break;
		case 3:
		{ res.push_back(0xfe4e56); res.push_back(0xff0000); } break;
		case 4:
		{ res.push_back(0xfee749); res.push_back(0xfddc01); } break;
		default:
		{ res.push_back(0x008aff); res.push_back(0x0066ff); }
	}
	
	return res;
}

/////////////////////////////////////////////////////////

#define title_image ([[NSString stringWithFormat:@"%s", GetImgPath("titles.png")] UTF8String])

string strNewPetBasic[NewGameUIPetAttrib::ePAB_End][2] = 
{
	{NDCommonCString("Liliang"), NDCommonCString("LiLiangAttrTip")}, 
	{NDCommonCString("TiZhi"), NDCommonCString("TiZhiAttrTip")}, 
	{NDCommonCString("MingJie"), NDCommonCString("MingJieAttrTip")},
	{NDCommonCString("ZhiLi"), NDCommonCString("ZhiLiAttrTip")},
};

enum ePetAttrDetail 
{
	ePAD_Begin = 0,
	ePAD_Bind = ePAD_Begin,
	ePAD_Quality,
	ePAD_XingGe,
	ePAD_InitLev,
	ePAD_Age,
	ePAD_Honyst,
	ePAD_SkillNum,
	ePAD_InitLiLiang,
	ePAD_InitTizhi,
	ePAD_InitMinJie,
	ePAD_InitZhiLi,
	ePAD_End,
};

string strNewPetDetail[ePAD_End] = 
{
	NDCommonCString("BindState"), NDCommonCString("PingZhi"), NDCommonCString("XingGe"), NDCommonCString("ChuShiLvl"), 
	NDCommonCString("ShouMing"), NDCommonCString("HonestVal"), NDCommonCString("SkillCao"), 
	NDCommonCString("ChuShiLiLiang"), NDCommonCString("ChuShiTiZhi"), NDCommonCString("ChuShiMingJie"), NDCommonCString("ChuShiZhiLi")
};

enum ePetAttrAdvance 
{
	ePAA_Begin = 0,
	ePAA_PhyAtk = ePAA_Begin,
	ePAA_PhyDef,
	ePAA_MagicAtk,
	ePAA_MagicDef,
	ePAA_AtkSpeed,
	ePAA_HardHit,
	ePAA_Dodge,
	ePAA_PetHit,
	ePAA_End,
};

string strNewPetAdvance[ePAA_End] = 
{
	NDCommonCString("PhyAtkVal"), NDCommonCString("PhyDef"), NDCommonCString("MagicAtkVal"), NDCommonCString("FaShuDef"), NDCommonCString("AtkSpeed"),
	NDCommonCString("CriticalHit"), NDCommonCString("DuoShang"), NDCommonCString("hit")
};

/////////////////////////////////////////////////////////////////
IMPLEMENT_CLASS(NewGameUIPetAttrib, NDUILayer)

std::string NewGameUIPetAttrib::str_PET_ATTR_NAME = ""; // 名字STRING
int NewGameUIPetAttrib::int_PET_ATTR_LEVEL = 0; // 等级INT
int NewGameUIPetAttrib::int_PET_ATTR_EXP = 0; // 经验INT
int NewGameUIPetAttrib::int_PET_ATTR_LIFE = 0; // 生命值INT
int NewGameUIPetAttrib::int_PET_ATTR_MAX_LIFE = 0; // 最大生命值INT
int NewGameUIPetAttrib::int_PET_ATTR_MANA = 0; // 魔法值INT
int NewGameUIPetAttrib::int_PET_ATTR_MAX_MANA = 0; // 最大魔法值INT
int NewGameUIPetAttrib::int_PET_ATTR_STR = 0; // 力量INT
int NewGameUIPetAttrib::int_PET_ATTR_STA = 0; // 体质INT
int NewGameUIPetAttrib::int_PET_ATTR_AGI = 0; // 敏捷INT
int NewGameUIPetAttrib::int_PET_ATTR_INI = 0; // 智力INT
int NewGameUIPetAttrib::int_PET_ATTR_LEVEL_INIT = 0; // 初始等级INT
int NewGameUIPetAttrib::int_PET_ATTR_STR_INIT = 0; // 初始力量INT
int NewGameUIPetAttrib::int_PET_ATTR_STA_INIT = 0; // 初始体质INT
int NewGameUIPetAttrib::int_PET_ATTR_AGI_INIT = 0; // 初始敏捷INT
int NewGameUIPetAttrib::int_PET_ATTR_INI_INIT = 0; // 初始智力INT
int NewGameUIPetAttrib::int_PET_ATTR_LOYAL = 0; // 忠诚度INT
int NewGameUIPetAttrib::int_PET_ATTR_AGE = 0; // 寿命INT
int NewGameUIPetAttrib::int_PET_ATTR_FREE_SP = 0; // 剩余技能点数INT
int NewGameUIPetAttrib::int_PET_PHY_ATK_RATE = 0;//物攻资质
int NewGameUIPetAttrib::int_PET_PHY_DEF_RATE = 0;//物防资质
int NewGameUIPetAttrib::int_PET_MAG_ATK_RATE = 0;//法攻资质
int NewGameUIPetAttrib::int_PET_MAG_DEF_RATE = 0;//法防资质
int NewGameUIPetAttrib::int_PET_ATTR_HP_RATE = 0; // 生命资质
int NewGameUIPetAttrib::int_PET_ATTR_MP_RATE = 0; // 魔法资质
int NewGameUIPetAttrib::int_PET_MAX_SKILL_NUM = 0;//最大可学技能数
int NewGameUIPetAttrib::int_PET_SPEED_RATE = 0;//速度资质

int NewGameUIPetAttrib::int_PET_PHY_ATK_RATE_MAX = 0;//物攻资质上限
int NewGameUIPetAttrib::int_PET_PHY_DEF_RATE_MAX = 0;//物防资质上限
int NewGameUIPetAttrib::int_PET_MAG_ATK_RATE_MAX = 0;//法攻资质上限
int NewGameUIPetAttrib::int_PET_MAG_DEF_RATE_MAX = 0;//法防资质上限
int NewGameUIPetAttrib::int_PET_ATTR_HP_RATE_MAX = 0; // 生命资质上限
int NewGameUIPetAttrib::int_PET_ATTR_MP_RATE_MAX = 0; // 魔法资质上限
int NewGameUIPetAttrib::int_PET_SPEED_RATE_MAX = 0;//速度资质上限

int NewGameUIPetAttrib::int_PET_GROW_RATE = 0;// 成长率
int NewGameUIPetAttrib::int_PET_GROW_RATE_MAX = 0;// 成长率
int NewGameUIPetAttrib::int_PET_HIT  = 0;//命中

int NewGameUIPetAttrib::int_ATTR_FREE_POINT = 0; //自由点数
int NewGameUIPetAttrib::int_PET_ATTR_LEVEUP_EXP = 0; // 升级经验
int NewGameUIPetAttrib::int_PET_ATTR_PHY_ATK = 0; // 物理攻击力INT
int NewGameUIPetAttrib::int_PET_ATTR_PHY_DEF = 0; // 物理防御INT
int NewGameUIPetAttrib::int_PET_ATTR_MAG_ATK = 0; // 法术攻击力INT
int NewGameUIPetAttrib::int_PET_ATTR_MAG_DEF = 0; // 法术抗性INT
int NewGameUIPetAttrib::int_PET_ATTR_HARD_HIT = 0;// 暴击
int NewGameUIPetAttrib::int_PET_ATTR_DODGE = 0;// 闪避
int NewGameUIPetAttrib::int_PET_ATTR_ATK_SPEED = 0;// 攻击速度
int NewGameUIPetAttrib::int_PET_ATTR_TYPE = 0;// 类型
int NewGameUIPetAttrib::int_PET_ATTR_LOOKFACE = 0;//外观
int NewGameUIPetAttrib::bindStatus = 0;//绑定状态

int NewGameUIPetAttrib::ownerid = 0;
std::string NewGameUIPetAttrib::ownerName = "";// 主人名

NewGameUIPetAttrib* NewGameUIPetAttrib::s_intance = NULL;

NewGameUIPetAttrib* NewGameUIPetAttrib::GetInstance()
{
	return s_intance;
}

NewGameUIPetAttrib::NewGameUIPetAttrib()
{
	m_picBasic = NULL; m_picBasicDown = NULL; m_btnBasic = NULL;
	m_picDetail = NULL; m_picDetailDown = NULL; m_btnDetail = NULL;
	m_picAdvance = NULL; m_picAdvanceDown = NULL; m_btnAdvance = NULL;
	
	m_framePet  = NULL;
	m_lbName = NULL; m_lbLevel = NULL; m_lbZhuRen = NULL;
	m_lbHP = NULL; m_lbMP = NULL; m_lbExp = NULL;
	m_layerPet = NULL;
	m_stateBarHP = NULL; m_stateBarMP = NULL; m_stateBarExp = NULL;
	
	m_GamePetNode = NULL;
	
	m_lbCurProp = NULL; //m_lbRate = NULL;
	
	m_enumTBS = eTBS_Basic;
	
	m_tableLayerBasic = NULL;
	m_tableLayerDetail = NULL;
	m_tableLayerAdvance = NULL;
	
	m_iFocusTitle = eTBS_Basic;
	
	m_bSelf = true;
	
	m_imageNumTotalPoint = NULL;
	m_imageNUmAllocPoint = NULL;
	m_picMinus = NULL;
	m_imageMinus = NULL;
	
	//memset(m_BasePropNode, 0, sizeof(m_BasePropNode));
	
	for( int ePointState = _stru_point::ps_begin; ePointState < _stru_point::ps_end; ePointState++ )
	{
		m_pointFrame[ePointState] = NULL;
		
		m_btnPointTxt[ePointState] = NULL;
		
		m_btnPointMinus[ePointState] = NULL;
		
		m_btnPointPlus[ePointState] = NULL;
		
		m_btnPointCur[ePointState] = NULL;	
		
		m_picPointMinus[ePointState][0] = NULL;
		m_picPointMinus[ePointState][1] = NULL;
		
		m_picPointPlus[ePointState][0] = NULL;
		m_picPointPlus[ePointState][1] = NULL;
	}
	
	m_layerPropAlloc = NULL;
	
	m_layerProp = NULL;
	
	m_lbTotal = NULL;
	
	m_lbAlloc = NULL;
	
	m_btnCommit = NULL;
	
	m_attrInfo = NULL;
	
	m_attrInfoShow = false;
	
	s_intance = this;
	
	m_iFocusPointType = _stru_point::ps_end;
} 

NewGameUIPetAttrib::~NewGameUIPetAttrib()
{
	SAFE_DELETE(m_picBasic);
	SAFE_DELETE(m_picBasicDown);
	SAFE_DELETE(m_picDetail);
	SAFE_DELETE(m_picDetailDown);
	SAFE_DELETE(m_picAdvance);
	SAFE_DELETE(m_picAdvanceDown);
	SAFE_DELETE(m_picMinus);
	
	for( int ePointState = _stru_point::ps_begin; ePointState < _stru_point::ps_end; ePointState++ )
	{
		SAFE_DELETE(m_picPointMinus[ePointState][0]);
		SAFE_DELETE(m_picPointMinus[ePointState][1]);
		SAFE_DELETE(m_picPointPlus[ePointState][0]);
		SAFE_DELETE(m_picPointPlus[ePointState][1]);
	}
	
	s_intance = NULL;
}
*/

//void NewGameUIPetAttrib::Initialization(bool bSelf/*=true*/)
/*
{
	m_bSelf = bSelf; 
	
	if (m_bSelf) setBattlePetValueToPetAttr();
	UpdateStrucPoint();
	
	NDUILayer::Initialization();
	
	CGSize winSize = NDDirector::DefaultDirector()->GetWinSize();
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	NDPicture* picBagLeftBg = pool.AddPicture(GetImgPathNew("bag_left_bg.png"));
	
	CGSize sizeBagLeftBg = picBagLeftBg->GetSize();
	
	m_framePet = new NDUILayer;
	m_framePet->Initialization();
	m_framePet->SetFrameRect(CGRectMake(0,12, sizeBagLeftBg.width, sizeBagLeftBg.height));
	m_framePet->SetBackgroundImage(picBagLeftBg, true);
	this->AddChild(m_framePet);
	
	m_lbName = new NDUILabel();
	m_lbName->Initialization();
	m_lbName->SetFontSize(14);
	m_lbName->SetTextAlignment(LabelTextAlignmentCenter);
	m_lbName->SetFontColor(ccc4(187,19,19,255));
	m_lbName->SetFrameRect(CGRectMake(0, 0, sizeBagLeftBg.width, 28));
	m_framePet->AddChild(m_lbName);
	
	
	NDPicture* picRoleBg = pool.AddPicture(GetImgPathNew("attr_role_bg.png"));
	
	CGSize sizeRoleBg = picRoleBg->GetSize();
	
	m_layerPet = new NDUILayer;
	m_layerPet->Initialization();
	m_layerPet->SetFrameRect(CGRectMake(0,26, sizeRoleBg.width, sizeRoleBg.height));
	m_layerPet->SetBackgroundImage(picRoleBg, true);
	m_framePet->AddChild(m_layerPet);
	
	m_lbZhuRen = new NDUILabel();
	m_lbZhuRen->Initialization();
	m_lbZhuRen->SetText(NDCommonCString("ZhuRen"));
	m_lbZhuRen->SetFontSize(13);
	m_lbZhuRen->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbZhuRen->SetFontColor(ccc4(20,29,2,255));
	m_lbZhuRen->SetFrameRect(CGRectMake(4, 5, sizeRoleBg.width, 15));
	m_layerPet->AddChild(m_lbZhuRen);
	
	m_lbLevel = new NDUILabel();
	m_lbLevel->Initialization();
	m_lbLevel->SetText(NDCommonCString("level"));
	m_lbLevel->SetFontSize(13);
	m_lbLevel->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbLevel->SetFontColor(INTCOLORTOCCC4(0x862700));
	m_lbLevel->SetFrameRect(CGRectMake(4, 25, sizeRoleBg.width, 15));
	m_layerPet->AddChild(m_lbLevel);
	
	std::stringstream ssXingGe;
	ssXingGe << "【" << getPetType(int_PET_ATTR_TYPE) << "】";
	NDUILabel *xingge = new NDUILabel();
	xingge->Initialization();
	xingge->SetText(ssXingGe.str().c_str());
	xingge->SetFontSize(15);
	xingge->SetTextAlignment(LabelTextAlignmentLeft);
	xingge->SetFontColor(INTCOLORTOCCC4(0xff0000));
	xingge->SetFrameRect(CGRectMake(0, 50, 480, 20));
	m_layerPet->AddChild(xingge);
	
	if (!m_bSelf) NewGamePetNode::lookface = int_PET_ATTR_LOOKFACE;
	m_GamePetNode = new NewGamePetNode;
	m_GamePetNode->Initialization(bSelf);
	//以下两行固定用法
	m_GamePetNode->SetFrameRect(CGRectMake(0, 0, winSize.width, winSize.height));
	m_GamePetNode->SetDisplayPos(ccp(120,165));
	m_layerPet->AddChild(m_GamePetNode);
	
	m_lbHP = new NDUILabel();
	m_lbHP->Initialization();
	m_lbHP->SetText("HP");
	m_lbHP->SetFontSize(13);
	m_lbHP->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbHP->SetFontColor(ccc4(187,19,19,255));
	m_lbHP->SetFrameRect(CGRectMake(8, 146, 480, 15));
	m_framePet->AddChild(m_lbHP);
	
	m_lbMP = new NDUILabel();
	m_lbMP->Initialization();
	m_lbMP->SetText("MP");
	m_lbMP->SetFontSize(13);
	m_lbMP->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbMP->SetFontColor(ccc4(187,19,19,255));
	m_lbMP->SetFrameRect(CGRectMake(8, 164, 480, 15));
	m_framePet->AddChild(m_lbMP);
	
	m_lbExp = new NDUILabel();
	m_lbExp->Initialization();
	m_lbExp->SetText("Exp");
	m_lbExp->SetFontSize(13);
	m_lbExp->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbExp->SetFontColor(ccc4(187,19,19,255));
	m_lbExp->SetFrameRect(CGRectMake(8, 183, 480, 15));
	m_framePet->AddChild(m_lbExp);
	
	NDHPStateBar* stateBarHP = new NDHPStateBar();
	stateBarHP->Initialization(ccp(33, 149));
	m_framePet->AddChild(stateBarHP);
	m_stateBarHP = stateBarHP;
	
	NDMPStateBar* stateBarMP = new NDMPStateBar();
	stateBarMP->Initialization(ccp(33, 167));
	m_framePet->AddChild(stateBarMP);
	m_stateBarMP = stateBarMP;
	
	NDExpStateBar* stateBarExp = new NDExpStateBar();
	stateBarExp->Initialization(ccp(33, 187));
	m_framePet->AddChild(stateBarExp);
	m_stateBarExp = stateBarExp;
	
	
/*	
	m_lbCurProp = new NDUILabel();
	m_lbCurProp->Initialization();
	m_lbCurProp->SetText("可分配属性:");
	m_lbCurProp->SetFontSize(15);
	m_lbCurProp->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbCurProp->SetFontColor(ccc4(0,0,0,255));
	m_lbCurProp->SetFrameRect(CGRectMake(220, 44, 480, 15));
	this->AddChild(m_lbCurProp);
	
	m_imageNumTotalPoint = new ImageNumber;
	m_imageNumTotalPoint->Initialization();
	m_imageNumTotalPoint->SetTitleRedNumber(0);
	m_imageNumTotalPoint->SetFrameRect(CGRectMake(320, 44, 60, 8));
	this->AddChild(m_imageNumTotalPoint);
	
	m_imageNUmAllocPoint = new ImageNumber;
	m_imageNUmAllocPoint->Initialization();
	m_imageNUmAllocPoint->SetTitleRedNumber(0);
	m_imageNUmAllocPoint->SetFrameRect(CGRectMake(390, 44, 60, 8));
	this->AddChild(m_imageNUmAllocPoint);
	
	m_picMinus = NDPicturePool::DefaultPool()->AddPicture(GetImgPath("plusMinus.png"));
	m_picMinus->Cut(CGRectMake(8, 0, 9, 8));
	
	m_imageMinus = new NDUIImage;
	m_imageMinus->Initialization();
	m_imageMinus->SetPicture(m_picMinus);
	m_imageMinus->SetFrameRect(CGRectMake(380, 48, 8, 8));
	this->AddChild(m_imageMinus);
	
	do 
	{
		m_tableLayerBasic = new NDUITableLayer;
		m_tableLayerBasic->Initialization();
		m_tableLayerBasic->SetDelegate(this);
		m_tableLayerBasic->VisibleSectionTitles(false);
		m_tableLayerBasic->VisibleScrollBar(true);
		m_tableLayerBasic->SetFrameRect(CGRectMake(220, 60, 230, 193));
		NDDataSource *dataSource = new NDDataSource;
		NDSection *section = new NDSection;
		for ( int i=ePAB_Begin; i<ePAB_End; i++) 
		{
			m_BasePropNode[i] = new BasePropNode;			
			m_BasePropNode[i]->Initialization();
			m_BasePropNode[i]->SetKeyText(strPetBasic[i].c_str());
			m_BasePropNode[i]->SetValue("500");
			m_BasePropNode[i]->SetFrameRect(CGRectMake(0, 0, 229, 30));
			section->AddCell(m_BasePropNode[i]);
		}
		
		std::vector<int> colors = getColorList(int_PET_ATTR_TYPE % 10-5);
#define fastinit(prop,str, min, max) \
do \
{ \
prop = new LayerProp; \
prop->Initialization(); \
prop->SetKeyText(str); \
prop->SetStateNum(min,max); \
prop->SetFrameRect(CGRectMake(0, 0, 229, 30)); \
prop->SetColor(colors);\
section->AddCell(prop); \
} while (0)
		
		fastinit(m_BaseLayerProp[ePABE_Begin], "成长资质", int_PET_GROW_RATE, int_PET_GROW_RATE_MAX);
		fastinit(m_BaseLayerProp[ePABE_Begin+1], "气血资质", int_PET_ATTR_HP_RATE, int_PET_ATTR_HP_RATE_MAX);
		fastinit(m_BaseLayerProp[ePABE_Begin+2], "法力资质", int_PET_ATTR_MP_RATE, int_PET_ATTR_MP_RATE_MAX);
		fastinit(m_BaseLayerProp[ePABE_Begin+3], "物攻资质", int_PET_PHY_ATK_RATE, int_PET_PHY_ATK_RATE_MAX);
		fastinit(m_BaseLayerProp[ePABE_Begin+4], "物防资质", int_PET_PHY_DEF_RATE, int_PET_PHY_DEF_RATE_MAX);
		fastinit(m_BaseLayerProp[ePABE_Begin+5], "法攻资质", int_PET_MAG_ATK_RATE, int_PET_MAG_ATK_RATE_MAX);
		fastinit(m_BaseLayerProp[ePABE_Begin+6], "法防资质", int_PET_MAG_DEF_RATE, int_PET_MAG_DEF_RATE_MAX);
		fastinit(m_BaseLayerProp[ePABE_Begin+7], "速度资质", int_PET_SPEED_RATE, int_PET_SPEED_RATE_MAX);
#undef	fastinit	
		dataSource->AddSection(section);
		m_tableLayerBasic->SetDataSource(dataSource);
		this->AddChild(m_tableLayerBasic);
	} while (0);
	
	do 
	{
		m_tableLayerDetail = new NDUITableLayer;
		m_tableLayerDetail->Initialization();
		m_tableLayerDetail->VisibleSectionTitles(false);
		m_tableLayerDetail->SetFrameRect(CGRectMake(220, 60, 230, 193));
		m_tableLayerDetail->VisibleScrollBar(true);
		m_tableLayerDetail->SetDelegate(this);
		NDDataSource *dataSource = new NDDataSource;
		NDSection *section = new NDSection;
		for ( int i=ePAD_Begin; i<ePAD_End; i++) 
		{
			NDUIProp  *propDetail = new NDUIProp;
			propDetail->Initialization();
			propDetail->SetFrameRect(CGRectMake(0, 0, 229, 20));
			propDetail->SetKeyText(strPetDetail[i].c_str());
			propDetail->SetValueText("");
			section->AddCell(propDetail);
		}
		
		dataSource->AddSection(section);
		m_tableLayerDetail->SetDataSource(dataSource);
		this->AddChild(m_tableLayerDetail);
	} while (0);
	
	do 
	{
		m_tableLayerAdvance = new NDUITableLayer;
		m_tableLayerAdvance->Initialization();
		m_tableLayerAdvance->VisibleSectionTitles(false);
		m_tableLayerAdvance->VisibleScrollBar(true);
		m_tableLayerAdvance->SetFrameRect(CGRectMake(220, 60, 230, 193));
		NDDataSource *dataSource = new NDDataSource;
		NDSection *section = new NDSection;
		
		for(int i=ePAA_Begin; i<ePAA_End; i++)
		{
			NDUIProp  *propDetail = new NDUIProp;
			propDetail->Initialization();
			propDetail->SetFrameRect(CGRectMake(0, 0, 229, 20));
			propDetail->SetKeyText(strPetAdvance[i].c_str());
			propDetail->SetValueText("");
			section->AddCell(propDetail);
		}
		
		dataSource->AddSection(section);
		m_tableLayerAdvance->SetDataSource(dataSource);
		this->AddChild(m_tableLayerAdvance);
	} while (0);
	
	updatePoint();
	*/
	/*
	InitPropAlloc();
	InitProp();
	
	m_attrInfo = new PetAttrInfo;
	m_attrInfo->Initialization();
	m_attrInfo->SetFrameRect(CGRectMake(0,12, sizeBagLeftBg.width, sizeBagLeftBg.height));
	this->AddChild(m_attrInfo);
	
	UpdateGameUIPetAttrib();
}

void NewGameUIPetAttrib::draw()
{	
	if (m_enumTBS == eTBS_Detail) 
	{
		ShowDetail();
	}
	else if (m_enumTBS == eTBS_Advance)
	{
		ShowAdvance();
	}
	else 
	{
		ShowBasic();
	}
}

void NewGameUIPetAttrib::OnButtonClick(NDUIButton* button)
{
	/*
	if ( button == m_btnBasic ) 
	{
		changeTitleFocus(eTBS_Basic);
		m_enumTBS = eTBS_Basic;
	}
	else if ( button == m_btnDetail )
	{
		changeTitleFocus(eTBS_Detail);
		m_enumTBS = eTBS_Detail;
	}
	else if ( button == m_btnAdvance )
	{
		changeTitleFocus(eTBS_Advance);
		m_enumTBS = eTBS_Advance;
	}
	else if ( button == this->GetOkBtn() )
	{
		if (m_struPoint.iAlloc > 0 
			&& m_struPoint.iAlloc <= m_struPoint.iTotal
			&& m_struPoint.VerifyAllocPoint() ) 
		{
			NDUIDialog* dlg = new NDUIDialog;
			dlg->Initialization();
			dlg->SetDelegate(this);
			stringstream ss;
			ss << "是否确认属性点分配,此次修改后可分配属性点剩余" << (m_struPoint.iTotal-m_struPoint.iAlloc);
			dlg->Show("提示", ss.str().c_str(), NULL, "确定", "取消", NULL);
		}
		else 
		{
			NDDirector::DefaultDirector()->PopScene();
		}
	}
	else if ( button == this->GetCancelBtn() )
	{
		NDDirector::DefaultDirector()->PopScene();
	}*/
	/*
	if ( button == m_btnCommit)
	{
		if (m_struPoint.iAlloc > 0 && m_struPoint.VerifyAllocPoint() ) 
		{
			NDUIDialog* dlg = new NDUIDialog;
			dlg->Initialization();
			dlg->SetDelegate(this);
			std::stringstream str;
			str << NDCommonCString("ModifyAttrTip") << m_struPoint.iTotal - m_struPoint.iAlloc;
			dlg->Show(NDCommonCString("tip"), str.str().c_str(), NDCommonCString("Cancel"), NDCommonCString("Ok"),NULL);
		}
	}
	
	for( int ePointState = _stru_point::ps_begin; ePointState < _stru_point::ps_end; ePointState++ )
	{
		if (button->GetParent() && button->GetParent() == m_pointFrame[ePointState]) 
		{
			if (m_pointFrame[ePointState] && !m_pointFrame[ePointState]->IsFocus())
			{
				changePointFocus(ePointState);
				UpdateSlideBar(ePointState);
				return;
			}
			break;
		}
	}
	
	for( int ePointState = _stru_point::ps_begin; ePointState < _stru_point::ps_end; ePointState++ )
	{
		if (m_btnPointMinus[ePointState] == button) 
		{
			if (m_struPoint.iAlloc > 0 && m_struPoint.m_psProperty[ePointState].iPoint >0) 
			{
				m_struPoint.iAlloc -= 1; m_struPoint.m_psProperty[ePointState].iPoint -= 1;
				
				UpdatePorpText(ePointState);
				
				UpdateSlideBar(ePointState);
				
				UpdatePorpAlloc();
			}
		}
	}
	
	for( int ePointState = _stru_point::ps_begin; ePointState < _stru_point::ps_end; ePointState++ )
	{
		if (m_btnPointPlus[ePointState] == button) 
		{
			if (m_struPoint.iTotal >= 1 && m_struPoint.iTotal >= m_struPoint.iAlloc+1) 
			{
				m_struPoint.m_psProperty[ePointState].iPoint += 1;
				m_struPoint.iAlloc += 1;
				
				UpdatePorpText(ePointState);
				
				UpdateSlideBar(ePointState);
				
				UpdatePorpAlloc();
			}
		}
	}
	
	for( int ePointState = _stru_point::ps_begin; ePointState < _stru_point::ps_end; ePointState++ )
	{
		if (m_btnPointTxt[ePointState] == button
			|| m_btnPointCur[ePointState] == button) 
		{
			showDialog(strNewPetBasic[ePointState][0].c_str(), strNewPetBasic[ePointState][1].c_str());
			return;
		}
	}
}

void NewGameUIPetAttrib::OnDialogButtonClick(NDUIDialog* dialog, unsigned int buttonIndex)
{
	dialog->Close();
	if (buttonIndex == 0) {
		this->sendAction();
	}
}

void NewGameUIPetAttrib::sendAction() {
	if ( !(m_struPoint.iAlloc > 0 
		   && m_struPoint.iAlloc <= m_struPoint.iTotal
		   && m_struPoint.VerifyAllocPoint()) 
		)
	{
		return;
	}
	
	Item *itempet = ItemMgrObj.GetEquipItemByPos(Item::eEP_Pet);
	NDBattlePet *pet = NDPlayer::defaultHero().battlepet;
	if (!itempet || !pet) 
	{
		return;
	}
	
	//int STR_POINT = 0x01;
	//	int STA_POINT = 0x02;
	//	int AGI_POINT = 0x04;
	//	int INI_POINT = 0x08;
	//int POINT_DEF[_stru_point::ps_end] = { 0x01, 0x04, 0x08, 0x02,};
	int POINT_DEF[_stru_point::ps_end] = { 0x01, 0x02, 0x04, 0x08,};
	NDTransData bao(_MSG_CHG_PET_POINT);
	bao << int(itempet->iID);
	int btPointField = 0;
	for (int i = _stru_point::ps_begin; i < _stru_point::ps_end; i++) 
	{
		if (m_struPoint.m_psProperty[i].iPoint > 0) 
		{
			btPointField |= POINT_DEF[i];
		}
	}
	bao << (unsigned char)btPointField;
	for (int i = _stru_point::ps_begin; i < _stru_point::ps_end; i++) 
	{
		if (m_struPoint.m_psProperty[i].iPoint > 0) 
		{
			bao << (unsigned short)(m_struPoint.m_psProperty[i].iPoint);
		}
	}
	SEND_DATA(bao);
	
	pet->tmpRestPoint = m_struPoint.iTotal - m_struPoint.iAlloc;
	pet->tmpStrPoint = m_struPoint.GetPoint(_stru_point::ps_liliang);
	pet->tmpStaPoint = m_struPoint.GetPoint(_stru_point::ps_tizhi);
	pet->tmpAgiPoint = m_struPoint.GetPoint(_stru_point::ps_minjie);
	pet->tmpIniPoint = m_struPoint.GetPoint(_stru_point::ps_zhili);
	int_ATTR_FREE_POINT = pet->tmpRestPoint;
	int_PET_ATTR_STR = pet->tmpStrPoint;
	int_PET_ATTR_STA = pet->tmpStaPoint;
	int_PET_ATTR_AGI = pet->tmpAgiPoint;
	int_PET_ATTR_INI = pet->tmpIniPoint;
	
	UpdateStrucPoint();
	updatePoint();
}

bool NewGameUIPetAttrib::OnCustomViewConfirm(NDUICustomView* customView)
{
	std::string strName = customView->GetEditText(0);
	if (!strName.empty() && UpdateDetailPetName(strName))
	{
		Item* item = ItemMgrObj.GetEquipItemByPos(Item::eEP_Pet);
		if (!item) 
		{
			NDLog(@"宠物属性界面更改宠物名字时找不到宠物所在装备");
			return true;
		}
		
		NDTransData data(_MSG_NAME);
		data << item->iID << (unsigned char)0;
		data.WriteUnicodeString(strName);
		
		NDDataTransThread::DefaultThread()->GetSocket()->Send(&data);
		
		m_lbName->SetText(strName.c_str());
	}
	return true;
}

void NewGameUIPetAttrib::OnTableLayerCellSelected(NDUITableLayer* table, NDUINode* cell, unsigned int cellIndex, NDSection* section)
{
	if (!m_bSelf) 
	{
		return;
	}
	
	if (table != m_tableLayerDetail) return;
	
	if (cellIndex == 0)
	{
		if (!cell->IsKindOfClass(RUNTIME_CLASS(NDNamePropCell))) return;
		
		stringstream ss;
		ss << NDCommonCString("InputNewPetName");
		NDUICustomView *view = new NDUICustomView;
		view->Initialization();
		view->SetDelegate(this);
		std::vector<int> vec_id; vec_id.push_back(101);
		std::vector<std::string> vec_str; vec_str.push_back(ss.str());
		view->SetEdit(1, vec_id, vec_str);
		view->Show();
		this->AddChild(view);
		return;
	}
	
	if (cell->IsKindOfClass(RUNTIME_CLASS(NDPetPropCell)))
	{
		return;
	}
	
	if (!cell->IsKindOfClass(RUNTIME_CLASS(NDPropCell))) return; 
	
	NDPropCell *prop = (NDPropCell*)cell;
	
	if (cell->GetTag() >= 200)
	{
		int eProp = cell->GetTag() - 200;
		if (eProp < ePAA_Begin || eProp >= ePAA_End) return;
		
		// eProp ->高级属性
	}
	else if (cell->GetTag() >= 100)
	{
		int eProp = cell->GetTag() - 100;
		if (eProp < ePAD_Begin || eProp >= ePAD_End) return;
		
		// eProp ->详细属性
	}
	NDUILabel *lb = prop->GetKeyText();
	
	if (lb && m_attrInfo && m_attrInfo->GetDescLabel())
	{
		m_attrInfo->GetDescLabel()->SetText(lb->GetText().c_str());
		/*
		m_attrInfo->SetContentText(
								   "1.力量 提升物理攻击力同时增加HP值" 
								   "2.体质 提升物理防御同时增加大幅增加HP值" 
								   "3.敏捷 提升攻击速度和少量提升物理攻击及闪避能力"
								   "智力 提升法术攻击力和魔法防御力同时大幅增加MP值"
								   "力量 提升物理攻击力同时增加HP值" 
								   "体质 提升物理防御同时增加大幅增加HP值" 
								   "4.敏捷 提升攻击速度和少量提升物理攻击及闪避能力"
								   "5.智力 提升法术攻击力和魔法防御力同时大幅增加MP值"
								   "6.力量 提升物理攻击力同时增加HP值" 
								   "7.体质 提升物理防御同时增加大幅增加HP值" 
								   "8.敏捷 提升攻击速度和少量提升物理攻击及闪避能力"
								   "9.智力 提升法术攻击力和魔法防御力同时大幅增加MP值"
								   "10.力量 提升物理攻击力同时增加HP值" 
								   "11.体质 提升物理防御同时增加大幅增加HP值" 
								   "12.敏捷 提升攻击速度和少量提升物理攻击及闪避能力"
								   "13.智力 提升法术攻击力和魔法防御力同时大幅增加MP值2");*/
		/*
		ShowAttrInfo(true);
	}
}

void NewGameUIPetAttrib::updatePoint()
{
/*
	for (int i = ePAB_Begin; i < ePAB_End; i++) 
	{
		ccColor4B color = ccc4(0, 0, 0, 255);
		int iValue = 0;
		_stru_point::point_state& pointstate = m_struPoint.m_psProperty[i];
		if (pointstate.iPoint != 0) 
		{
			iValue += pointstate.iPoint;
			color = ccc4(255, 0, 0, 255);
		}
		iValue += pointstate.iFix;
		std::stringstream ss; ss << iValue;
		if (m_BasePropNode[i]) 
		{
			m_BasePropNode[i]->SetValue(ss.str());
			m_BasePropNode[i]->SetValueColor(color);
		}
	}
	
	if (m_imageNumTotalPoint) 
	{
		m_imageNumTotalPoint->SetTitleRedNumber(m_struPoint.iTotal);
	}
	
	if (m_imageNUmAllocPoint) 
	{
		m_imageNUmAllocPoint->SetTitleRedNumber(m_struPoint.iAlloc);
	}
	
	if (m_struPoint.iAlloc > 0 && m_imageMinus)
	{
		m_imageMinus->SetVisible(true);
	}
	*//*
}

void NewGameUIPetAttrib::UpdateGameUIPetAttrib()
{
	if (m_bSelf) setBattlePetValueToPetAttr();
	
	m_lbName->SetText(str_PET_ATTR_NAME.c_str());
	stringstream ssName; ssName << NDCommonCString("ZhuRen") << ":" << ownerName.c_str();
	m_lbZhuRen->SetText(ssName.str().c_str());
	
	stringstream ssLvl; ssLvl << int_PET_ATTR_LEVEL << NDCommonCString("Ji");
	m_lbLevel->SetText(ssLvl.str().c_str());
	
	m_stateBarHP->SetNumber(int_PET_ATTR_LIFE, int_PET_ATTR_MAX_LIFE);
	m_stateBarMP->SetNumber(int_PET_ATTR_MANA, int_PET_ATTR_MAX_MANA);
	m_stateBarExp->SetNumber(int_PET_ATTR_EXP, int_PET_ATTR_LEVEUP_EXP);
	
	if (!this->IsVisibled())
	{
		m_stateBarHP->SetVisible(false);
		m_stateBarExp->SetVisible(false);
		m_stateBarHP->SetVisible(false);
	}
	
	UpdateStrucPoint();
	
	for (int i =_stru_point::ps_begin; i<_stru_point::ps_end; i++) 
	{
		UpdatePorpText(i);
		SetPropTextFocus(i, i == m_iFocusPointType);
	}
	
	if (m_lbTotal)
	{
		std::stringstream ss; ss << m_struPoint.iTotal;
		m_lbTotal->SetText(ss.str().c_str());
	}
	
	if (m_lbAlloc)
	{
		std::stringstream ss; ss << m_struPoint.iAlloc;
		m_lbAlloc->SetText(ss.str().c_str());
	}
	
	UpdateSlideBar(m_iFocusPointType);
	
	//updatePoint();
	
	UpdateBasicData(ePABE_GrowRate, int_PET_GROW_RATE, int_PET_GROW_RATE_MAX);
	UpdateBasicData(ePABE_HpRate, int_PET_ATTR_HP_RATE, int_PET_ATTR_HP_RATE_MAX);
	UpdateBasicData(ePABE_MpRate, int_PET_ATTR_MP_RATE, int_PET_ATTR_MP_RATE_MAX);
	UpdateBasicData(ePABE_PhyAtkRate, int_PET_PHY_ATK_RATE, int_PET_PHY_ATK_RATE_MAX);
	UpdateBasicData(ePABE_PhyDefRate, int_PET_PHY_DEF_RATE, int_PET_PHY_DEF_RATE_MAX);
	UpdateBasicData(ePABE_MagAtkRate, int_PET_MAG_ATK_RATE, int_PET_MAG_ATK_RATE_MAX);
	UpdateBasicData(ePABE_MagDefRate, int_PET_MAG_DEF_RATE, int_PET_MAG_DEF_RATE_MAX);
	UpdateBasicData(ePABE_SpeedRate, int_PET_SPEED_RATE, int_PET_SPEED_RATE_MAX);
	
	UpdateDetailPetName(str_PET_ATTR_NAME);
	
	UpdateDetailData(ePAD_Bind, bindStatus);
	UpdateDetailData(ePAD_Quality, int_PET_ATTR_TYPE);
	UpdateDetailData(ePAD_XingGe, int_PET_ATTR_TYPE);
	UpdateDetailData(ePAD_InitLev, int_PET_ATTR_LEVEL_INIT);
	UpdateDetailData(ePAD_Age, int_PET_ATTR_AGE);
	UpdateDetailData(ePAD_Honyst, int_PET_ATTR_LOYAL);
	UpdateDetailData(ePAD_SkillNum, int_PET_MAX_SKILL_NUM);
	UpdateDetailData(ePAD_InitLiLiang, int_PET_ATTR_STR_INIT);
	UpdateDetailData(ePAD_InitTizhi, int_PET_ATTR_STA_INIT);
	UpdateDetailData(ePAD_InitMinJie, int_PET_ATTR_AGI_INIT);
	UpdateDetailData(ePAD_InitZhiLi, int_PET_ATTR_INI_INIT);
	
	UpdateAdvanceData(ePAA_PhyAtk, int_PET_ATTR_PHY_ATK);
	UpdateAdvanceData(ePAA_PhyDef, int_PET_ATTR_PHY_DEF);
	UpdateAdvanceData(ePAA_MagicAtk, int_PET_ATTR_MAG_ATK);
	UpdateAdvanceData(ePAA_MagicDef, int_PET_ATTR_MAG_DEF);
	UpdateAdvanceData(ePAA_AtkSpeed, int_PET_ATTR_ATK_SPEED);
	UpdateAdvanceData(ePAA_HardHit, int_PET_ATTR_HARD_HIT);
	UpdateAdvanceData(ePAA_Dodge, int_PET_ATTR_DODGE);
	UpdateAdvanceData(ePAA_PetHit, int_PET_HIT);
}

void NewGameUIPetAttrib::ShowBasic()
{
/*
	m_lbCurProp->SetVisible(true);
	m_imageNumTotalPoint->SetVisible(true);
	m_imageNUmAllocPoint->SetVisible(true);
	if (m_struPoint.iAlloc > 0 && m_imageMinus)
	{
		m_imageMinus->SetVisible(true);
	}
	m_tableLayerBasic->SetVisible(true);
	m_tableLayerDetail->SetVisible(false);
	m_tableLayerAdvance->SetVisible(false);
	*//*
}
void NewGameUIPetAttrib::ShowDetail()
{	
	/*
	m_lbCurProp->SetVisible(false);
	m_imageNumTotalPoint->SetVisible(false);
	m_imageNUmAllocPoint->SetVisible(false);
	m_imageMinus->SetVisible(false);
	m_tableLayerBasic->SetVisible(false);
	m_tableLayerDetail->SetVisible(true);
	m_tableLayerAdvance->SetVisible(false);
	*//*
}
void NewGameUIPetAttrib::ShowAdvance()
{
	/*
	m_lbCurProp->SetVisible(false);
	m_imageNumTotalPoint->SetVisible(false);
	m_imageNUmAllocPoint->SetVisible(false);
	m_imageMinus->SetVisible(false);
	m_tableLayerBasic->SetVisible(false);
	m_tableLayerDetail->SetVisible(false);
	m_tableLayerAdvance->SetVisible(true);
	*//*
}

void NewGameUIPetAttrib::UpdateBasicData(int eProp, int iMin, int iMax)
{
	if (eProp < ePABE_Begin || eProp >= ePABE_End ) return;
	
	if (!m_tableLayerDetail
	    || !m_tableLayerDetail->GetDataSource()
		|| m_tableLayerDetail->GetDataSource()->Count() == 0
		|| m_tableLayerDetail->GetDataSource()->Section(0)->Count() <= (unsigned int)(eProp+1))
		return ;
		
	NDUINode* cell = m_tableLayerDetail->GetDataSource()->Section(0)->Cell(eProp+1);
	
	if(!cell || !cell->IsKindOfClass(RUNTIME_CLASS(NDPetPropCell))) return;
	
	NDPetPropCell* prop = (NDPetPropCell*)cell;

	prop->SetNum(iMin, iMax);
}

void NewGameUIPetAttrib::UpdateDetailData(int eProp, int value)
{
	if (eProp < ePAD_Begin || eProp >= ePAD_End ) return;
	
	if (!m_tableLayerDetail
	    || !m_tableLayerDetail->GetDataSource()
		|| m_tableLayerDetail->GetDataSource()->Count() == 0
		|| m_tableLayerDetail->GetDataSource()->Section(0)->Count() <= (unsigned int)(eProp+1+ePABE_End))
		return ;
		
	NDUINode *node = m_tableLayerDetail->GetDataSource()->Section(0)->Cell(eProp+1+ePABE_End);								

	if (!node || !node->IsKindOfClass(RUNTIME_CLASS(NDPropCell))) return;
	
	if (node->GetTag() != 100+eProp) return;
	
	NDPropCell* prop = (NDPropCell*)node;

	stringstream ss;  
	if (eProp == ePAD_XingGe) 
	{
		ss << getPetType(value);
	}
	else if (eProp == ePAD_Quality) 
	{
		int tempInt = value % 10;
		if (tempInt >= 5) 
		{
		ss << NDItemType::PETLEVEL(tempInt - 5);
		}
	}
	else if (eProp == ePAD_Bind)
	{
		if (value == BIND_STATE_BIND) 
		{
		ss << NDCommonCString("hadbind");
		} else {
		ss << NDCommonCString("WeiBind");
		}
	}
	else 
	{
		ss << value;
	}

	if (prop->GetValueText())
		prop->GetValueText()->SetText(ss.str().c_str());	
}

void NewGameUIPetAttrib::UpdateAdvanceData(int eProp, int value)
{
	if (eProp < ePAA_Begin || eProp >= ePAA_End ) return;
	
	if (!m_tableLayerDetail
	    || !m_tableLayerDetail->GetDataSource()
		|| m_tableLayerDetail->GetDataSource()->Count() == 0
		|| m_tableLayerDetail->GetDataSource()->Section(0)->Count() <= (unsigned int)(eProp+1+ePABE_End+ePAD_End))
		return ;
	
	NDUINode *node = m_tableLayerDetail->GetDataSource()->Section(0)->Cell(eProp+1+ePABE_End+ePAD_End);								
	
	if (!node || !node->IsKindOfClass(RUNTIME_CLASS(NDPropCell))) return;
	
	if (node->GetTag() != 200+eProp) return;
	
	NDPropCell* prop = (NDPropCell*)node;
	
	stringstream ss; ss << value;
	
	if (prop->GetValueText())
		prop->GetValueText()->SetText(ss.str().c_str());
}

bool NewGameUIPetAttrib::UpdateDetailPetName(std::string str)
{
	if (!m_tableLayerDetail 
		|| !m_tableLayerDetail->GetDataSource() 
		|| m_tableLayerDetail->GetDataSource()->Count() == 0
		|| m_tableLayerDetail->GetDataSource()->Section(0)->Count() == 0) 
	{
		return false;
	}
	
	NDUINode* node = m_tableLayerDetail->GetDataSource()->Section(0)->Cell(0);
	if (node && node->IsKindOfClass(RUNTIME_CLASS(NDNamePropCell))) 
	{
		NDNamePropCell* prop = (NDNamePropCell*)node;
		
		if (prop->GetKeyText())
			prop->GetKeyText()->SetText(str.c_str());
		return true;
	}
	
	return false;
}

void NewGameUIPetAttrib::setBattlePetValueToPetAttr()
{
	/*
	NDBattlePet *battlepet = NDPlayer::defaultHero().battlepet;
	if (!battlepet)
	{
		return;
	}
	
	Item* itemPet = ItemMgrObj.GetEquipItem(Item::eEP_Pet);
	HeroPetInfo::PetData& pet = NDMapMgrObj.petInfo.m_data;
	
	if (itemPet == NULL || itemPet->iID != battlepet->m_id || itemPet->iID != pet.int_PET_ID) 
	{
		NDLog(@"error, 查看玩家装备的宠物id不正确");
		return;
	}
	*/
	
	//NDBattlePet& pet = *(NDPlayer::defaultHero().battlepet);
	/*
	str_PET_ATTR_NAME = NDMapMgrObj.petInfo.str_PET_ATTR_NAME; // 名字STRING
	int_PET_ATTR_LEVEL = pet.int_PET_ATTR_LEVEL; // 等级INT
	int_PET_ATTR_EXP = pet.int_PET_ATTR_EXP; // 经验INT
	int_PET_ATTR_LIFE = pet.int_PET_ATTR_LIFE; // 生命值INT
	int_PET_ATTR_MAX_LIFE = pet.int_PET_ATTR_MAX_LIFE; // 最大生命值INT
	int_PET_ATTR_MANA = pet.int_PET_ATTR_MANA; // 魔法值INT
	int_PET_ATTR_MAX_MANA = pet.int_PET_ATTR_MAX_MANA; // 最大魔法值INT
	int_PET_ATTR_STR = pet.int_PET_ATTR_STR; // 力量INT
	int_PET_ATTR_STA = pet.int_PET_ATTR_STA; // 体质INT
	int_PET_ATTR_AGI = pet.int_PET_ATTR_AGI; // 敏捷INT
	int_PET_ATTR_INI = pet.int_PET_ATTR_INI; // 智力INT
	int_PET_ATTR_LEVEL_INIT = pet.int_PET_ATTR_LEVEL_INIT; // 初始等级INT
	int_PET_ATTR_STR_INIT = pet.int_PET_ATTR_STR_INIT; // 初始力量INT
	int_PET_ATTR_STA_INIT = pet.int_PET_ATTR_STA_INIT; // 初始体质INT
	int_PET_ATTR_AGI_INIT = pet.int_PET_ATTR_AGI_INIT; // 初始敏捷INT
	int_PET_ATTR_INI_INIT = pet.int_PET_ATTR_INI_INIT; // 初始智力INT
	int_PET_ATTR_LOYAL = pet.int_PET_ATTR_LOYAL; // 忠诚度INT
	int_PET_ATTR_AGE = pet.int_PET_ATTR_AGE; // 寿命INT
	int_PET_ATTR_FREE_SP = pet.int_PET_ATTR_FREE_SP; // 剩余技能点数INT
	int_PET_PHY_ATK_RATE = pet.int_PET_PHY_ATK_RATE;// 物攻资质
	int_PET_PHY_DEF_RATE = pet.int_PET_PHY_DEF_RATE;// 物防资质
	int_PET_MAG_ATK_RATE = pet.int_PET_MAG_ATK_RATE;// 法攻资质
	int_PET_MAG_DEF_RATE = pet.int_PET_MAG_DEF_RATE;// 法防资质
	int_PET_ATTR_HP_RATE = pet.int_PET_ATTR_HP_RATE; // 生命资质
	int_PET_ATTR_MP_RATE = pet.int_PET_ATTR_MP_RATE; // 魔法资质
	int_PET_MAX_SKILL_NUM = pet.int_PET_MAX_SKILL_NUM;// 最大可学技能数
	int_PET_SPEED_RATE = pet.int_PET_SPEED_RATE;// 速度资质
	int_ATTR_FREE_POINT = pet.int_ATTR_FREE_POINT; // 自由点数
	int_PET_ATTR_LEVEUP_EXP = pet.int_PET_ATTR_LEVEUP_EXP; // 升级经验
	int_PET_ATTR_PHY_ATK = pet.int_PET_ATTR_PHY_ATK; // 物理攻击力INT
	int_PET_ATTR_PHY_DEF = pet.int_PET_ATTR_PHY_DEF; // 物理防御INT
	int_PET_ATTR_MAG_ATK = pet.int_PET_ATTR_MAG_ATK; // 法术攻击力INT
	int_PET_ATTR_MAG_DEF = pet.int_PET_ATTR_MAG_DEF; // 法术抗性INT
	int_PET_ATTR_HARD_HIT = pet.int_PET_ATTR_HARD_HIT;// 暴击
	int_PET_ATTR_DODGE = pet.int_PET_ATTR_DODGE;// 闪避
	int_PET_ATTR_ATK_SPEED = pet.int_PET_ATTR_ATK_SPEED;// 攻击速度
	ownerName = NDPlayer::defaultHero().m_name;
	
	this->m_struPoint.iTotal = pet.int_ATTR_FREE_POINT;
	this->m_struPoint.m_psProperty[_stru_point::ps_liliang].iFix = pet.int_PET_ATTR_STR;
	this->m_struPoint.m_psProperty[_stru_point::ps_tizhi].iFix = pet.int_PET_ATTR_STA;
	this->m_struPoint.m_psProperty[_stru_point::ps_minjie].iFix = pet.int_PET_ATTR_AGI;
	this->m_struPoint.m_psProperty[_stru_point::ps_zhili].iFix = pet.int_PET_ATTR_INI;
	
	
	int_PET_GROW_RATE_MAX=pet.int_PET_GROW_RATE_MAX;// 成长资质上限
	int_PET_PHY_ATK_RATE_MAX=pet.int_PET_PHY_ATK_RATE_MAX;// 物攻资质上限
	int_PET_PHY_DEF_RATE_MAX=pet.int_PET_PHY_DEF_RATE_MAX;// 物防资质上限
	int_PET_MAG_ATK_RATE_MAX=pet.int_PET_MAG_ATK_RATE_MAX;// 法攻资质上限
	int_PET_MAG_DEF_RATE_MAX=pet.int_PET_MAG_DEF_RATE_MAX;// 法防资质上限
	int_PET_ATTR_HP_RATE_MAX=pet.int_PET_ATTR_HP_RATE_MAX; // 生命资质上限
	int_PET_ATTR_MP_RATE_MAX=pet.int_PET_ATTR_MP_RATE_MAX; // 魔法资质上限
	int_PET_SPEED_RATE_MAX=pet.int_PET_SPEED_RATE_MAX;// 速度资质上限
	int_PET_GROW_RATE=pet.int_PET_GROW_RATE;//成长资质
	bindStatus = pet.bindStatus;*//*
}

std::string NewGameUIPetAttrib::getPetType(int type) {
	std::string s = "";
	switch (type / 10 % 10) {
		case 1:
			s = NDCommonCString("LuMang");
			break;
		case 2:
			s = NDCommonCString("LengJing");
			break;
		case 3:
			s = NDCommonCString("TaoQi");
			break;
		case 4:
			s = NDCommonCString("HangHou");
			break;
		case 5:
			s = NDCommonCString("DangXiao");
			break;
	}
	return s;
}

void NewGameUIPetAttrib::UpdateStrucPoint()
{
	m_struPoint.reset();
	m_struPoint.iTotal = int_ATTR_FREE_POINT;
	m_struPoint.m_psProperty[_stru_point::ps_liliang].iFix = int_PET_ATTR_STR;
	m_struPoint.m_psProperty[_stru_point::ps_tizhi].iFix = int_PET_ATTR_STA;
	m_struPoint.m_psProperty[_stru_point::ps_minjie].iFix = int_PET_ATTR_AGI;
	m_struPoint.m_psProperty[_stru_point::ps_zhili].iFix = int_PET_ATTR_INI;
	m_struPoint.iAlloc = 0;
}

#pragma mark 新加的
void NewGameUIPetAttrib::OnPropSlideBarChange(NDPropSlideBar* bar, int change)
{
	if (bar == m_slideBar)
	{
		m_struPoint.SetAllocPoint(_stru_point::enumPointState(m_iFocusPointType), change);
		
		UpdatePorpText(m_iFocusPointType);
		
		UpdatePorpAlloc();
	}
}

void NewGameUIPetAttrib::SetVisible(bool visible)
{
	NDUILayer::SetVisible(visible);
	
	if (visible && m_attrInfo)
		m_attrInfo->SetVisible(m_attrInfoShow);
}

void NewGameUIPetAttrib::AddPropAlloc(NDUINode* parent)
{
	if (!parent || !m_layerPropAlloc) return;
	
	CGSize size = parent->GetFrameRect().size;
	m_layerPropAlloc->SetFrameRect(CGRectMake(0, 0, size.width, size.height));
	
	parent->AddChild(m_layerPropAlloc);
}
void NewGameUIPetAttrib::AddProp(NDUINode* parent)
{
	if (!parent || !m_layerProp) return;
	
	CGSize size = parent->GetFrameRect().size;
	m_layerProp->SetFrameRect(CGRectMake(0, 0, size.width, size.height));
	
	parent->AddChild(m_layerProp);
}
void NewGameUIPetAttrib::ShowAttrInfo(bool show)
{
	if (m_attrInfo) 
	{
		m_attrInfo->SetVisible(show);
		m_attrInfoShow = show;
	}
}

bool NewGameUIPetAttrib::changePointFocus(int iPointType)
{
	if (iPointType < _stru_point::ps_begin || iPointType >= _stru_point::ps_end )
	{
		return false;
	}
	
	if (m_iFocusPointType == iPointType)
	{
		return false;
	}
	
	if (m_pointFrame[iPointType])
		m_pointFrame[iPointType]->SetLayerFocus(true);
	if (m_pointFrame[m_iFocusPointType])
		m_pointFrame[m_iFocusPointType]->SetLayerFocus(false);
	
	SetPlusOrMinusPicture(iPointType, true, true);
	SetPlusOrMinusPicture(iPointType, false, true);
	
	SetPlusOrMinusPicture(m_iFocusPointType, true, false);
	SetPlusOrMinusPicture(m_iFocusPointType, false, false);
	
	SetPropTextFocus(iPointType, true);
	SetPropTextFocus(m_iFocusPointType, false);
	
	
	m_iFocusPointType = iPointType;
	
	return true;
}

void NewGameUIPetAttrib::InitPropAlloc()
{
	m_layerPropAlloc = new NDUILayer;
	
	m_layerPropAlloc->Initialization();
	
	int width = 252;//, height = 274;
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	/*m_picPropDot = NDPicturePool::DefaultPool()->AddPicture(title_image);
	 m_picPropDot->Cut(CGRectMake(160, 5, 108, 15));
	 
	 m_imagePropDot = new NDUIImage;
	 m_imagePropDot->Initialization();
	 m_imagePropDot->SetPicture(m_picPropDot);
	 m_imagePropDot->SetFrameRect(CGRectMake(219, 62, 108, 15));
	 this->AddChild(m_imagePropDot);*//*
	
	NDUILayer *layer = new NDUILayer;
	layer->Initialization();
	layer->SetFrameRect(CGRectMake(6, 17, width-10, 18));
	layer->SetBackgroundColor(ccc4(127, 98, 56, 255));
	layer->SetTouchEnabled(false);
	m_layerPropAlloc->AddChild(layer);
	
	NDUILabel *text = new NDUILabel;
	text->Initialization();
	text->SetFontSize(14);
	text->SetFontColor(ccc4(255, 237, 46, 255));
	text->SetTextAlignment(LabelTextAlignmentLeft);
	text->SetText(NDCommonCString("CanAllocAttr"));
	text->SetFrameRect(CGRectMake(7, 2,  width-10, 14));
	layer->AddChild(text);
	/*
	 m_imageNumTotalPoint = new ImageNumber;
	 m_imageNumTotalPoint->Initialization();
	 m_imageNumTotalPoint->SetTitleRedNumber(0);
	 m_imageNumTotalPoint->SetFrameRect(CGRectMake(334, 62, 16, 8));
	 this->AddChild(m_imageNumTotalPoint);
	 
	 m_imageNUmAllocPoint = new ImageNumber;
	 m_imageNUmAllocPoint->Initialization();
	 m_imageNUmAllocPoint->SetTitleRedNumber(0);
	 m_imageNUmAllocPoint->SetFrameRect(CGRectMake(374, 62, 16, 8));
	 this->AddChild(m_imageNUmAllocPoint);*//*
	
	m_lbTotal = new NDUILabel;
	m_lbTotal->Initialization();
	m_lbTotal->SetFontSize(14);
	m_lbTotal->SetFontColor(ccc4(255, 237, 46, 255));
	m_lbTotal->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbTotal->SetFrameRect(CGRectMake(120, 2, width-10, 14));
	std::stringstream ss; ss << int_ATTR_FREE_POINT;
	m_lbTotal->SetText(ss.str().c_str());
	layer->AddChild(m_lbTotal);
	
	m_lbAlloc = new NDUILabel;
	m_lbAlloc->Initialization();
	m_lbAlloc->SetFontSize(14);
	m_lbAlloc->SetFontColor(ccc4(255, 237, 46, 255));
	m_lbAlloc->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbAlloc->SetFrameRect(CGRectMake(120+69, 2, width-10, 14));
	m_lbAlloc->SetText("0");
	layer->AddChild(m_lbAlloc);
	
	/*
	 m_picMinus = NDPicturePool::DefaultPool()->AddPicture(plusminus_image);
	 m_picMinus->Cut(CGRectMake(8, 0, 9, 8));
	 
	 m_imageMinus = new NDUIImage;
	 m_imageMinus->Initialization();
	 m_imageMinus->SetPicture(m_picMinus);
	 m_imageMinus->SetFrameRect(CGRectMake(120+80, 5, 8, 8));
	 layer->AddChild(m_imageMinus);*//*
	
	for( int ePointState = _stru_point::ps_begin; ePointState < _stru_point::ps_end; ePointState++ )
	{
		m_picPointMinus[ePointState][0] = pool.AddPicture(GetImgPathNew("minu_normal.png"));
		m_picPointMinus[ePointState][1] = pool.AddPicture(GetImgPathNew("minu_selected.png"));
		m_picPointPlus[ePointState][0] = pool.AddPicture(GetImgPathNew("plus_normal.png"));
		m_picPointPlus[ePointState][1] = pool.AddPicture(GetImgPathNew("plus_selected.png"));
		
		m_pointFrame[ePointState] = new NDPropAllocLayer;
		m_pointFrame[ePointState]->Initialization(CGRectMake(5,52+(5+27)*ePointState,238,27));
		//m_pointFrame[ePointState]->SetLayerFocus(ePointState == m_iFocusPointType);
		
		m_layerPropAlloc->AddChild(m_pointFrame[ePointState]);
	}
	
	
	for( int ePointState = _stru_point::ps_begin; ePointState < _stru_point::ps_end; ePointState++ )
	{
		m_btnPointTxt[ePointState] = new NDUIButton();
		m_btnPointTxt[ePointState]->Initialization();
		m_btnPointTxt[ePointState]->SetFrameRect(CGRectMake(4, 4, 48, 19));
		m_btnPointTxt[ePointState]->SetFontColor(ccc4(255, 255, 255, 255));
		m_btnPointTxt[ePointState]->SetFontSize(13);
		m_btnPointTxt[ePointState]->SetTitle(strNewPetBasic[ePointState][0].c_str());
		m_btnPointTxt[ePointState]->CloseFrame();
		m_btnPointTxt[ePointState]->SetDelegate(this);
		m_pointFrame[ePointState]->AddChild(m_btnPointTxt[ePointState]);
	}
	for( int ePointState = _stru_point::ps_begin; ePointState < _stru_point::ps_end; ePointState++ )
	{
		m_btnPointMinus[ePointState] = new NDUIButton();
		m_btnPointMinus[ePointState]->Initialization();
		CGSize size = m_picPointMinus[ePointState][1]->GetSize();
		m_btnPointMinus[ePointState]->SetFrameRect(CGRectMake(62, 3, size.width, size.height));
		SetPlusOrMinusPicture(ePointState, false, (ePointState==_stru_point::ps_begin));
		m_btnPointMinus[ePointState]->SetDelegate(this);
		m_pointFrame[ePointState]->AddChild(m_btnPointMinus[ePointState]);
	}
	for( int ePointState = _stru_point::ps_begin; ePointState < _stru_point::ps_end; ePointState++ )
	{
		m_btnPointPlus[ePointState] = new NDUIButton();
		m_btnPointPlus[ePointState]->Initialization();
		CGSize size = m_picPointPlus[ePointState][1]->GetSize();
		m_btnPointPlus[ePointState]->SetFrameRect(CGRectMake(170, 3, size.width, size.height));
		SetPlusOrMinusPicture(ePointState, true, (ePointState==_stru_point::ps_begin));
		m_btnPointPlus[ePointState]->SetDelegate(this);
		m_pointFrame[ePointState]->AddChild(m_btnPointPlus[ePointState]);
	}
	for( int ePointState = _stru_point::ps_begin; ePointState < _stru_point::ps_end; ePointState++ )
	{
		std::stringstream strDisplay; 
		strDisplay << m_struPoint.m_psProperty[ePointState].iPoint 
		<< "(+" << m_struPoint.m_psProperty[ePointState].iFix << ")";
		
		m_btnPointCur[ePointState] = new NDUIButton();
		m_btnPointCur[ePointState]->Initialization();
		m_btnPointCur[ePointState]->SetFontColor(ccc4(22, 87, 81, 255));
		m_btnPointCur[ePointState]->SetFontSize(13);
		m_btnPointCur[ePointState]->SetTitle(strDisplay.str().c_str());
		m_btnPointCur[ePointState]->CloseFrame();
		m_btnPointCur[ePointState]->SetFrameRect(CGRectMake(82, 0, 88, 27));
		m_btnPointCur[ePointState]->SetDelegate(this);
		m_pointFrame[ePointState]->AddChild(m_btnPointCur[ePointState]);
	}
	
	m_slideBar = new NDPropSlideBar();
	m_slideBar->Initialization(CGRectMake(6, 182, width-12, 45),205);
	m_slideBar->SetMax(int_ATTR_FREE_POINT);
	m_slideBar->SetDelegate(this);
	m_layerPropAlloc->AddChild(m_slideBar);
	
	NDUILayer *layerBtn = new NDUILayer;
	layerBtn->Initialization();
	layerBtn->SetFrameRect(CGRectMake(195, 234, 48,24));	
	m_layerPropAlloc->AddChild(layerBtn);
	
	m_btnCommit = new NDUIButton;
	m_btnCommit->Initialization();
	m_btnCommit->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("bag_btn_normal.png")),
									  pool.AddPicture(GetImgPathNew("bag_btn_click.png")),
									  false, CGRectZero, true);
	m_btnCommit->SetFrameRect(CGRectMake(0, 0, 48,24));							 
	m_btnCommit->SetFontSize(12);
	m_btnCommit->SetTitle(NDCommonCString("commit"));
	m_btnCommit->SetFontColor(ccc4(255, 255, 255, 255));
	m_btnCommit->CloseFrame();
	m_btnCommit->SetDelegate(this);
	layerBtn->AddChild(m_btnCommit);
	
	changePointFocus(_stru_point::ps_begin);
}

void NewGameUIPetAttrib::InitProp()
{
	m_layerProp = new NDUILayer;

	m_layerProp->Initialization();

	int width = 252;//, height = 274;

	m_tableLayerDetail = new NDUITableLayer;
	m_tableLayerDetail->Initialization();
	m_tableLayerDetail->SetSelectEvent(false);
	m_tableLayerDetail->SetBackgroundColor(ccc4(0, 0, 0, 0));
	m_tableLayerDetail->VisibleSectionTitles(false);
	m_tableLayerDetail->SetFrameRect(CGRectMake(6, 17, width-10, 226));
	m_tableLayerDetail->VisibleScrollBar(false);
	m_tableLayerDetail->SetCellsInterval(2);
	m_tableLayerDetail->SetCellsRightDistance(0);
	m_tableLayerDetail->SetCellsLeftDistance(0);
	m_tableLayerDetail->SetDelegate(this);

	NDDataSource *dataSource = new NDDataSource;
	NDSection *section = new NDSection;
	section->UseCellHeight(true);

	NDNamePropCell *nameCell = new NDNamePropCell;
	nameCell->Initialization();
	if (nameCell->GetKeyText())
	 nameCell->GetKeyText()->SetText(str_PET_ATTR_NAME.c_str());
	if (nameCell->GetValueText())
	 nameCell->GetValueText()->SetText(NDCommonCString("modify"));
	nameCell->SetFocusTextColor(ccc4(255, 0, 0, 255));
	section->AddCell(nameCell);

	#define fastinit(str, min, max) \
	do \
	{ \
	NDPetPropCell* prop = new NDPetPropCell; \
	prop->Initialization(str, min, max); \
	section->AddCell(prop); \
	} while (0)

	fastinit(NDCommonCString("ChengZhangZiZhi"), int_PET_GROW_RATE, int_PET_GROW_RATE_MAX);
	fastinit(NDCommonCString("QiXueZiZhi"), int_PET_ATTR_HP_RATE, int_PET_ATTR_HP_RATE_MAX);
	fastinit(NDCommonCString("FaLiZiZhi"), int_PET_ATTR_MP_RATE, int_PET_ATTR_MP_RATE_MAX);
	fastinit(NDCommonCString("WuGongZiZhi"), int_PET_PHY_ATK_RATE, int_PET_PHY_ATK_RATE_MAX);
	fastinit(NDCommonCString("WuFangZiZhi"), int_PET_PHY_DEF_RATE, int_PET_PHY_DEF_RATE_MAX);
	fastinit(NDCommonCString("FaGongZiZhi"), int_PET_MAG_ATK_RATE, int_PET_MAG_ATK_RATE_MAX);
	fastinit(NDCommonCString("FaFangZiZhi"), int_PET_MAG_DEF_RATE, int_PET_MAG_DEF_RATE_MAX);
	fastinit(NDCommonCString("SpeedZiZhi"), int_PET_SPEED_RATE, int_PET_SPEED_RATE_MAX);

	#undef	fastinit
	 
	 for ( int i=ePAD_Begin; i<ePAD_End; i++) 
	 {
		 NDPropCell  *propDetail = new NDPropCell;
		 propDetail->Initialization(true);
		 if (propDetail->GetKeyText())
			 propDetail->GetKeyText()->SetText(strNewPetDetail[i].c_str());
		 propDetail->SetTag(100+i);
		 section->AddCell(propDetail);
	 }
	 
	 for(int i=ePAA_Begin; i<ePAA_End; i++)
	 {
		 NDPropCell  *propDetail = new NDPropCell;
		 propDetail->Initialization(true);
		 if (propDetail->GetKeyText())
			 propDetail->GetKeyText()->SetText(strNewPetAdvance[i].c_str());
		 propDetail->SetTag(200+i);
		 section->AddCell(propDetail);
	 }

	dataSource->AddSection(section);
	m_tableLayerDetail->SetDataSource(dataSource);
	m_layerProp->AddChild(m_tableLayerDetail);
}

void NewGameUIPetAttrib::SetPlusOrMinusPicture(int eProp, bool plus, bool focus)
{
	if (eProp < _stru_point::ps_begin || eProp >= _stru_point::ps_end) return;
	
	int iFocus = focus ? 1 : 0;
	
	NDUIButton *btn = plus ? m_btnPointPlus[eProp] : m_btnPointMinus[eProp];
	
	NDPicture  *pic = plus ? m_picPointPlus[eProp][iFocus] : m_picPointMinus[eProp][iFocus];
	
	if (!btn || !pic) return;
	
	CGSize size = btn->GetFrameRect().size,
	sizePic = pic->GetSize();
	
	btn->SetImage(pic, true, CGRectMake((size.width-sizePic.width)/2, (size.height-sizePic.height)/2, sizePic.width, sizePic.height));
}

void NewGameUIPetAttrib::SetPropTextFocus(int eProp, bool focus)
{
	if (eProp < _stru_point::ps_begin || eProp >= _stru_point::ps_end) return;
	
	ccColor4B color = focus ? ccc4(255, 0, 0, 255) : 
	(m_struPoint.IsAlloc(_stru_point::enumPointState(eProp)) ? 
	 ccc4(255, 255, 255, 255) : ccc4(22, 87, 81, 255));
	
	if (m_btnPointCur[eProp])
		m_btnPointCur[eProp]->SetFontColor(color);
	
	//if (m_btnPointTotal[eProp])
		//m_btnPointTotal[eProp]->SetFontColor(color);
}

void NewGameUIPetAttrib::UpdatePorpText(int eProp)
{
	if (eProp < _stru_point::ps_begin || eProp >= _stru_point::ps_end) return;
	
	stringstream ss; ss << (m_struPoint.m_psProperty[eProp].iFix + m_struPoint.m_psProperty[eProp].iPoint);
	
	if (m_btnPointCur[eProp])
		m_btnPointCur[eProp]->SetTitle(ss.str().c_str());
	
	//stringstream ss2; ss2 << (m_struPoint.m_psProperty[eProp].iFix 
	//						  + m_struPoint.m_psProperty[eProp].iPoint
	//						  + m_struPoint.m_psProperty[eProp].iAdd);
	
	//if (m_btnPointTotal[eProp])
	//	m_btnPointTotal[eProp]->SetTitle(ss2.str().c_str());
}

void NewGameUIPetAttrib::UpdatePorpAlloc()
{
	stringstream ss;
	ss << m_struPoint.iAlloc;
	
	if (m_lbAlloc)
		m_lbAlloc->SetText(ss.str().c_str());
}

void NewGameUIPetAttrib::UpdateSlideBar(int eProp)
{
	if (eProp < _stru_point::ps_begin || eProp >= _stru_point::ps_end) return;
	
	if (m_slideBar)
	{
		m_slideBar->SetMax(m_struPoint.iTotal, false);
		m_slideBar->SetMin(m_struPoint.GetMinPoint(_stru_point::enumPointState(eProp)),false);
		m_slideBar->SetCur(m_struPoint.iAlloc, true);
	}
}*/