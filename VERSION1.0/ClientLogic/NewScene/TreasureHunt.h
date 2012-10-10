/*
 *  TreasureHunt.h
 *  DragonDrive
 *
 *  Created by jhzheng on 11-10-25.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef _TREASURE_HUNT_H_
#define _TREASURE_HUNT_H_

#include "NDCommonScene.h"
#include "GameNewItemBag.h"
#include "NDUILabel.h"
#include "NDScrollLayer.h"
#include "NDItemType.h"
#include "NDUIDialog.h"

#pragma mark 寻宝界面

using namespace NDEngine;

typedef enum
{
	HuntItemTypeBegin,
	HuntItemTypeEffect = HuntItemTypeBegin,				// 效率
	HuntItemTypeRate,									// 成功率
	HuntItemTypeHunt,									// 猎人
	HuntItemTypeEnd,
}HuntItemType;

class TreasureHuntLayer :
public NDUILayer,
public NewGameItemBagDelegate,
public NDUIButtonDelegate
{
	DECLARE_CLASS(TreasureHuntLayer)
	
	TreasureHuntLayer();
	
	~TreasureHuntLayer();
	
	struct HuntItemUI 
	{
		NDUILabel				*lbText;
		NDUIItemButton			*btn;
		NDUILabel				*tip;
		bool					m_bEnable;
		
		HuntItemUI() { memset(this, 0, sizeof(*this)); m_bEnable = true; }
		
		int GetItemID() { if (!btn || !btn->GetItem()) return 0; return btn->GetItem()->iID; }
		
		int GetItemType() { if (!btn || !btn->GetItem()) return 0; return btn->GetItem()->iItemType; }
		
		Item* GetItem() { return btn->GetItem(); }
		
		void SetEnable(bool enable) { m_bEnable = enable; }
		
		bool IsEnable() { return m_bEnable; }
	};
	
public:
	void Initialization(); override
	
	bool OnBagButtonDragIn(NDUIButton* desButton, NDUINode *uiSrcNode, bool longTouch, bool del); override
	
	bool OnButtonDragIn(NDUIButton* desButton, NDUINode *uiSrcNode, bool longTouch); override
	
	bool OnButtonDragOut(NDUIButton* button, CGPoint beginTouch, CGPoint moveTouch, bool longTouch); override
	
	bool OnButtonDragOutComplete(NDUIButton* button, CGPoint endTouch, bool outOfRange); override
	
	void StartTreasureHunt();
	
	// huntLost-寻宝失败率 equipAdd-装备加成 duration-当前可寻宝时间
	void SetRateInfo(int huntLost, int equipAdd, int duration);
	
private:
	void refreshHuntItem(HuntItemType hunt, NDUIButton *btn);
	
	void refreshHuntTip(HuntItemType hunt, NDItemType* itemtype);

private:
	NewGameItemBag				*m_bag;
	
	HuntItemUI					m_huntItemUI[HuntItemTypeEnd];
	
	NDUILabel					*m_lbHuntLost, *m_lbEquipAdd, *m_lbDuration;
	
	std::map<int, NDPicture*>	m_recylePictures;
	
	NDUIImage					*m_imageMouse;
	//NDUILayer					*m_layerBG;

private:
	void FilterHuntItem(const std::vector<Item*>& itemlist, std::vector<Item*>& outItemList);
	
	void InitHuntItem();
	
	void SetLabelText(NDUILabel*& lb, const char* text);
	
	HuntItemType GetHuntItemType(NDUIItemButton *btn);
	
	HuntItemType GetHuntItemTypeByStateID(int idState);
	
	bool IsHuntItem(NDUIButton *btn);
};

#pragma mark 寻宝场景

class TreasureHuntScene :
public NDCommonScene,
public NDUIDialogDelegate
{
	DECLARE_CLASS(TreasureHuntScene)
	
	static void processHuntDesc(NDTransData& data);
public:	
	TreasureHuntScene();
	
	~TreasureHuntScene();
	
	static TreasureHuntScene* Scene();
	
	void Initialization(); override
	
	void OnButtonClick(NDUIButton* button); override
	
	bool OnLayerMove(NDUILayer* uiLayer, UILayerMove move, float distance); override
	
	// huntLost-寻宝成功率 equipAdd-装备加成 duration-当前可寻宝时间
	void SetRateInfo(int huntLost, int equipAdd, int duration);
	
	void refreshHuntDesc();
	
	void OnDialogButtonClick(NDUIDialog* dialog, unsigned int buttonIndex); override
	
private:
	void OnTabLayerSelect(TabLayer* tab, unsigned int lastIndex, unsigned int curIndex); override
	
private:
	TreasureHuntLayer *m_layerTreasureHunt;
	
	NDUIButton *m_btnTreasureHunt;
	
	NDUIContainerScrollLayer *m_contentScroll;
	
	static std::string s_HuntDesc;
	
private:
	void InitTreasureHunt(NDUIClientLayer* client);
	
	void InitDesc(NDUIClientLayer* client);
};


#endif // _TREASURE_HUNT_H_