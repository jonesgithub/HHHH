/*
 *  NewGamePetBag.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 12-1-13.
 *  Copyright 2012 __MyCompanyName__. All rights reserved.
 *
 */

#include "NewGamePetBag.h"

#include "NDDirector.h"
#include "CGPointExtension.h"
#include "NDUtility.h"
#include "GameItemBag.h"
#include "ImageNumber.h"
#include "define.h"
#include "NDUtility.h"
#include "ItemImage.h"
#include "NDDataTransThread.h"
#include "NDTransData.h"
#include "NDUISynLayer.h"
#include "NDMsgDefine.h"
#include "NDUIDialog.h"
#include "NDPlayer.h"
#include <sstream>

#define BTN_TAG_BEGIN (1001)

//////////////////////////////////////////////////////////////////////////////////////////
IMPLEMENT_CLASS(CUIItemInfo, NDUILayer)

CUIItemInfo::CUIItemInfo()
{
	m_pImage		= NULL;
	m_pLableName	= NULL;
	m_pLableLevel	= NULL;
	m_pSrcLableInfo	= NULL;
	m_pBtnUse		= NULL;
	m_bUse			= true;
	m_pBtnDrop		= NULL;
	m_bDrop			= true;
	
	m_bEnable		= true;
}

CUIItemInfo::~CUIItemInfo()
{
}

bool CUIItemInfo::Init()
{
	NDUILayer::Initialization();
	
	NDPicture* pPicBg = NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("bag_left_bg.png"));
	if (!pPicBg) {
		return false;
	}
	CGSize rSize = pPicBg->GetSize();
	this->SetFrameRect(CGRectMake(0,12, rSize.width, rSize.height));
	this->SetBackgroundImage(pPicBg, true);
	
	NDUIImage* imgSkillBg = new NDUIImage;
	imgSkillBg->Initialization();
	imgSkillBg->SetPicture(NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("bag_bagitem_sel.png")), true);
	imgSkillBg->SetFrameRect(CGRectMake(16, 16, 42, 42));
	this->AddChild(imgSkillBg);
	
	m_pImage = new NDUIImage;
	m_pImage->Initialization();
	m_pImage->SetFrameRect(CGRectMake(20, 20, 34, 34));
	this->AddChild(m_pImage);
	
	m_pLableName = new NDUILabel;
	m_pLableName->Initialization();
	m_pLableName->SetFontSize(16);
	m_pLableName->SetFontColor(ccc4(187, 19, 19, 255));
	m_pLableName->SetFrameRect(CGRectMake(66, 14, 160, 20));
	this->AddChild(m_pLableName);
	
	m_pLableLevel = new NDUILabel;
	m_pLableLevel->Initialization();
	m_pLableLevel->SetFontSize(14);
	m_pLableLevel->SetFontColor(ccc4(187, 19, 19, 255));
	m_pLableLevel->SetFrameRect(CGRectMake(66, 41, 100, 20));
	this->AddChild(m_pLableLevel);
	
	NDUIImage* imgSlash = new NDUIImage;
	imgSlash->Initialization();
	imgSlash->SetPicture(NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("bag_left_fengge.png")), true);
	imgSlash->SetFrameRect(CGRectMake(6, 68, 185, 2));
	this->AddChild(imgSlash);
	
	imgSlash = new NDUIImage;
	imgSlash->Initialization();
	imgSlash->SetPicture(NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("bag_left_fengge.png")), true);
	imgSlash->SetFrameRect(CGRectMake(6, 200, 185, 2));
	this->AddChild(imgSlash);
	
	m_pSrcLableInfo = new NDUILabelScrollLayer;
	m_pSrcLableInfo->Initialization();
	m_pSrcLableInfo->SetFrameRect(CGRectMake(6, 74, 180, 118));
	this->AddChild(m_pSrcLableInfo);
	
	NDPicture *picClose = NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("bag_left_close.png"));
	CGSize sizeClose = picClose->GetSize();
	m_pBtnClose = new NDUIButton;
	m_pBtnClose->Initialization();
	m_pBtnClose->SetFrameRect(CGRectMake(0, 206, sizeClose.width, sizeClose.height));
	m_pBtnClose->SetImage(picClose, false, CGRectZero, true);
	m_pBtnClose->SetDelegate(this);
	this->AddChild(m_pBtnClose);
	
	m_pBtnUse	= this->CreateButton(NDCommonCString("use"));
	m_pBtnUse->SetFrameRect(CGRectMake(70, 210, BUTTON_W, BUTTON_H));
	m_pBtnDrop	= this->CreateButton(NDCommonCString("PetDrop"));
	m_pBtnDrop->SetFrameRect(CGRectMake(130, 210, BUTTON_W, BUTTON_H));
	this->UpdateButton();
	return false;
}

void CUIItemInfo::EnableOperate(bool bEnable)
{
	m_bEnable = bEnable;
}

void CUIItemInfo::RefreshItemInfo(Item* pItem)
{
	if (!pItem) {
		this->ClearInfo();
	}
	else {
		m_pImage->SetPicture(ItemImage::GetItemByIconIndex(pItem->getIconIndex()), true);
		
		m_pLableName->SetText(pItem->getItemNameWithAdd().c_str());
		
		std::stringstream ss;
		ss << NDCommonCString("LevelRequire") << " : " << int(pItem->getReq_level()) << NDCommonCString("Ji");
		
		m_pLableLevel->SetText(ss.str().c_str());
		
		
		std::string desc;
		
		desc += pItem->makeItemDes(false, true);
		
		if (m_pSrcLableInfo) 
			m_pSrcLableInfo->SetText(desc.c_str());
	}
}

void CUIItemInfo::OnButtonClick(NDUIButton* button)
{
	if (button == m_pBtnUse) {
		CUIPetDelegate* pDelegate = dynamic_cast<CUIPetDelegate*> (this->GetDelegate());
		if (pDelegate) 
		{
			pDelegate->UseItem();
		}
	}
	else if (button == m_pBtnDrop) {
		CUIPetDelegate* pDelegate = dynamic_cast<CUIPetDelegate*> (this->GetDelegate());
		if (pDelegate) 
		{
			pDelegate->DropItem();
		}
	}
	else if (button == m_pBtnClose) {
		CUIPetDelegate* pDelegate = dynamic_cast<CUIPetDelegate*> (this->GetDelegate());
		if (pDelegate) 
		{
			pDelegate->CloseBagItemInfo();
		}
	}
}

void CUIItemInfo::SetVisible(bool bVisible)
{
	NDUILayer::SetVisible(bVisible);
	if (bVisible) {
		this->UpdateButton();
	}
}

void CUIItemInfo::ClearInfo()
{
	m_bUse		= false;
	m_bDrop		= false;
	m_pImage->SetPicture(NULL, true);
	m_pLableName->SetText("");
	m_pLableLevel->SetText("");
	m_pSrcLableInfo->SetText("");
	
	this->UpdateButton();
}

void CUIItemInfo::UpdateButton()
{
	if (!this->IsVisibled()) {
		return;
	}

	m_pBtnUse->SetVisible(m_bUse && m_bEnable);
	m_pBtnDrop->SetVisible(m_bDrop && m_bEnable);
}

NDUIButton* CUIItemInfo::CreateButton(const char* pszTitle)
{
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	NDUIButton* pBtn = new NDUIButton;
	if (!pBtn) {
		return false;
	}
	pBtn->Initialization();
	pBtn->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("bag_btn_normal.png")),
							   pool.AddPicture(GetImgPathNew("bag_btn_click.png")),
							   false, CGRectZero, true);
	pBtn->SetFontSize(12);
	pBtn->SetFontColor(ccc4(255, 255, 255, 255));
	pBtn->SetTitle(pszTitle);
	pBtn->SetFrameRect(CGRectMake(130, 210, BUTTON_W, BUTTON_H));
	pBtn->CloseFrame();
	pBtn->SetDelegate(this);
	this->AddChild(pBtn);
	return pBtn;
}

////////////////////////////////////////////////////////////////////////////////
IMPLEMENT_CLASS(NewGamePetBag, NDUILayer)

int NewGamePetBag::m_iTotalPage = 0;

NewGamePetBag::NewGamePetBag()
{
	m_backlayer = NULL;
	memset(m_arrCellInfo, 0, sizeof(CellInfo*)*NEW_MAX_CELL_PER_PAGE*NEW_MAX_PAGE_COUNT);
	memset(m_btnPages, 0, sizeof(NDUIButton*)*NEW_MAX_PAGE_COUNT);
	memset(m_picPages, 0, sizeof(NDPicture*)*NEW_MAX_PAGE_COUNT);
	m_iCurpage = 0;
	m_iFocusIndex = 0;
	m_iTotalPage = 0; 
	memset(m_imagePages, 0, sizeof(NDUIImage*)*NEW_MAX_PAGE_COUNT);
	m_itemfocus = NULL;
	
	m_imageMouse = NULL;
	m_pageLayer = NULL;

	m_btnDrop = NULL;
	
	memset(m_imageNumInfo, 0, sizeof(m_imageNumInfo));
	
	m_idOperatePet	= 0;
	m_idOperateItem	= 0;
}

NewGamePetBag::~NewGamePetBag()
{	
	//for (int i = 0; i < MAX_PAGE_COUNT; i++)
	//	{
	//		SAFE_DELETE(m_picPages[i]);
	//	}
	
	SAFE_DELETE(m_itemfocus);
}

void NewGamePetBag::Initialization(vector<Item*>& itemlist)
{
	NDUILayer::Initialization();
	//this->SetBackgroundColor(NEW_BKCOLOR4);
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	
	{
		int iPageX = 15;
		int iPageH = 20;
		int iPageW = ITEM_BAG_W - 2 * iPageX;
		int iBtnInterval = 4;
		int leftInter = 20;
		int iBtnW = (iPageW - leftInter * 2 - iBtnInterval*(MAX_PAGE_COUNT - 1) ) / MAX_PAGE_COUNT;
		
		m_pageLayer = new NDUILayer;
		m_pageLayer->Initialization();
		m_pageLayer->SetBackgroundColor(ccc4(0, 0, 0, 0));
		m_pageLayer->SetFrameRect(CGRectMake(0, ITEM_BAG_H+2, iPageW, iPageH));
		this->AddChild(m_pageLayer);
		
		for (int i = 0; i < MAX_PAGE_COUNT; i++)
		{
			std::stringstream ss; ss << (i+1);
			m_btnPages[i]= new NDUIButton;
			m_btnPages[i]->Initialization();
			m_btnPages[i]->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("bag_btn_normal.png")),
												NULL,
												false, CGRectZero, true);
			m_btnPages[i]->SetFocusImage(pool.AddPicture(GetImgPathNew("bag_btn_click.png")), false, CGRectZero, true);
			m_btnPages[i]->SetFontSize(14);
			m_btnPages[i]->SetTitle(ss.str().c_str());
			m_btnPages[i]->SetFontColor(ccc4(255, 255, 255, 255));
			m_btnPages[i]->CloseFrame();
			m_btnPages[i]->SetDelegate(this);
			
			int iBtnx = leftInter + i * (iBtnW  + iBtnInterval);
			m_btnPages[i]->SetFrameRect(CGRectMake(iBtnx, 0, iBtnW, iPageH));
			m_pageLayer->AddChild(m_btnPages[i]);
		}
	}
	
	// 设置数据
	vector<Item*>::iterator it = itemlist.begin();
	int iIndex = 0;
	for (; it != itemlist.end(); it++, iIndex++)
	{
		if (iIndex >= NEW_MAX_CELL_PER_PAGE*NEW_MAX_PAGE_COUNT)
		{
			break;
		}
		
		InitCellItem(iIndex, *it, false);
	}
	
	// 初始化第一页
	if (iIndex < NEW_MAX_CELL_PER_PAGE)
	{
		InitCellItem(iIndex, NULL, false);
	}
	
	ShowPage(0);
	
	m_itemfocus = new ItemFocus;
	m_itemfocus->Initialization();
	m_itemfocus->EnableEvent(false);
	this->AddChild(m_itemfocus,1);
	if (m_arrCellInfo[0])
	{
		m_itemfocus->SetFrameRect(m_arrCellInfo[0]->GetFrameRect());
	}
	
	m_imageMouse = new NDUIImage;
	
	m_imageMouse->Initialization();
	
	m_imageMouse->EnableEvent(false);
	
	this->AddChild(m_imageMouse, 2);
	
	NDPicture* pPicDel = pool.AddPicture(GetImgPathNew("trash_open.png"));
	
	m_btnDrop = new NDUIButton;
	m_btnDrop->Initialization();
	m_btnDrop->SetImage(pPicDel);
	m_btnDrop->SetDelegate(this);
	m_btnDrop->SetFrameRect(CGRectMake(10+(NEW_ITEM_CELL_INTERVAL_W+NEW_ITEM_CELL_W)*0,
											10+(NEW_ITEM_CELL_INTERVAL_H+NEW_ITEM_CELL_H)*(NEW_ITEM_BAG_R-1), 
											NEW_ITEM_CELL_W, NEW_ITEM_CELL_H));
	this->AddChild(m_btnDrop);
}
void NewGamePetBag::draw()
{
	NDUILayer::draw();
	
	if (m_itemfocus) m_itemfocus->SetVisible(false);
}

void NewGamePetBag::OnButtonClick(NDUIButton* button)
{
	if (m_iTotalPage < 1)
	{
		return;
	}

	for (int i=0; i < NEW_MAX_PAGE_COUNT; i++)
	{
		if ( button == m_btnPages[i])
		{
			if ( i <= m_iTotalPage-1 )
			{
				//切换页
				ShowPage( i+1 > m_iTotalPage ? 0 : i);
				
				int iStartIndex = i == 0 ? 0 : (i)*NEW_MAX_CELL_PER_PAGE;
				int iEndIndex = (i+1)*NEW_MAX_CELL_PER_PAGE;
				if (m_iFocusIndex >= iStartIndex && m_iFocusIndex < iEndIndex)
				{}
				else
				{
					m_iFocusIndex = -1;
					m_itemfocus->SetFrameRect(CGRectZero);
					
					this->SetFocus(NULL);
				}
				
				m_iCurpage = i;
			}
			
			NewGamePetBagDelegate* delegate = dynamic_cast<NewGamePetBagDelegate*> (this->GetDelegate());
			if (delegate) 
			{
				delegate->OnClickPage(this, i);
			}
			
			if (i >= m_iTotalPage)
			{
				stringstream ss; ss << NDCommonCString("KaiTongBag") << (i+1) << NDCommonCString("NeedSpend");
				if (i == 1) {
					ss << 200;
				} else if (i == 2) {
					ss << 500;
				} else if (i == 3) {
					ss << 1000;
				}
				
				ss << NDCommonCString("ge") << NDCommonCString("emoney");
				
				NDUIDialog *dlg = new NDUIDialog;
				dlg->Initialization();
				dlg->SetDelegate(this);
				dlg->SetTag(OPERATOR_ENLARGE_BAG);
				dlg->Show("", ss.str().c_str(), NDCommonCString("Cancel"), NDCommonCString("Ok"), NULL);
			}
			
			m_pageLayer->SetFocus(m_btnPages[m_iCurpage]);
			
			return;
		}
		
		
	}
	
	if (m_iCurpage >= NEW_MAX_PAGE_COUNT)
	{
		NDLog(@"物品包当前页出错!!!");
		return;
	}
	
	int iIndex = m_iCurpage*NEW_MAX_CELL_PER_PAGE;
	
	for (; iIndex < (m_iCurpage+1)*NEW_MAX_CELL_PER_PAGE; iIndex++)
	{
		if (m_arrCellInfo[iIndex] == button)
		{
			NewGamePetBagDelegate* delegate = dynamic_cast<NewGamePetBagDelegate*> (this->GetDelegate());
			bool bDelegateRet = true;
			bool bFocus = m_iFocusIndex == iIndex;
			if (delegate) 
			{
				bDelegateRet = delegate->OnClickCell(this, m_iCurpage, iIndex, m_arrCellInfo[iIndex]->GetItem(), bFocus );
			}
			
			if (m_iFocusIndex != iIndex)
			{
				m_itemfocus->SetFrameRect(m_arrCellInfo[iIndex]->GetFrameRect());
			}
			
			m_iFocusIndex = iIndex;
			
			CUIPetDelegate* pDelegate = dynamic_cast<CUIPetDelegate*> (this->GetDelegate());
			if (pDelegate) 
			{
				pDelegate->UpdateBagItemInfo();
			}
			return;
		}
	}
	
}

bool NewGamePetBag::OnButtonLongClick(NDUIButton* button)
{
	if (button->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton))) 
	{
		NDUIItemButton *btn = (NDUIItemButton*)button;
		
		Item *item = btn->GetItem();
		
		if (item) 
		{
			if (item->isFormula() || item->isItemPet() || item->isSkillBook())
			{
				sendQueryDesc(item->iID);
			} 
			else
			{
				NDUIDialog *dlg = new NDUIDialog;
				dlg->Initialization();
				std::string strtmp = item->makeItemDes(false, true);
				dlg->Show(item->getItemNameWithAdd().c_str(), strtmp.c_str(), NULL, NULL);
			}	
			
			return true;
		}
	}
	
	return false;
}

bool NewGamePetBag::OnButtonDragOut(NDUIButton* button, CGPoint beginTouch, CGPoint moveTouch, bool longTouch)
{
	if (button->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton)) && m_imageMouse) 
	{
		Item* item = ((NDUIItemButton*)button)->GetItem();
		
		if (!item) 
			return false;
		
		NDPicture* pic = ItemImage::GetItemByIconIndex(item->getIconIndex(), ((NDUIItemButton*)button)->IsGray());
		
		if (!pic) return false;
		
		if (pic) pic->SetGrayState(((NDUIItemButton*)button)->IsGray());
		
		m_imageMouse->SetPicture(pic, true);
		
		CGSize size = pic->GetSize();
		
		CGRect scrRect = this->GetScreenRect();
		
		CGPoint point = ccp(moveTouch.x-size.width/2-scrRect.origin.x, moveTouch.y-size.height/2-scrRect.origin.y);
		
		m_imageMouse->SetFrameRect(CGRectMake(point.x, point.y, pic->GetSize().width, pic->GetSize().height));

		return true;
	}
	
	return false;
}

bool NewGamePetBag::OnButtonDragOutComplete(NDUIButton* button, CGPoint endTouch, bool outOfRange)
{
	if (m_imageMouse)
		m_imageMouse->SetPicture(NULL, true);

	return false;
}

bool NewGamePetBag::OnButtonDragIn(NDUIButton* desButton, NDUINode *uiSrcNode, bool longTouch)
{
	if (!desButton || !uiSrcNode || uiSrcNode == desButton) {
		return true;
	}
	
	if (!uiSrcNode->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton))) {
		return true;
	}
	
	NDUIItemButton *srcButton = (NDUIItemButton*)uiSrcNode;
	Item* pItem = srcButton->GetItem();
	if (!pItem) {
		return true;
	}
	
	if (uiSrcNode->GetParent() != this) 
	{
		if (desButton == m_btnDrop) {
			// 丢弃物品
		}
		else {
			// 卸载装备
			CUIPetDelegate* pDelegate = dynamic_cast<CUIPetDelegate*> (this->GetDelegate());
			if (pDelegate) 
			{
				this->SendUnloadItemMsg(pDelegate->GetFocusPetId(), pItem->iID);
			}
		}

		return true;
	}
		
	if (desButton == m_btnDrop ) 
	{
		// 丢弃物品
		this->SendDropItemMsg(pItem->iID);
	}
	else
	{ // swap
		if (!desButton || !desButton->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton))) return false;
		
		if (desButton->GetParent() != this) return true;
		
		NDUIItemButton *dstItemButton = (NDUIItemButton*)desButton;
		
		Item* tmpItem = dstItemButton->GetItem();
		bool gray = dstItemButton->IsGray();
		
		dstItemButton->ChangeItem(srcButton->GetItem(), srcButton->IsGray());
		dstItemButton->EnalbeGray(srcButton->IsGray());
		
		srcButton->ChangeItem(tmpItem, gray);
		srcButton->EnalbeGray(gray);
		
		return true;
	}
	
	return true;
}

void NewGamePetBag::OnDialogButtonClick(NDUIDialog* dialog, unsigned int buttonIndex)
{
	if (!dialog) {
		return;
	}
	int nTag = dialog->GetTag();
	switch (nTag) {
		case OPERATOR_USE:
		{
			Item* pItem = ItemMgrObj.QueryItem(m_idOperateItem);
			if (!pItem) {
				return;
			}
			if (pItem->isItemPet()) {
				ItemMgrObj.UseItem(pItem);
			}
			else {
				if (m_idOperatePet && m_idOperateItem) {
					ShowProgressBar;
					NDTransData bao(_MSG_PET_ACTION);
					bao << int(m_idOperatePet) << (int)MSG_PET_ACTION_USEITEM << int(m_idOperateItem);
					SEND_DATA(bao);
				}
			}
			break;
		}
		case OPERATOR_DROP:
		{
			Item* pItem = ItemMgrObj.QueryItem(m_idOperateItem);
			if (pItem) {
				sendDropItem(*pItem);
			}
			break;
		}
		case OPERATOR_ENLARGE_BAG:
		{
			ShowProgressBar;
			NDTransData bao(_MSG_LIMIT);
			bao << (unsigned char)(1);
			SEND_DATA(bao);
			break;
		}
		default:
			break;
	}
	dialog->Close();
	m_idOperatePet	= 0;
	m_idOperateItem = 0;
}

void NewGamePetBag::UpdatePetBag(vector<Item*>& itemlist)
{
	if (m_iTotalPage <= 0)
	{
		return;
	}
	
	int iSize = int(itemlist.size());
	
	for (int i = 0; i < NEW_MAX_PAGE_COUNT; i++)
	{
		for (int j = 0; j < NEW_MAX_CELL_PER_PAGE; j++)
		{
			int iIndex = i*NEW_MAX_CELL_PER_PAGE+j;
			if (iIndex < iSize)
			{
				InitCellItem(iIndex, itemlist[iIndex], iIndex%NEW_MAX_CELL_PER_PAGE == m_iCurpage);
			}
			else
			{
				if (iIndex >= m_iTotalPage*NEW_MAX_CELL_PER_PAGE)
				{
					break;
				}
				InitCellItem(iIndex, NULL, iIndex%NEW_MAX_CELL_PER_PAGE == m_iCurpage);
			}
		}
	}
	
	ShowPage(m_iCurpage+1 > m_iTotalPage ? 0 : m_iCurpage);
}

void NewGamePetBag::UpdatePetBag(vector<Item*>& itemlist, vector<int> filter)
{
	vector<Item*> vec_item;
	vector<Item*>::iterator it = itemlist.begin();
	for (; it != itemlist.end(); it++) 
	{
		vector<int> vec_type = Item::getItemType((*it)->iItemType);
		int typesize = vec_type.size();
		int filtersize = filter.size();
		for (int i = 0; i < filtersize; i++) 
		{
			if (i > (typesize-1) || filter[i] != vec_type[i]) 
			{
				break;
			}
			
			if (i == filtersize-1) 
			{
				vec_item.push_back(*it);
			}
		}
	}
	
	UpdatePetBag(vec_item);
}

bool NewGamePetBag::AddItem(Item* item)
{
	for (int i = 0; i < NEW_MAX_PAGE_COUNT; i++)
	{
		for (int j = 0; j < NEW_MAX_CELL_PER_PAGE; j++)
		{
			int iIndex = i*NEW_MAX_CELL_PER_PAGE+j;
			
			if (iIndex >= m_iTotalPage*NEW_MAX_CELL_PER_PAGE)
			{
				break;
			}
			
			if (!m_arrCellInfo[iIndex] || m_arrCellInfo[iIndex]->GetItem()== NULL)
			{
				InitCellItem(iIndex, item, iIndex/NEW_MAX_CELL_PER_PAGE == m_iCurpage);
				return true;
			}
		}
	}
	return false;
}

bool NewGamePetBag::DelItem(int iItemID)
{
	for (int i = 0; i < NEW_MAX_PAGE_COUNT; i++)
	{
		for (int j = 0; j < NEW_MAX_CELL_PER_PAGE; j++)
		{
			int iIndex = i*NEW_MAX_CELL_PER_PAGE+j;
			
			if (iIndex >= m_iTotalPage*NEW_MAX_CELL_PER_PAGE)
			{
				break;
			}
			
			if (m_arrCellInfo[iIndex])
			{
				NDUIItemButton*& btn	= m_arrCellInfo[iIndex];
				
				if (btn && btn->GetItem() && btn->GetItem()->iID == iItemID)
				{
					btn->ChangeItem(NULL);
					
					return true;
				}
			}
		}
	}
	
	return false;
}

bool NewGamePetBag::AddItemByIndex(int iCellIndex, Item* item)
{
	if (!m_arrCellInfo[iCellIndex])
	{
		InitCellItem(iCellIndex, item, iCellIndex%NEW_MAX_CELL_PER_PAGE == m_iCurpage);
		return true;
	}
	return false;
}

bool NewGamePetBag::DelItemByIndex(int iCellIndex)
{
	if (m_arrCellInfo[iCellIndex])
	{
		m_arrCellInfo[iCellIndex]->ChangeItem(NULL);
		
		return true;
	}
	return false;
}

bool NewGamePetBag::IsFocus()
{
	return m_iFocusIndex != -1;
}

void NewGamePetBag::DeFocus()
{
	m_iFocusIndex = -1;
	m_itemfocus->SetFrameRect(CGRectZero);
}

Item* NewGamePetBag::GetFocusItem()
{
	if (m_iFocusIndex > -1 && m_arrCellInfo[m_iFocusIndex])
	{
		return m_arrCellInfo[m_iFocusIndex]->GetItem();
	}
	
	return NULL;
}

NDUIItemButton* NewGamePetBag::GetFocusItemBtn()
{
	if (m_iFocusIndex > -1 && m_arrCellInfo[m_iFocusIndex])
	{
		return m_arrCellInfo[m_iFocusIndex];
	}
	
	return NULL;
}

Item* NewGamePetBag::GetItem(int iPage, int iIndex)
{
	if (iPage >= m_iTotalPage || !(iIndex >= 0 && iIndex < NEW_MAX_CELL_PER_PAGE)) 
	{
		return NULL;
	}
	
	if (m_arrCellInfo[iPage*NEW_MAX_CELL_PER_PAGE+iIndex]) 
	{
		return m_arrCellInfo[iPage*NEW_MAX_CELL_PER_PAGE+iIndex]->GetItem();
	}
	
	return NULL;
}

void NewGamePetBag::ShowPage(int iPage)
{
	if (iPage >= NEW_MAX_PAGE_COUNT && iPage+1 <= m_iTotalPage)
	{
		return;
	}
	
	int iIndex = iPage*NEW_MAX_CELL_PER_PAGE;
	
	for (; iIndex < (iPage+1)*NEW_MAX_CELL_PER_PAGE; iIndex++)
	{
		if (!m_arrCellInfo[iIndex])
		{
			InitCellItem(iIndex, NULL, true);
		}
		
		if (m_arrCellInfo[iIndex])
		{
			m_arrCellInfo[iIndex]->SetVisible(true);
		}
	}
	
	HidePage(iPage);
	
	if (m_pageLayer && m_btnPages[iPage]) 
		m_pageLayer->SetFocus(m_btnPages[iPage]);
}

void NewGamePetBag::HidePage(int iExceptPage)
{
	if (iExceptPage >= NEW_MAX_PAGE_COUNT || iExceptPage < 0)
	{
		return;
	}
	
	for (int i = 0; i < NEW_MAX_PAGE_COUNT; i++)
	{
		if (i == iExceptPage)
		{
			continue;
		}
		
		int iIndex = i*NEW_MAX_CELL_PER_PAGE;
		
		for (; iIndex < (i+1)*NEW_MAX_CELL_PER_PAGE; iIndex++)
		{
			if (m_arrCellInfo[iIndex])
			{
				m_arrCellInfo[iIndex]->SetVisible(false);
			}
		}
	}
}

void NewGamePetBag::InitCellItem(int iIndex, Item* item, bool bShow)
{
	if (iIndex<0 || iIndex>=NEW_MAX_CELL_PER_PAGE*NEW_MAX_PAGE_COUNT)
	{
		NDLog(@"初始化物品格子参数有误!!!");
		return;
	}
	
	if (!m_arrCellInfo[iIndex])
	{
		int col = iIndex%NEW_MAX_CELL_PER_PAGE%NEW_ITEM_BAG_C;
		int row = iIndex%NEW_MAX_CELL_PER_PAGE/NEW_ITEM_BAG_C;
		
		if (row == NEW_ITEM_BAG_R-1)
		{
			col += 1;
		}
		
		m_arrCellInfo[iIndex] = new NDUIItemButton;
		m_arrCellInfo[iIndex]->Initialization();
		m_arrCellInfo[iIndex]->SetFrameRect(CGRectMake(10+(NEW_ITEM_CELL_INTERVAL_W+NEW_ITEM_CELL_W)*col,
													   10+(NEW_ITEM_CELL_INTERVAL_H+NEW_ITEM_CELL_H)*row, 
													   NEW_ITEM_CELL_W, NEW_ITEM_CELL_H));
		m_arrCellInfo[iIndex]->SetDelegate(this);
		this->AddChild(m_arrCellInfo[iIndex]);
		m_arrCellInfo[iIndex]->SetTag(BTN_TAG_BEGIN + iIndex); 
	}
	
	m_arrCellInfo[iIndex]->ChangeItem(item);
	
	m_arrCellInfo[iIndex]->SetVisible(bShow && this->IsVisibled());
}

void NewGamePetBag::UpdateBagNum(int iNum)
{
	if(iNum<=0) return; m_iTotalPage = iNum > NEW_MAX_PAGE_COUNT ? NEW_MAX_PAGE_COUNT : iNum;
}

NDPicture* NewGamePetBag::GetPagePic(unsigned int num, bool bHightLight)
{
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	NDPicture *pic = pool.AddPicture(GetImgPathNew("bag_bag_unsel.png"));
	NDPicture *picSel = pool.AddPicture(GetImgPathNew("bag_bag_sel.png"));
	NDPicture *picNum = pool.AddPicture(GetImgPathBattleUI("bag_number.png"));
	
	CGSize size = pic->GetSize(), sizeSel = picSel->GetSize();
	
	vector<const char*> vImgFiles;
	vector<CGRect> vImgCustomRect;
	vector<CGPoint>vOffsetPoint;
	vImgFiles.push_back(GetImgPathNew(bHightLight ? "bag_bag_sel.png" : "bag_bag_unsel.png"));
	vImgCustomRect.push_back(CGRectMake(0, 0, (bHightLight ? sizeSel.width : size.width), (bHightLight ? sizeSel.height : size.height)));
	vOffsetPoint.push_back(CGPointZero);
	vImgFiles.push_back(GetImgPathBattleUI("bag_number.png"));
	vImgCustomRect.push_back(getNewNumCut(num, bHightLight));
	CGPoint pos;
	pos.x = ((bHightLight ? sizeSel.width : size.width)-14)/2+(bHightLight ? 2 : 0);
	pos.y = ((bHightLight ? sizeSel.height : size.height)-14)/2;
	vOffsetPoint.push_back(pos);
	
	NDPicture* resPic = new NDPicture;
	
	resPic->Initialization(vImgFiles, vImgCustomRect, vOffsetPoint);
	
	delete pic;
	delete picSel;
	delete picNum;
	
	return resPic;
}

NDUIItemButton* NewGamePetBag::GetItemBtnByItem(Item* item)
{
	for (int i = 0; i < NEW_MAX_PAGE_COUNT; i++)
	{
		for (int j = 0; j < NEW_MAX_CELL_PER_PAGE; j++) 
		{
			if (m_arrCellInfo[i*NEW_MAX_CELL_PER_PAGE+j] &&
				m_arrCellInfo[i*NEW_MAX_CELL_PER_PAGE+j]->GetItem() == item)
				return m_arrCellInfo[i*NEW_MAX_CELL_PER_PAGE+j];
		}
	}
	
	return NULL;
}

NDUIItemButton* NewGamePetBag::GetItemButtonByItemID(int iItemID)
{
	for (int i = 0; i < NEW_MAX_PAGE_COUNT; i++)
	{
		for (int j = 0; j < NEW_MAX_CELL_PER_PAGE; j++)
		{
			int iIndex = i*NEW_MAX_CELL_PER_PAGE+j;
			
			if (iIndex >= m_iTotalPage*NEW_MAX_CELL_PER_PAGE)
			{
				break;
			}
			
			if (m_arrCellInfo[iIndex])
			{
				NDUIItemButton*& btn	= m_arrCellInfo[iIndex];
				
				if (btn && btn->GetItem() && btn->GetItem()->iID == iItemID)
				{
					return btn;
				}
			}
		}
	}
	
	return NULL;
}

bool NewGamePetBag::SetItemAmountByID(int iItemID, unsigned int amount)
{
	NDUIItemButton* btn = GetItemButtonByItemID(iItemID);
	if (btn) {
		btn->SetItemCount(amount);
		
		return true;
	}
	
	return false;
}

void NewGamePetBag::SendUseItemMsg(OBJID idPet, OBJID idItem)
{
	Item* pItem = ItemMgrObj.QueryItem(idItem);
	if (!pItem) {
		return;
	}
	// 确认使用对话框
	m_idOperatePet	= idPet;
	m_idOperateItem	= idItem;
	
	if (pItem->getMonopoly() & ITEMTYPE_MONOPOLY_NOT_USE_TIP) {
		NDUIDialog *dlg = new NDUIDialog;
		dlg->Initialization();
		dlg->SetTag(OPERATOR_USE);
		dlg->SetDelegate(this);
		stringstream ss;
		ss << NDCommonCString("MakeSureUse") << "'" << pItem->getItemName() << "'" << NDCommonCString("ma");
		dlg->Show(NDCommonCString("tip"), ss.str().c_str(), NDCommonCString("Cancel"), NDCommonCString("Ok"), NULL);
	}
	else {
		if (pItem->isItemPet()) {
			ItemMgrObj.UseItem(pItem);
		}
		else {
			if (idPet && idItem) {
				ShowProgressBar;
				NDTransData bao(_MSG_PET_ACTION);
				bao << int(idPet) << (int)MSG_PET_ACTION_USEITEM << int(idItem);
				SEND_DATA(bao);
			}
		}
	}
}

void NewGamePetBag::SendDropItemMsg(OBJID idItem)
{
	Item* pItem = ItemMgrObj.QueryItem(idItem);
	if (!pItem) {
		return;
	}
	if (pItem->isItemDropReminder())
	{
		NDUIDialog *dlg = new NDUIDialog;
		dlg->Initialization();
		dlg->SetTag(OPERATOR_DROP);
		m_idOperateItem	= idItem;
		dlg->SetDelegate(this);
		dlg->Show(NDCommonCString("drop"), NDCommonCString("DropTip"), NDCommonCString("Cancel"), NDCommonCString("Ok"), NULL);
	}
	else 
	{
		sendDropItem(*pItem);
	}
}

void NewGamePetBag::SendUnloadItemMsg(OBJID idPet, OBJID idItem)
{
	
}


bool NewGamePetBag::SetItemAmount(Item* item, unsigned int amount)
{
	NDUIItemButton* btn = GetItemBtnByItem(item);
	if (btn) {
		btn->SetItemCount(amount);
		
		return true;
	}
	
	return false;
}

void NewGamePetBag::SetVisible(bool visible)
{
	NDUILayer::SetVisible(visible);
	if (visible) 
	{
		this->ShowPage(this->GetCurPage());
	}
}

