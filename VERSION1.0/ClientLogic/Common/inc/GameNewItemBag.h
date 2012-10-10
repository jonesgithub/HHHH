/*
 *  GameNewItemBag.h
 *  DragonDrive
 *
 *  Created by jhzheng on 11-8-6.
 *  Copyright 2011 (网龙)DeNA. All rights reserved.
 *
 */
 
#ifndef _GAME_NEW_ITEM_BAG_H_
#define _GAME_NEW_ITEM_BAG_H_
 
#include "NDUILayer.h"
#include "NDUIItemButton.h"
#include "NDPicture.h"
#include "NDUIImage.h"
#include "Item.h"
#include "NDUIBaseGraphics.h"
#include "define.h"
#include "NDUIDialog.h"
#include "ImageNumber.h"
#include <vector>

using namespace NDEngine;
using namespace std;

#define NEW_ITEM_BAG_W						(277)
#define NEW_ITEM_BAG_H						(270)

#define NEW_ITEM_CELL_INTERVAL_W			(4)
#define NEW_ITEM_CELL_INTERVAL_H			(5)

#define NEW_ITEM_CELL_W						(42)
#define NEW_ITEM_CELL_H						(42)

#define NEW_MAX_PAGE_COUNT					(4)
#define NEW_MAX_CELL_PER_PAGE				(24)

#define NEW_ITEM_BAG_C						(5)
#define NEW_ITEM_BAG_R						(5)

#define NEW_BKCOLOR4 (ccc4(227, 229, 218, 255))
#define NEW_BKCOLOR3 (ccc3(227, 229, 218))

#define NEW_FOCUS_DURATION_TIME (15)

#define NEW_BAG_OP_DROP (100)

class Item;
class ItemFocus;
class NewGameItemBag;
class NewGameItemBagDelegate
{
public:
	virtual void OnClickPage(NewGameItemBag* itembag, int iPage)													{}
	/**bFocused,表示该事件发生前该Cell是否处于Focus状态*/
	virtual bool OnClickCell(NewGameItemBag* itembag, int iPage, int iCellIndex, Item* item, bool bFocused)		{ return false;}
	/*ret=true*/
	virtual void AfterClickCell(NewGameItemBag* itembag, int iPage, int iCellIndex, Item* item, bool bFocused)		{}
	
	// 外部只需要处理卸载装备
	virtual bool OnBagButtonDragIn(NDUIButton* desButton, NDUINode *uiSrcNode, bool longTouch, bool del) { return false; }
	
	virtual bool OnDropItem(NewGameItemBag* itembag, Item* item) { return false; }
};

class NewGameItemBag : public NDUILayer , public NDUIButtonDelegate, public NDUIDialogDelegate
{
	DECLARE_CLASS(NewGameItemBag)
public:
	NewGameItemBag();
	~NewGameItemBag();
	
	void Initialization(vector<Item*>& itemlist, bool showMoney=false, bool tidyupEnable = true); override
	void SetPageCount(int iPage){ if(iPage<=0) return; m_iTotalPage = iPage > NEW_MAX_PAGE_COUNT ? NEW_MAX_PAGE_COUNT : iPage; }
	void draw(); override
	void OnButtonClick(NDUIButton* button); override
	
	bool OnButtonLongClick(NDUIButton* button); override
	bool OnButtonDragOut(NDUIButton* button, CGPoint beginTouch, CGPoint moveTouch, bool longTouch); override
	bool OnButtonDragOutComplete(NDUIButton* button, CGPoint endTouch, bool outOfRange); override
	bool OnButtonDragIn(NDUIButton* desButton, NDUINode *uiSrcNode, bool longTouch); override

	void OnDialogButtonClick(NDUIDialog* dialog, unsigned int buttonIndex); override
	void UpdateItemBag(vector<Item*>& itemlist);
	void UpdateItemBag(vector<Item*>& itemlist, vector<int> filter);
	bool AddItem(Item* item);
	bool DelItem(int iItemID);
	bool AddItemByIndex(int iCellIndex, Item* item);
	bool DelItemByIndex(int iCellIndex);
	bool IsFocus();
	void DeFocus();
	void SetTitle(string title);
	void SetTitleColor(ccColor4B color);
	Item* GetFocusItem();
	
	NDUIItemButton* GetFocusItemBtn();
	/**更新当前选中物品文本*/
	void UpdateTitle();
	
	void UpdateMoney();
	
	// 获取某页某个索引物品
	Item* GetItem(int iPage, int iIndex);
	
	void ShowPage(int iPage);
	
	int GetCurPage() { return m_iCurpage; }
	
	void ShowDel(bool show);
	
	NDUIItemButton* GetItemBtnByItem(Item* item);
	
	//该接口只提供给网络消息用来设置背包数
	static void UpdateBagNum(int iNum);
	
	bool SetItemAmountByID(int iItemID, unsigned int amount);
	bool SetItemAmount(Item* item, unsigned int amount);
private:
	NDUIItemButton* GetItemButtonByItemID(int iItemID);
	void ShowFocus();
	void HidePage(int iPage);
	void InitCellItem(int iIndex, Item* item, bool bShow);
	NDPicture* GetPagePic(unsigned int num, bool bHightLight);
	void InitMoney(NDUINode* parent);
private:
	NDUIItemButton* m_arrCellInfo[NEW_MAX_CELL_PER_PAGE*NEW_MAX_PAGE_COUNT];
	NDUILayer *m_backlayer;
	NDUILabel *m_lbTitle;
	NDUIButton *m_btnPages[NEW_MAX_PAGE_COUNT]; NDPicture *m_picPages[NEW_MAX_PAGE_COUNT];
	NDUIImage *m_imagePages[NEW_MAX_PAGE_COUNT];
	NDUILayer *m_pageLayer;
	int m_iCurpage;
	int m_iFocusIndex;
	ItemFocus *m_itemfocus;
	
	NDUIImage *m_imageMouse;
	
	NDUIButton *m_btnPlanOrDel; // 整理或删除
	NDPicture  *m_picPlan, *m_picDel;
	
	ImageNumber *m_imageNumInfo[3];
	
	bool m_showMoney;
	bool m_tidyupEnable;
public:
	static int m_iTotalPage;
};

#endif // _GAME_NEW_ITEM_BAG_H_
