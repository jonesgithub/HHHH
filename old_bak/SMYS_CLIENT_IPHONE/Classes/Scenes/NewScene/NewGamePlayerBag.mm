/*
 *  NewGamePlayerBag.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-8-12.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "NewGamePlayerBag.h"
#include "NDDirector.h"
#include "ItemMgr.h"
#include "ImageNumber.h"
#include "GameRoleNode.h"
#include "CGPointExtension.h"
#include "ItemImage.h"
#include "NDUtility.h"
#include "NDUIDialog.h"
#include "NDTransData.h"
#include "NDDataTransThread.h"
#include "NDBattlePet.h"
#include "NDPlayer.h"
#include "define.h"
#include "NDString.h"
#include "EnumDef.h"
#include "NDUISynLayer.h"
#include "NDMapMgr.h"
#include "GameItemInlay.h"
#import "PlayerInfoScene.h"
#include <sstream>


using namespace NDEngine;

#define PlayerBagDialog_Reapir (-2)

//////////////////////////////////////////////////////////

void NewGamePlayerBagUpdateMoney()
{
	NewPlayerBagLayer* bag = NewPlayerBagLayer::GetInstance();
	
	if (bag) 
		bag->UpdateMoney();
}

#define money_image ([[NSString stringWithFormat:@"%s", GetImgPath("money.png")] UTF8String])
#define emoney_image ([[NSString stringWithFormat:@"%s", GetImgPath("emoney.png")] UTF8String])
#define bag_image ([[NSString stringWithFormat:@"%s", GetImgPath("titles.png")] UTF8String])

IMPLEMENT_CLASS(NewPlayerBagLayer, NDUILayer)

NewPlayerBagLayer* NewPlayerBagLayer::s_instance = NULL;

NewPlayerBagLayer* NewPlayerBagLayer::GetInstance()
{
	return s_instance;
}

NewPlayerBagLayer::NewPlayerBagLayer()
{
	m_menuLayer = NULL;
	m_itembagPlayer = NULL;
	
	m_imageNumMoney = NULL; m_imageNumEMoney = NULL;
	
	m_picMoney = NULL; m_picEMoney = NULL;
	m_imageMoney = NULL; m_imageEMoney = NULL;
	
	m_picBag = NULL; m_imageBag = NULL;
	
	m_GameRoleNode = NULL;
	m_layerRole = NULL;
	
	memset(m_cellinfoEquip, 0, sizeof(m_cellinfoEquip));
	
	m_iFocusIndex = -1;
	m_itemfocus = NULL;
	
	m_layerEquip = NULL;
	
	m_tlShare = NULL;
	
	m_iShowType = NEW_SHOW_EQUIP_NORMAL;
	
	m_imageMouse = NULL;
	
	m_bagInfo = NULL;
	
	m_bagInfoShow = false;
	
	m_dlgRemoteSale = NULL;
	
	s_instance = this;
}

NewPlayerBagLayer::~NewPlayerBagLayer()
{
	SAFE_DELETE(m_picMoney);
	SAFE_DELETE(m_picEMoney);
	SAFE_DELETE(m_picBag);
	
	for (std::map<int, NDPicture*>::iterator it = m_recylePictures.begin(); it != m_recylePictures.end(); it++) 
	{
		delete it->second;
	}
	
	m_recylePictures.clear();
	
	s_instance = NULL;
}

/*
GamePlayerBagScene* GamePlayerBagScene::Scene()
{
	GamePlayerBagScene* scene = new GamePlayerBagScene();	
	scene->Initialization();
	return scene;
}
*/

void NewPlayerBagLayer::Initialization(int iShowType /*= NEW_SHOW_EQUIP_NORMAL*/)
{
	if (iShowType < NEW_SHOW_EQUIP_BEGIN || iShowType >= NEW_SHOW_EQUIP_END)
	{
		NDLog(@"设置玩家背包类型出错了!!!");
		iShowType = NEW_SHOW_EQUIP_NORMAL;
	}
	
	NDUILayer::Initialization();
	
	CGSize winSize = NDDirector::DefaultDirector()->GetWinSize();
	
	m_iShowType = iShowType;
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	NDPicture* picBagLeftBg = pool.AddPicture(GetImgPathNew("bag_left_bg.png"));
	
	CGSize sizeBagLeftBg = picBagLeftBg->GetSize();
	
	m_layerEquip = new NDUILayer;
	m_layerEquip->Initialization();
	m_layerEquip->SetFrameRect(CGRectMake(0,12, sizeBagLeftBg.width, sizeBagLeftBg.height));
	m_layerEquip->SetBackgroundImage(picBagLeftBg, true);
	//m_layerEquip->SetBackgroundColor(ccc4(25, 255, 255, 0));
	this->AddChild(m_layerEquip);
	
	NDPicture* picRoleBg = pool.AddPicture(GetImgPathNew("role_bg.png"));
	NDUIImage *imgRoleBg = new NDUIImage;
	imgRoleBg->Initialization();
	imgRoleBg->SetFrameRect(CGRectMake(49, 57, picRoleBg->GetSize().width, picRoleBg->GetSize().height));
	imgRoleBg->SetPicture(picRoleBg, true);
	m_layerEquip->AddChild(imgRoleBg);
	
	m_bagInfo = new BagItemInfo;
	m_bagInfo->Initialization();
	m_bagInfo->SetFrameRect(CGRectMake(0,12, sizeBagLeftBg.width, sizeBagLeftBg.height));
	m_bagInfo->SetDelegate(this);
	this->AddChild(m_bagInfo);
	
	ShowBagInfo(false);
	
	{ // todo 人物角色
	/*
	m_GameRoleNode = new GameRoleNode;
	m_GameRoleNode->Initialization();
	//以下两行固定用法
	m_GameRoleNode->SetFrameRect(CGRectMake(0, 0, winSize.width, winSize.height));
	m_GameRoleNode->SetDisplayPos(ccp(92+8,136+16));
	m_layerRole->AddChild(m_GameRoleNode);
	*/
	}
	
	UpdateEquipList();
	
	std::vector<Item*>& itemlist = ItemMgrObj.GetPlayerBagItems();
	m_itembagPlayer = new NewGameItemBag;
	m_itembagPlayer->Initialization(itemlist, true);
	m_itembagPlayer->SetDelegate(this);
	m_itembagPlayer->SetPageCount(ItemMgrObj.GetPlayerBagNum());
	m_itembagPlayer->SetFrameRect(CGRectMake(203, 5, NEW_ITEM_BAG_W, NEW_ITEM_BAG_H));
	this->AddChild(m_itembagPlayer);
	
	{// todo 修理逻辑
	/*
	if (m_iShowType == NEW_SHOW_EQUIP_REPAIR && itemlist.size() >=1 )
	{
		m_itembagPlayer->SetTitle(getRepairDesc(itemlist[0]));
	}
	*/
	}
	
	m_imageMouse = new NDUIImage;
	
	m_imageMouse->Initialization();
	
	m_imageMouse->EnableEvent(false);
	
	this->AddChild(m_imageMouse, 1);
}

void NewPlayerBagLayer::OnClickPage(NewGameItemBag* itembag, int iPage)
{
	if (itembag == m_itembagPlayer)
	{
		m_bagInfo->SetVisible(false);
		m_bagInfoShow	= false;
	}
}
/**bFocus,表示该事件发生前该Cell是否处于Focus状态*/
bool NewPlayerBagLayer::OnClickCell(NewGameItemBag* itembag, int iPage, int iCellIndex, Item* item, bool bFocused)
{
	if (m_iFocusIndex != -1 && m_itemfocus)
	{
		m_iFocusIndex = -1;
		m_itemfocus->SetFrameRect(CGRectZero);
	}
	
	if( m_iShowType == NEW_SHOW_EQUIP_REPAIR && bFocused)
	{
		m_bagOPInfo.set(iCellIndex, item);
		
		std::vector<std::string> vec_str;
		if (item->isEquip())
		{
			vec_str.push_back(std::string(NDCommonCString("RepairCurEquip")));
		}
		vec_str.push_back(std::string(NDCommonCString("RepairAllEquip")));
		//InitTLContentWithVec(m_tlShare, vec_str);
		if (m_itembagPlayer)
		{
			m_itembagPlayer->SetTitle(getRepairDesc(item));
		}
		return true;
	}
	
	if (itembag == m_itembagPlayer && item && NEW_SHOW_EQUIP_NORMAL == m_iShowType) 
	{
		ShowBagInfo(true);
		
		m_bagInfo->ChangItem(item);
		
		return true;
	}
	
	if (item)
	{
		if (m_iShowType == NEW_SHOW_EQUIP_REPAIR)
		{
			m_itembagPlayer->SetTitle(getRepairDesc(item));
		}
		else
		{
			m_itembagPlayer->SetTitle(item->getItemDesc());
		}
	}
	else 
	{
		m_itembagPlayer->SetTitle("");
	}
	
	return true;
}

void NewPlayerBagLayer::OnButtonClick(NDUIButton* button)
{
	for (int i = Item::eEP_Begin; i < Item::eEP_End; i++)
	{
	
		if (!m_cellinfoEquip[i])
		{
			InitEquipItemList(i, NULL);
		}
		
		if (!m_cellinfoEquip[i])
		{
			continue;
		}
		
		if ( button == m_cellinfoEquip[i] )
		{
			
			if (m_iFocusIndex == i && m_cellinfoEquip[i]->GetItem())
			{
				/*
				// 前一状态已获得焦点
				if (m_cellinfoEquip[i]->item)
				{
					hasEquipItem(m_cellinfoEquip[i]->item, i);
				}
				else
				{
					notHasEquipItem(i);
				}
				*/
				
				if (NEW_SHOW_EQUIP_NORMAL == m_iShowType) 
				{
					ShowBagInfo(true);
					
					m_bagInfo->ChangItem(m_cellinfoEquip[i]->GetItem(), true);
				}
			}
			/*
			else 
			{
				// 前一状态未获得焦点
				if( m_cellinfoEquip[i]->item )
				{
					if (m_iShowType == NEW_SHOW_EQUIP_REPAIR)
					{
						m_itembagPlayer->SetTitle(getRepairDesc(m_cellinfoEquip[i]->item));
					}
					else
					{
						m_itembagPlayer->SetTitle(m_cellinfoEquip[i]->item->getItemDesc());
					}
				}
				else 
				{
					m_itembagPlayer->SetTitle(getEquipPositionInfo(i));
				}
			}
			*/
			m_iFocusIndex = i;
			
			/*
			if (m_itemfocus && m_cellinfoEquip[i] && m_cellinfoEquip[i]->button)
			{
				m_itemfocus->SetFrameRect(m_cellinfoEquip[i]->button->GetFrameRect());
			}
			
			if (m_itembagPlayer)
			{
				m_itembagPlayer->DeFocus();
			}
			*/
			return;
		}
	}
}

void NewPlayerBagLayer::OnDialogButtonClick(NDUIDialog* dialog, unsigned int buttonIndex)
{
	if (dialog == m_dlgRemoteSale)
	{
		// 远程出售物品
		ShowProgressBar;
		NDTransData bao(_MSG_SHOP);
		bao << int(dialog->GetTag()) << int(0) << (unsigned char)(4) << (unsigned char)(0);
		SEND_DATA(bao);
		dialog->Close();
		return;
	}
	if (dialog)
	{ //卸下装备
		if (dialog->GetTag() == PlayerBagDialog_Reapir)
		{
			//修理所有装备
			sendItemRepair(0, Item::_ITEMACT_REPAIR_ALL);
			dialog->Close();
			return;
		}
		
		if (m_bagOPInfo.operate == bag_cell_info::e_op_kaitong) 
		{
			ShowProgressBar;
			NDTransData bao(_MSG_LIMIT);
			bao << (unsigned char)(1);
			SEND_DATA(bao);
		}
		else if (!m_equipOPInfo.empty())
		{
		/*
			ShowProgressBar;
			NDTransData bao(_MSG_ITEM);
			bao << int(m_equipOPInfo.item->iID) << (unsigned char)(Item::ITEM_UNEQUIP);
			SEND_DATA(bao);
		*/
		}
		else if (!m_bagOPInfo.empty())
		{
			if (m_bagOPInfo.operate == bag_cell_info::e_op_use)
			{ //使用物品
				ItemMgrObj.UseItem(m_bagOPInfo.item);
			}
			else if (m_bagOPInfo.operate == bag_cell_info::e_op_drop)
			{ // 丢弃物品
				sendDropItem(*(m_bagOPInfo.item));
			}
			else if (m_bagOPInfo.operate == bag_cell_info::e_op_xuexi)
			{ // 学习物品
				ItemMgrObj.UseItem(m_bagOPInfo.item);
			}
			else if (m_bagOPInfo.operate == bag_cell_info::e_op_bind)
			{ // 绑定物品
				ShowProgressBar;
				NDTransData bao(_MSG_EQUIP_BIND);
				bao << (unsigned char)0 << int(m_bagOPInfo.item->iID);
				SEND_DATA(bao);
			}
		}
	}
	dialog->Close();
}
void NewPlayerBagLayer::OnDialogClose(NDUIDialog* dialog)
{
	m_dlgRemoteSale = NULL;
	
	m_bagOPInfo.reset();
	
	m_equipOPInfo.reset();
}

bool NewPlayerBagLayer::OnCustomViewConfirm(NDUICustomView* customView)
{
	if(!m_bagOPInfo.empty() && customView)
	{
		if (m_bagOPInfo.operate == bag_cell_info::e_op_caifeng)
		{
			VerifyViewNum(*customView);
			
			std::string stramount =	customView->GetEditText(0);
			if (!stramount.empty())
			{
				int chaiFenNum = atoi(stramount.c_str());
				if (chaiFenNum <= 0 || chaiFenNum >= m_bagOPInfo.item->iAmount) {
					//T.gotoAlert("物品数量不合法", "请重新输入", 2000);
					customView->ShowAlert(NDCommonCString("ItemAmountInvalidReinput"));
					return false;
				}
				
				ShowProgressBar;
				NDTransData bao(_MSG_SPLIT_ITEM);
				bao << int(m_bagOPInfo.item->iID) << (unsigned short)(chaiFenNum);
				SEND_DATA(bao);
			}
		}
	}
	m_bagOPInfo.reset();
	return true;
}

void NewPlayerBagLayer::OnCustomViewCancle(NDUICustomView* customView)
{
	m_bagOPInfo.reset();
}

void NewPlayerBagLayer::OnBagItemInfoOperate(BagItemInfo* bagiteminfo, Item* item, BagItemOperate op)
{
	if (!item || op < BagItemOperate_Begin || op >= BagItemOperate_End ) 
		return;
	
	m_bagOPInfo.item = item;
	
	switch (op) {
		case BagItemOperate_Use:
		{
			if (item->getMonopoly() & ITEMTYPE_MONOPOLY_NOT_USE_TIP) {
				m_bagOPInfo.operate = bag_cell_info::e_op_use;
				NDUIDialog *dlg = new NDUIDialog;
				dlg->Initialization();
				dlg->SetTag(m_bagOPInfo.item->iID);
				dlg->SetDelegate(this);
				stringstream ss;
				ss << NDCommonCString("MakeSureUse") << "'" << item->getItemName() << "'" << NDCommonCString("ma");
				dlg->Show(NDCommonCString("tip"), ss.str().c_str(), NDCommonCString("Cancel"), NDCommonCString("Ok"), NULL);
			} 
			else {
				ItemMgrObj.UseItem(item);
			}

		}
			break;
		case BagItemOperate_Learn:
		{
			if (m_bagOPInfo.item->iAmount > 0)
			{
				if (m_bagOPInfo.item->isItemUseReminder())
				{
					m_bagOPInfo.operate = bag_cell_info::e_op_xuexi;
					
					NDUIDialog *dlg = new NDUIDialog;
					dlg->Initialization();
					dlg->SetTag(m_bagOPInfo.item->iID);
					dlg->SetDelegate(this);
					stringstream ss;
					ss << NDCommonCString("MakeSureLearn") << "'" << m_bagOPInfo.item->getItemName() << "'" << NDCommonCString("ma");
					dlg->Show(NDCommonCString("tip"), ss.str().c_str(), NDCommonCString("Cancel"), NDCommonCString("Ok"), NULL);
				}
				else 
				{
					ItemMgrObj.UseItem(m_bagOPInfo.item);
				}
				
			}
		}
			break;
		case BagItemOperate_Inlay:
		{
			int itemType = m_bagOPInfo.item->iItemType;
			bool stone = itemType / 100000 == 290;
			
			int equipType = (itemType / 100000) % 100;
			
			std::vector<Item*> vec_item_res;
			std::vector<Item*> vec_item = ItemMgrObj.GetPlayerBagItems();
			std::vector<Item*>::iterator it = vec_item.begin();
			for (; it != vec_item.end(); it++)
			{
				Item *item = (*it);
				if (item == NULL)
				{
					continue;
				}
				if (stone) {
					if (item->canInlay()) {
						vec_item_res.push_back(item);
					}
				} else if (item->iItemType / 100000 == 290) {
					bool bAdd = false;
					int stoneType = (item->iItemType / 1000) % 100;
					if (equipType < 40 && stoneType == 1) { // 武器
						bAdd = true;
					} else if (equipType == stoneType) { // 其他装备位
						bAdd = true;
					}
					if (bAdd) {
						vec_item_res.push_back(item);
					}
				}
			}
			
			if ( vec_item_res.size() == 0 )
			{
				//stone ? "没有可镶嵌的装备" : "没有可镶嵌的宝石"
			}
			
			GameInlayScene* scene = new GameInlayScene();	
			scene->Initialization(m_bagOPInfo.item->iID, m_bagOPInfo.item->iItemType);
			NDDirector::DefaultDirector()->PushScene(scene);
		}
			break;
		case BagItemOperate_Active:
		{
			m_bagOPInfo.item->active = true;
		}
			break;
		case BagItemOperate_Compare:
		{
			int comparePosition = getComparePosition(m_bagOPInfo.item);
			Item *tempItem = m_cellinfoEquip[comparePosition]->GetItem();
			if (!tempItem) return;
			std::string tempStr = Item::makeCompareItemDes(tempItem, m_bagOPInfo.item, -1);
			// ChatRecordManager.parserChat(tempStr, -1)
			NDUIDialog *dlg = new NDUIDialog;
			dlg->Initialization();
			dlg->Show(NDCommonCString("compare"), tempStr.c_str(), NULL, NULL);
		}
			break;
		case BagItemOperate_Bind:
		{
			m_bagOPInfo.operate = bag_cell_info::e_op_bind;			
			NDUIDialog *dlg = new NDUIDialog;
			dlg->Initialization();
			dlg->SetTag(m_bagOPInfo.item->iID);
			dlg->SetDelegate(this);
			dlg->Show(NDCommonCString("tip"), NDCommonCString("ForeverBindTip"), NDCommonCString("Cancel"), NDCommonCString("Ok"), NULL);
		}
			break;
		case BagItemOperate_Drop:
		{
			DropOperate(item);
		}
			break;
		case BagItemOperate_CaiFeng:
		{
			m_bagOPInfo.operate = bag_cell_info::e_op_caifeng;
			stringstream ss;
			ss << NDCommonCString("CurAmount") << ":" << m_bagOPInfo.item->iAmount << ", " << NDCommonCString("InputCaiFengAmount") << ":";
			NDUICustomView *view = new NDUICustomView;
			view->Initialization();
			view->SetDelegate(this);
			std::vector<int> vec_id; vec_id.push_back(1);
			std::vector<std::string> vec_str; vec_str.push_back(ss.str());
			view->SetEdit(1, vec_id, vec_str);
			view->Show();
			this->AddChild(view);
		}
			break;
		case BagItemOperate_ChaKang:
			sendQueryDesc(item->iID);
			break;
		case BagItemOperate_chuShou:
		{
			m_bagOPInfo.operate = bag_cell_info::e_op_sale;
			if (NDPlayer::defaultHero().m_nVipLev >= 5) {
				m_dlgRemoteSale = new NDUIDialog;
				m_dlgRemoteSale->Initialization();
				m_dlgRemoteSale->SetDelegate(this);
				m_dlgRemoteSale->SetTag(item->iID);
				m_dlgRemoteSale->Show(NDCommonCString("WenXinTip"), NDCommonCString("RemoteSaleTip"), "", NDCommonCString("Ok"), NULL);
			}
			else {
				NDUIDialog* pDlg = new NDUIDialog;
				if (pDlg) {
					pDlg->Initialization();
					NDString strText;
					strText.Format(NDCommonCString("RemoteSaleVip"), NDPlayer::defaultHero().m_nVipLev);
					pDlg->Show(NDCommonCString("WenXinTip"), strText.getData(), NULL, NULL);
				}
			}
		}
			break;

		default:
			break;
	}
}

bool NewPlayerBagLayer::OnBagButtonDragIn(NDUIButton* desButton, NDUINode *uiSrcNode, bool longTouch, bool del)
{
	if (!uiSrcNode || !uiSrcNode->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton))) return false;
	
	//if (!desButton || !desButton->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton)) ) return false;
	
	if (desButton->GetParent() != m_itembagPlayer) return false;
	
	NDUIItemButton *itemBtn = (NDUIItemButton*)uiSrcNode;
	Item* item = itemBtn->GetItem();
	if (!item) return false;
	
	// 卸载装备或丢装备
	for (int i = Item::eEP_Begin; i < Item::eEP_End; i++) 
	{
		if (!m_cellinfoEquip[i]) continue;
		
		if (itemBtn == m_cellinfoEquip[i]) 
		{
			if (del) 
			{
				DropOperate(item);
				
				return true;
			}
			
			if (item->isRidePet() && !NDPlayer::defaultHero().canUnpackRidePet())
			{
				showDialog(NDCommonCString("warring"), NDCommonCString("CantUnEquip"));
				return true;
			}
			
			ShowProgressBar;
			NDTransData bao(_MSG_ITEM);
			bao << int(item->iID) << (unsigned char)(Item::ITEM_UNEQUIP);
			SEND_DATA(bao);
			return true;
		}
	}
	
	return false;
}

bool NewPlayerBagLayer::OnDropItem(NewGameItemBag* itembag, Item* item)
{
	if (itembag == m_itembagPlayer && item) 
	{
		DropOperate(item);
		
		return true;
	}
	
	return false;
}

bool NewPlayerBagLayer::OnButtonDragOut(NDUIButton* button, CGPoint beginTouch, CGPoint moveTouch, bool longTouch)
{
	if (button->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton))) 
	{
		Item* item = ((NDUIItemButton*)button)->GetItem();
		
		if (!item) 
			return false;
			
		bool find = false;
			
		for (int i = Item::eEP_Begin; i < Item::eEP_End; i++) 
		{
			if (!m_cellinfoEquip[i]) continue;
			
			if (button == m_cellinfoEquip[i]) 
			{
				find = true;
				
				break;
			}
		}
		
		if (!find) return false;
		
		std::map<int, NDPicture*>::iterator cache = m_recylePictures.find(item->iItemType);
		
		NDPicture* pic = NULL;
		
		if (cache != m_recylePictures.end() ) 
		{
			pic = cache->second;
		}
		else
		{
			pic = ItemImage::GetItemByIconIndex(item->getIconIndex(), ((NDUIItemButton*)button)->IsGray());
			
			if (!pic) return false;
			
			m_recylePictures.insert(std::pair<int, NDPicture*>(item->iItemType, pic));
		}
		
		if (pic && m_imageMouse) 
		{
			pic->SetGrayState(((NDUIItemButton*)button)->IsGray());
			
			m_imageMouse->SetPicture(pic);
			
			CGSize size = pic->GetSize();
			
			CGRect scrRect = this->GetScreenRect();
			
			m_imageMouse->SetFrameRect(CGRectMake(moveTouch.x-size.width/2-scrRect.origin.x, moveTouch.y-size.height/2-scrRect.origin.y, pic->GetSize().width, pic->GetSize().height));
			
			if (m_itembagPlayer) 
				m_itembagPlayer->ShowDel(true);
			
			return true;
		}
	}
	
	return false;
	
}

bool NewPlayerBagLayer::OnButtonDragOutComplete(NDUIButton* button, CGPoint endTouch, bool outOfRange)
{
	m_imageMouse->SetPicture(NULL);
	
	if (m_itembagPlayer) 
		m_itembagPlayer->ShowDel(false);
	
	return false;
}

bool NewPlayerBagLayer::OnButtonDragIn(NDUIButton* desButton, NDUINode *uiSrcNode, bool longTouch)
{
	if (uiSrcNode && uiSrcNode->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton)) 
		&& desButton != uiSrcNode && uiSrcNode->GetParent() == m_itembagPlayer) 
	{
		Item* item = ((NDUIItemButton*)uiSrcNode)->GetItem();
		
		if (!item) 
			return false;
		
		bool find = false;
		
		for (int i = Item::eEP_Begin; i < Item::eEP_End; i++) 
		{
			if (!m_cellinfoEquip[i]) continue;
			
			if (desButton == m_cellinfoEquip[i]) 
			{
				find = true;
				
				break;
			}
		}
		
		if (!find) return false;
		
		if (!item->isEquip() || item->isItemPet())
		{
			showDialog(NDCommonCString("tip"), NDCommonCString("CantEquip"));
			
			return true;
		}
		
		if (checkItemLimit(item, true))
		{
			ItemMgrObj.UseItem(item);
			
			return true;
		}
	}
	
	return false;
}

void NewPlayerBagLayer::UpdateEquipList()
{
	for (int i = Item::eEP_Begin; i < Item::eEP_End; i++)
	{
		InitEquipItemList(i, ItemMgrObj.GetEquipItemByPos(Item::eEquip_Pos(i)));
	}
	//if (m_itembagPlayer)
	//	{
	//		m_itembagPlayer->UpdateItemBag(ItemMgrObj.GetPlayerBagItems());
	//	}
	
	ShowBagInfo(false);
}

void NewPlayerBagLayer::AddItemToBag(Item* item)
{ 
	if (!item || !m_itembagPlayer) return; 
	
	m_itembagPlayer->AddItem(item);
}

void NewPlayerBagLayer::UpdateBag()
{ 
	if (!m_itembagPlayer) return;
		m_itembagPlayer->UpdateItemBag(ItemMgrObj.GetPlayerBagItems());
}

void NewPlayerBagLayer::UpdateMoney()
{	
	/*
	NDPlayer& player = NDPlayer::defaultHero();
	if (m_imageNumMoney)
		m_imageNumMoney->SetTitleRedNumber(player.money);
	if (m_imageNumEMoney)
		m_imageNumEMoney->SetTitleRedNumber(player.eMoney);
	*/
	
	if (m_itembagPlayer) 
	{
		m_itembagPlayer->UpdateMoney();
	}
}

void NewPlayerBagLayer::UpdateItem(int iItemID)
{
	Item* item = ItemMgrObj.QueryItem(iItemID);
	if (m_itembagPlayer && item)
	{
		m_itembagPlayer->SetItemAmount(item, item->iAmount);
	}
}

void NewPlayerBagLayer::updateCurItem()
{
	if (m_iFocusIndex != -1 && m_itembagPlayer && m_itembagPlayer->IsFocus())
	{
		NDLog(@"updateCurItem出错,出现背包与装备同时处于焦点状态!!!");
	}
	
	if (!m_itembagPlayer)
	{
		NDLog(@"updateCurItem出错,背包指针为空!!!");
	}
	
	if (m_iFocusIndex != -1
		&& m_cellinfoEquip[m_iFocusIndex])
	{
		
		if( m_cellinfoEquip[m_iFocusIndex]->GetItem() )
		{
			if (m_iShowType == NEW_SHOW_EQUIP_REPAIR)
			{
				m_itembagPlayer->SetTitle(getRepairDesc(m_cellinfoEquip[m_iFocusIndex]->GetItem()));
			}
			else
			{
				m_itembagPlayer->SetTitle(m_cellinfoEquip[m_iFocusIndex]->GetItem()->getItemDesc());
			}
		}
		else 
		{
			m_itembagPlayer->SetTitle(getEquipPositionInfo(m_iFocusIndex));
		}
		
	}
	
	if (m_itembagPlayer && m_itembagPlayer->IsFocus())
	{
		m_itembagPlayer->UpdateTitle();
		
		Item* item = m_itembagPlayer->GetFocusItem();
		if (item && m_bagInfo) 
		{
			m_bagInfo->ChangItem(item);
			ShowBagInfo(false);
		}
		
		NDUIItemButton* btn = m_itembagPlayer->GetFocusItemBtn();
		
		if (btn)
			btn->ChangeItem(item);
	}
}

std::string NewPlayerBagLayer::getEquipPositionInfo(int index)
{
	// //0肩 1头 2胸 3项链 4耳环 5腰带--披风 6主武器 7无 8副武 9徽记 10手 11宠物 12护腿 13无 14鞋子
	// 15左戒指
	// 16右戒指
	// 17坐骑
	std::string tip;
	switch (index) {
		case Item::eEP_Shoulder: {
			tip = NDCommonCString("HuJian");
		}
		case Item::eEP_Head: {
			tip = NDCommonCString("TouKui");
		}
		case Item::eEP_Armor: {
			tip = NDCommonCString("YiFu");
		}
			
		case Item::eEP_XianLian: {
			tip = NDCommonCString("XiangLiang");
		}
		case Item::eEP_ErHuan: {
			tip = NDCommonCString("ErHuan");
		}
		case Item::eEP_YaoDai: {
			tip = NDCommonCString("PiFeng");// 腰带
		}
			
		case Item::eEP_MainArmor: {
			tip = NDCommonCString("WuQi");
		}
		case Item::eEP_FuArmor: {
			tip = NDCommonCString("FuShou");
		}
		case Item::eEP_HuiJi: {
			tip = NDCommonCString("HuiJi");
		}
		case Item::eEP_Shou: {
			tip = NDCommonCString("HuWang");
		}
		case Item::eEP_Decoration: {
			tip = NDCommonCString("decoration");
		}
		case Item::eEP_HuTui: {
			tip = NDCommonCString("HuTui");
		}
		case Item::eEP_Shoes: {
			tip = NDCommonCString("XieZhi");
		}
		case Item::eEP_LeftRing: {
			tip = NDCommonCString("JieZhi");
		}
		case Item::eEP_RightRing: {
			tip = NDCommonCString("JieZhi");
		}
		case Item::eEP_Ride: {
			tip = NDCommonCString("ZhuoQi");
		}
	}
	
	if (!tip.empty())
	{
		return std::string("--" + tip);
	}
	return "";
}

void NewPlayerBagLayer::DelBagItem(int iItemID) 
{ 
	if (m_itembagPlayer) 
		m_itembagPlayer->DelItem(iItemID); 
	
	ShowBagInfo(false);
} 

void NewPlayerBagLayer::SetVisible(bool visible)
{
	NDUILayer::SetVisible(visible);
	
	if (visible && m_bagInfo)
	{
		m_bagInfo->SetVisible(m_bagInfoShow);
	}
	
	if (visible && m_itembagPlayer) 
	{
		m_itembagPlayer->ShowPage(m_itembagPlayer->GetCurPage());
	}
	
	NDScene* scene = NDDirector::DefaultDirector()->GetRunningScene();
	if (scene && scene->IsKindOfClass(RUNTIME_CLASS(PlayerInfoScene)))
	{
		((PlayerInfoScene*)scene)->DrawRole(visible && !m_bagInfoShow, ccp(97, 181));
	}
}

void NewPlayerBagLayer::InitEquipItemList(int iEquipPos, Item* item)
{
	if (iEquipPos < Item::eEP_Begin || iEquipPos >= Item::eEP_End)
	{
		NDLog(@"玩家背包,装备列表初始化失败,装备位[%d]!!!", iEquipPos);
		return;
	}
	
	if (!m_cellinfoEquip[iEquipPos])
	{
		int iCellX = 5, iCellY = 13 , iXInterval = 4, iYInterval = 4;
		
		if(iEquipPos >= 0 && iEquipPos <= 3)
		{
			iCellX += (ITEM_CELL_W+iXInterval)*iEquipPos;
		}
		
		if(iEquipPos == 4 )
		{
			iCellY += (ITEM_CELL_H+iYInterval)*1;
		}
		
		if(iEquipPos == 5 )
		{
			iCellX += (ITEM_CELL_W+iXInterval)*3;
			iCellY += (ITEM_CELL_H+iYInterval)*1;
		}
		
		if(iEquipPos == 6 )
		{
			iCellY += (ITEM_CELL_H+iYInterval)*2;
		}
		
		if(iEquipPos == 7 )
		{
			iCellX += (ITEM_CELL_W+iXInterval)*3;
			iCellY += (ITEM_CELL_H+iYInterval)*2;
		}
		
		if (iEquipPos >= 8 && iEquipPos <= 15) 
		{
			iCellY += (ITEM_CELL_H+iYInterval)*3;
			
			iCellX += (ITEM_CELL_W+iXInterval)*((iEquipPos-8)%4);
			iCellY += (ITEM_CELL_H+iYInterval)*((iEquipPos-8)/4);
		}
		
		NDPicture *picDefaultItem = ItemImage::GetItem(GetIconIndexByEquipPos(iEquipPos), true);
		if (picDefaultItem)
		{
			picDefaultItem->SetColor(ccc4(215, 171, 108, 150));
			picDefaultItem->SetGrayState(true);
		}
		
		m_cellinfoEquip[iEquipPos] = new NDUIItemButton;
		m_cellinfoEquip[iEquipPos]->Initialization();
		m_cellinfoEquip[iEquipPos]->SetFrameRect(CGRectMake( iCellX+1, iCellY+1,ITEM_CELL_W-2, ITEM_CELL_H-2));
		m_cellinfoEquip[iEquipPos]->SetDelegate(this);
		m_cellinfoEquip[iEquipPos]->SetDefaultItemPicture(picDefaultItem);
		m_layerEquip->AddChild(m_cellinfoEquip[iEquipPos]);
	}
	
	m_cellinfoEquip[iEquipPos]->ChangeItem(item);
	
	m_cellinfoEquip[iEquipPos]->setBackDack(false);
	
	if (item) 
	{
		//roleequipok
		if (item->iAmount == 0) 
		{
			ItemMgrObj.SetRoleEuiptItemsOK(true, iEquipPos);
			m_cellinfoEquip[iEquipPos]->setBackDack(true);
			//T.roleEuiptItemsOK[i] = 1;
		}
		if (iEquipPos == Item::eEP_Ride) 
		{
			if (item->sAge == 0) 
			{
				//T.roleEuiptItemsOK[i] = 1;
				ItemMgrObj.SetRoleEuiptItemsOK(true, iEquipPos);
				m_cellinfoEquip[iEquipPos]->setBackDack(true);
			}
		}
	}
}

bool NewPlayerBagLayer::HasCompareEquipPosition(Item* otheritem)
{
	if (!otheritem) 
	{
		return false;
	}
	
	int comparePosition = getComparePosition(otheritem);
	if (   (comparePosition >= 0)
		&& (m_cellinfoEquip[comparePosition])
		&& (m_cellinfoEquip[comparePosition]->GetItem()) 
		) 
	{
		return true;
	}
	
	return false;
}

int NewPlayerBagLayer::getComparePosition(Item* item)
{
	if (!item)
	{
		return -1;
	}
	
	int type = Item::getIdRule(item->iItemType, Item::ITEM_TYPE);
	if (type != 0) { // 0装备,1宠物
		return -1;
	}
	
	int item_equip = Item::getIdRule(item->iItemType, Item::ITEM_EQUIP);
	int item_class = Item::getIdRule(item->iItemType, Item::ITEM_CLASS);
	
	// 0肩
	if ((type == 0) && (item_equip == 4) && (item_class == 2)) {
		return Item::eEP_Shoulder;
	}
	// 1头
	if ((type == 0) && (item_equip == 4) && (item_class == 1)) {
		return Item::eEP_Head;
	}
	// 2胸
	if ((type == 0) && (item_equip == 4) && (item_class == 3)) {
		return Item::eEP_Armor;
	}
	// 3项链
	if ((type == 0) && (item_equip == 5) && (item_class == 1)) {
		return Item::eEP_XianLian;
	}
	// 4耳环
	if ((type == 0) && (item_equip == 5) && (item_class == 2)) {
		return Item::eEP_ErHuan;
	}
	// 5腰带--披风
	if ((type == 0) && (item_equip == 4) && (item_class == 5)) {
		return Item::eEP_YaoDai;
	}
	// 6主武器
	if ((type == 0) && (item_equip == 1)) { // 双手
		return Item::eEP_MainArmor;
	}
	// 8副武
	if ((type == 0) && (item_equip == 3)) { // 盾牌或法器
		return Item::eEP_FuArmor;
	}
	
	if ((type == 0) && (item_equip == 2)) { // 特殊, 单手武器,可能在主手也可能在副手
		//if ((T.roleEuiptItems[6] != null)
		//			&& (T.roleEuiptItems[6].getItem() != null)) { // 主手优先比较
		//			return 6;
		//		} else if ((T.roleEuiptItems[8] != null)
		//				   && (T.roleEuiptItems[8].getItem() != null)) {// 副手有单手武器
		//			return 8;
		//		} else {
		//			return 6;
		//		}
		
		Item*  mainarmor = ItemMgrObj.GetEquipItemByPos(Item::eEP_MainArmor);
		Item*  fuarmor = ItemMgrObj.GetEquipItemByPos(Item::eEP_FuArmor);
		
		if (mainarmor) { // 主手优先比较
			return Item::eEP_MainArmor;
		} else if (fuarmor) {// 副手有单手武器
			return Item::eEP_FuArmor;
		} else {
			return Item::eEP_MainArmor;
		}
	}
	
	// 9徽记
	if ((type == 0) && (item_equip == 5) && (item_class == 3)) {
		return Item::eEP_HuiJi;
	}
	// 10手
	if ((type == 0) && (item_equip == 4) && (item_class == 4)) {
		return Item::eEP_Shou;
	}
	// 11宠物
	if ((type == 1) && (item_equip == 1)) {
		return Item::eEP_Decoration;
	}
	// 12护腿
	if ((type == 0) && (item_equip == 4) && (item_class == 6)) {
		return Item::eEP_HuTui;
	}
	// 14鞋子
	if ((type == 0) && (item_equip == 4) && (item_class == 7)) {
		return Item::eEP_Shoes;
	}
	// 15左戒指 16右戒指
	if ((type == 0) && (item_equip == 5) && (item_class == 4)) {
		return Item::eEP_LeftRing;
	}
	// 17坐骑
	if ((type == 1) && (item_equip == 2)) {
		return Item::eEP_RightRing;
	}
	
	return -1;
}

void NewPlayerBagLayer::notHasEquipItem(int iPos)
{
	if (iPos < Item::eEP_Begin || iPos >= Item::eEP_End)
	{
		return;
	}
	
	if (m_iShowType == NEW_SHOW_EQUIP_NORMAL)
	{
		/*
		if (m_tlPickEquip)
		{
			std::vector<std::string> vec_str;
			std::vector<int> vec_id;
			vec_str.push_back(std::string("无"));
			vec_id.push_back(-1);
			
			std::vector<Item*>bag = ItemMgrObj.GetPlayerBagItems();
			std::vector<Item*>::iterator it = bag.begin();
			for (; it != bag.end(); it++)
			{
				bool bOK = false;
				Item* item = *it;
				
				do 
				{
					int type = Item::getIdRule(item->iItemType, Item::ITEM_TYPE);
					if ((type != 0) && (type != 1)) { // 0装备,1宠物
						break;
					}
					int item_equip = Item::getIdRule(item->iItemType, Item::ITEM_EQUIP);
					int item_class = Item::getIdRule(item->iItemType, Item::ITEM_CLASS);
					
					switch (iPos) {
						case Item::eEP_Shoulder: {// 0肩
							if ((type == 0) && (item_equip == 4) && (item_class == 2)) {
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_Head: {// 1头
							if ((type == 0) && (item_equip == 4) && (item_class == 1)) {
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_Armor: {// 2胸
							if ((type == 0) && (item_equip == 4) && (item_class == 3)) {
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_XianLian: {// 3项链
							if ((type == 0) && (item_equip == 5) && (item_class == 1)) {
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_ErHuan: {// 4耳环
							if ((type == 0) && (item_equip == 5) && (item_class == 2)) {
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_YaoDai: {// 5腰带--披风
							if ((type == 0) && (item_equip == 4) && (item_class == 5)) {
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_MainArmor: {// 6主武器
							if ((type == 0) && ((item_equip == 1) || (item_equip == 2))) { // 单手或者双手
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_FuArmor: {// 8副武
							if ((type == 0) && ((item_equip == 2) || (item_equip == 3))) {// 副手或者单手
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_HuiJi: {// 9徽记
							if ((type == 0) && (item_equip == 5) && (item_class == 3)) {
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_Shou: {// 10手
							if ((type == 0) && (item_equip == 4) && (item_class == 4)) {
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_Pet: {// 11宠物
							if ((type == 1) && (item_equip == 1)) {
								bOK = true;
							}
							break;
						}
						case Item::eEP_HuTui: {// 12护腿
							if ((type == 0) && (item_equip == 4) && (item_class == 6)) {
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_Shoes: {// 14鞋子
							if ((type == 0) && (item_equip == 4) && (item_class == 7)) {
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_LeftRing:
						case Item::eEP_RightRing: {// 15左戒指 16右戒指
							if ((type == 0) && (item_equip == 5) && (item_class == 4)) {
								bOK = checkItemLimit(item, false);
							}
							break;
						}
						case Item::eEP_Ride: {// 17坐骑
							if ((type == 1) && (item_equip == 4)) {
								bOK = true;
							}
							break;
						}
					}
				} while (0);
				
				if (bOK)
				{
					vec_str.push_back(item->getItemNameWithAdd());
					vec_id.push_back(item->iID);
				}
			}
			
			//InitTLContentWithVecEquip(m_tlPickEquip, vec_str, vec_id);
		}
		*/
	}
}

void NewPlayerBagLayer::hasEquipItem(Item* item, int iPos)
{
	if (!item || (iPos < Item::eEP_Begin || iPos >= Item::eEP_End) )
	{
		return;
	}
	
	if (m_iShowType == NEW_SHOW_EQUIP_NORMAL)
	{
		std::stringstream sb;
		std::stringstream sb2;
		std::string title;
		std::string content;
		//NDBattlePet *petptr = NDPlayer::defaultHero().battlepet;
		//HeroPetInfo::PetData& pet = NDMapMgrObj.petInfo.m_data;
		if (item->isItemPet())// && petptr && petptr->m_id == pet.int_PET_ID)
		{
			//NDBattlePet& pet = *petptr;
			/*
			sb << (NDMapMgrObj.petInfo.str_PET_ATTR_NAME);
			sb << ("(");
			sb << (pet.int_PET_ATTR_LEVEL);
			sb << (")");
			sb << ('\n');
			title = sb.str();
			
			sb2 << NDCommonCString("PingZhi") << "：";
			int tempInt = pet.int_PET_ATTR_TYPE % 10;
			sb2 << NDItemType::PETPINZHI(tempInt) << '\n';
			sb2 << NDCommonCString("ShouMing") << "：" << pet.int_PET_ATTR_AGE << '\n';
			sb2 << NDCommonCString("HonestVal") << "：" << pet.int_PET_ATTR_LOYAL << '\n';
			if (pet.int_PET_ATTR_STR > 0) {
				sb2 << NDCommonCString("Liliang") << "：" << pet.int_PET_ATTR_STR << '\n';
			}
			if (pet.int_PET_ATTR_STA > 0) {
				sb2 << NDCommonCString("TiZhi") << "：" << pet.int_PET_ATTR_STA << '\n';
			}
			if (pet.int_PET_ATTR_AGI > 0) {
				sb2 << NDCommonCString("MingJie") << "：" << pet.int_PET_ATTR_AGI << '\n';
			}
			if (pet.int_PET_ATTR_INI > 0) {
				sb2 << NDCommonCString("ZhiLi") << "：" << pet.int_PET_ATTR_INI << '\n';
			}
			if (pet.int_PET_ATTR_PHY_ATK > 0) {
				sb2 << NDCommonCString("PhyAtkVal") << "：" << pet.int_PET_ATTR_PHY_ATK << '\n';
			}
			if (pet.int_PET_ATTR_MAG_ATK > 0) {
				sb2 << NDCommonCString("MagicAtkVal") << "：" << pet.int_PET_ATTR_MAG_ATK;
			}
			content = sb2.str();*/
		}
		else
		{
			title = item->getItemNameWithAdd();
			content = item->makeItemDes(false, true);
			// ChatRecordManager.parserChat(content, -1)
		}
		
		/*
		m_equipOPInfo.set(iPos, item);
		NDPlayerBagDialog *dlg = new NDPlayerBagDialog;
		dlg->Initialization(item->iID);
		dlg->SetDelegate(this);
		dlg->Show(title.c_str(), content.c_str(), "离开", "卸载", NULL);
		*/
	}
	else if (m_iShowType == NEW_SHOW_EQUIP_REPAIR)
	{
		m_equipOPInfo.set(iPos, item);
		
		std::vector<std::string> vec_str;
		if (item->isEquip())
		{
			vec_str.push_back(std::string(NDCommonCString("RepairCurEquip")));
		}
		vec_str.push_back(std::string(NDCommonCString("RepairAllEquip")));
		//InitTLContentWithVec(m_tlShare, vec_str);	
	}
}

std::string NewPlayerBagLayer::getRepairDesc(Item* item)
{
	if (!item)
	{
		return std::string("");
	}
	
	stringstream sb;
	
	int type = Item::getIdRule(item->iItemType,Item::ITEM_TYPE); // 物品类型
	if (type == 0) {// 装备
		int equipAllAmount = item->getAmount_limit();
		sb << (item->getItemNameWithAdd());
		if ((item->iAmount < equipAllAmount)
			&& (equipAllAmount > 1)) {
			int repairCharge = getEquipRepairCharge(item, 0);
			sb	<< " " << NDCommonCString("NaiJiuDu") << ": "
			<< Item::getdwAmountShow(item->iAmount)
			<< "/" << Item::getdwAmountShow(equipAllAmount)
			<< " " << NDCommonCString("RepairFee") << ":" << repairCharge;
		} else if (equipAllAmount == 0) {
			sb << (NDCommonCString("NoNeedRepair"));
		} else {
			sb	<< " " << NDCommonCString("NaiJiuDu") << ": "
			<< Item::getdwAmountShow(item->iAmount)
			<< "/" << Item::getdwAmountShow(equipAllAmount)
			<< " " << NDCommonCString("NoNeedRepair");
		}
	} else {
		sb << (item->getItemName());
		if (item->iAmount > 1) {
			sb << (item->iAmount);
		}
		sb << NDCommonCString("CantRepair");
	}
	return std::string(sb.str());
}


int NewPlayerBagLayer::getEquipRepairCharge(Item* item, int type)
{
	switch (type) {
		case 0: {
			
			if (!item ) {
				return 0;
			}
			
			int equipAllAmount = item->getAmount_limit();
			int equipPrice = item->getPrice();
			if ((item->iAmount < equipAllAmount) && (equipAllAmount > 1)) {
				return repairEveryMoney(equipPrice, item->iAmount,
										equipAllAmount);
			}
			return 0;
		}
		case 1: {
			int sumRepair = 0;
			for (int i = Item::eEP_Begin; i < Item::eEP_End; i++)
			{
				if (!m_cellinfoEquip[i] || !m_cellinfoEquip[i]->GetItem())
				{
					continue;
				}
				
				Item *tempItem = m_cellinfoEquip[i]->GetItem();
				if (tempItem && tempItem->isEquip() && !tempItem->isRidePet() && i != Item::eEP_Ride) {// 装备
					int equipAllAmount = tempItem->getAmount_limit();
					int equipPrice = tempItem->getPrice();
					
					if ((tempItem->iAmount < equipAllAmount)
						&& (equipAllAmount > 1)) {
						sumRepair += repairEveryMoney(equipPrice,
													  tempItem->iAmount, equipAllAmount);
					}
				}
			}
			
			return sumRepair;
		}
	}
	return 0;
}

int NewPlayerBagLayer::repairEveryMoney(int equipPrice, int dwAmount,int equipAllAmount)
{
	double repairMoney = double(equipPrice
								* ((double)3333333333.0 - (double)dwAmount * (double)10000000000.0 / (equipAllAmount * 3))
								/ (double)10000000000.0);
	return (int) (repairMoney) + 1; // 取整+1
}

bool NewPlayerBagLayer::checkItemLimit(Item* item, bool isShow)
{
	if (!item)
	{
		return false;
	}
	
	stringstream sb;
	NDPlayer &player = NDPlayer::defaultHero();
	int levelLimit = item->getReq_level(); // 等级限制
	int selfLimit = player.level;
	if (selfLimit < levelLimit) {
		sb << NDCommonCString("LevelRequire") << levelLimit << "(" << NDCommonCString("current") << selfLimit << ")\n";
	}
	
	int req_phy = item->getReq_phy(); // 力量限制
	int self_phy = player.phyPoint;
	if (self_phy < req_phy) {
		sb <<  NDCommonCString("LiLiangXuQiu") << req_phy << "(" << NDCommonCString("current") << self_phy << ")\n";
	}
	int req_dex = item->getReq_dex(); // 敏捷限制
	int self_dex = player.dexPoint;
	if (self_dex < req_dex) {
		sb << NDCommonCString("MingJieXuQiu") << req_dex << "(" << NDCommonCString("current") << self_dex << ")\n";
	}
	
	int req_mag = item->getReq_mag(); // 智力限制
	int self_mag = player.magPoint;
	if (self_mag < req_mag) {
		sb << NDCommonCString("ZhiLiXuQiu") << req_mag << "(" << NDCommonCString("current") << self_mag << ")\n";
	}
	
	int req_def = item->getReq_def(); // 体质限制
	int self_def = player.defPoint;
	if (self_def < req_def) {
		sb << NDCommonCString("TiZhiXuQiu") << req_def << "(" << NDCommonCString("current") << self_def << ")";
	}
	
	std::string str = sb.str();
	if (!str.empty()) {
		if (isShow) {
			NDUIDialog *dlg = new NDUIDialog;
			dlg->Initialization();
			dlg->Show(NDCommonCString("NoUpToEquip"), str.c_str(), NULL, NULL);
		}
		return false;
	}
	
	return true;
}

void NewPlayerBagLayer::repairItem(Item* item)
{
	if (!item)
	{
		return;
	}
	
	if (item->isRidePet())
	{
		showDialog(NDCommonCString("WenXinTip"), NDCommonCString("QiChongCantRepaire"));
	} else {
		int sumRepair = getEquipRepairCharge(item, 0);
		if (sumRepair == 0) {
			showDialog(NDCommonCString("WenXinTip"), NDCommonCString("EquipNoNeedRepair"));
		} else {
			if (sumRepair > NDPlayer::defaultHero().money) {
				stringstream ss; ss << NDCommonCString("RepairEquipFee") << sumRepair << "," << NDCommonCString("CantRepairEquipMoney");
				showDialog(NDCommonCString("WenXinTip"), ss.str().c_str());
			} else {
				sendItemRepair(item->iID, Item::_ITEMACT_REPAIR);
			}
		}
	}
}

void NewPlayerBagLayer::repairAllItem()
{
	int sumRepair = getEquipRepairCharge(NULL, 1);
	
	if (sumRepair == 0) {
		showDialog(NDCommonCString("WenXinTip"), NDCommonCString("AllEquipNoNeedRepair"));
	} else {
		if (sumRepair > NDPlayer::defaultHero().money) {
			stringstream ss; ss << NDCommonCString("AllEquipRepairFee") << sumRepair << NDCommonCString("CantRepairAllEquipMoney");
			showDialog(NDCommonCString("WenXinTip"), ss.str().c_str());
		} else {
			stringstream ss; ss << NDCommonCString("RepairAllEquipMoney") << " " << sumRepair << " " << NDCommonCString("RepairAllEquipMoneyTip");
			/*
			NDPlayerBagDialog *dlg = new NDPlayerBagDialog;
			dlg->Initialization(PlayerBagDialog_Reapir);
			dlg->SetDelegate(this);
			dlg->Show(NDCommonCString("WenXinTip"), ss.str().c_str(), NDCommonCString("Cancel"), NDCommonCString("Ok"), NULL);
			*/
		}
	}
}

void NewPlayerBagLayer::DropOperate(Item* item)
{
	m_bagOPInfo.item = item;
	
	if (!item) return;
	
	if (m_bagOPInfo.item->isItemDropReminder())
	{
		m_bagOPInfo.operate = bag_cell_info::e_op_drop;
		
		NDUIDialog *dlg = new NDUIDialog;
		dlg->Initialization();
		dlg->SetTag(m_bagOPInfo.item->iID);
		dlg->SetDelegate(this);
		dlg->Show(NDCommonCString("drop"), NDCommonCString("DropTip"), NDCommonCString("Cancel"), NDCommonCString("Ok"), NULL);
	}
	else 
	{
		sendDropItem(*(m_bagOPInfo.item));
	}
}

void NewPlayerBagLayer::ShowBagInfo(bool show)
{
	if (m_bagInfo) 
	{
		m_bagInfo->SetVisible(show);
		m_bagInfoShow = show;
	}
	
	NDScene* scene = NDDirector::DefaultDirector()->GetRunningScene();
	if (scene && scene->IsKindOfClass(RUNTIME_CLASS(PlayerInfoScene)))
	{
		((PlayerInfoScene*)scene)->DrawRole(!show, ccp(97, 181));
	}
}

int NewPlayerBagLayer::GetIconIndexByEquipPos(int pos)
{
	int index = -1;
	switch (pos) {
		case Item::eEP_Shoulder:
			index = 2+5*6;
			break;
		case Item::eEP_Head:
			index = 5*6;
			break;
		case Item::eEP_XianLian:
			index = 3+6;
			break;
		case Item::eEP_ErHuan:
			index = 6;
			break;
		case Item::eEP_Armor:
			index = 1+5*6;
			break;
		case Item::eEP_YaoDai:
			index = 5+5*6;
			break;
		case Item::eEP_MainArmor:
			index = 0;
			break;
		case Item::eEP_FuArmor:
			index = 5;
			break;
		case Item::eEP_Shou:
			index = 3+5*6;
			break;
		case Item::eEP_HuTui:
			index = 4+5*6;
			break;
		case Item::eEP_LeftRing:
			index = 2+6;
			break;
		case Item::eEP_RightRing:
			index = 2+6;
			break;
		case Item::eEP_HuiJi:
			index = 1+6;
			break;
		case Item::eEP_Shoes:
			index = 6*6;
			break;
		case Item::eEP_Decoration:
			index = 1+1*6;
			break;
		case Item::eEP_Ride:
			index = 1+3*6;
			break;
		default:
			break;
	}
	
	return index;
}

////////////////////////////////////////////////////////
IMPLEMENT_CLASS(BagItemInfo, NDUILayer)

BagItemInfo::BagItemInfo()
{
	m_btnItem = NULL;
	
	m_btnClose = NULL;
	
	m_uiOpMaxCols = 3;
	
	m_lbItemName = NULL;
	
	m_lbItemLvl = NULL;
	
	m_lslText = NULL;
}

BagItemInfo::~BagItemInfo()
{
	for_vec(m_vOpBtn, vec_btn_it)
	{
		NDUIButton*& btn = *it;
		
		if (btn && btn->GetParent() == NULL) 
		{
			delete btn;
		}
	}
	
	m_vOpBtn.clear();
}

void BagItemInfo::Initialization()
{
	NDUILayer::Initialization();
	
	this->SwallowDragInEvent(true);
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	NDPicture* picBagLeftBg = pool.AddPicture(GetImgPathNew("bag_left_bg.png"));
	
	CGSize sizeBagLeftBg = picBagLeftBg->GetSize();
	
	this->SetBackgroundImage(picBagLeftBg, true);
		
	m_btnItem = new NDUIItemButton;
	m_btnItem->Initialization();
	m_btnItem->SetFrameRect(CGRectMake( 17, 11,ITEM_CELL_W, ITEM_CELL_H));
	m_btnItem->SetDelegate(this);
	this->AddChild(m_btnItem);
	
	m_lbItemName = new NDUILabel;
	m_lbItemName->Initialization();
	m_lbItemName->SetFontSize(18);
	m_lbItemName->SetFontColor(ccc4(136, 41, 41, 255));
	m_lbItemName->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbItemName->SetFrameRect(CGRectMake(71, 13, sizeBagLeftBg.width, sizeBagLeftBg.height));
	this->AddChild(m_lbItemName);
	
	m_lbItemLvl = new NDUILabel;
	m_lbItemLvl->Initialization();
	m_lbItemLvl->SetFontSize(14);
	m_lbItemLvl->SetFontColor(ccc4(136, 41, 41, 255));
	m_lbItemLvl->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbItemLvl->SetFrameRect(CGRectMake(71, 39, sizeBagLeftBg.width, sizeBagLeftBg.height));
	this->AddChild(m_lbItemLvl);
	
	m_lslText = new NDUILabelScrollLayer;
	m_lslText->Initialization();
	m_lslText->SetFrameRect(CGRectMake(17, 70, (sizeBagLeftBg.width-34), 120));
	this->AddChild(m_lslText);
	
	NDPicture *picCut = pool.AddPicture(GetImgPathNew("bag_left_fengge.png"));
	
	CGSize sizeCut = picCut->GetSize();
	
	NDUIImage* imageCut = new NDUIImage;
	
	imageCut->Initialization();
	
	imageCut->SetPicture(picCut, true);
	
	imageCut->SetFrameRect(CGRectMake((sizeBagLeftBg.width-sizeCut.width)/2, 65, sizeCut.width, sizeCut.height));
	
	imageCut->EnableEvent(false);
	
	this->AddChild(imageCut);
	
	picCut = pool.AddPicture(GetImgPathNew("bag_left_fengge.png"));
	
	imageCut = new NDUIImage;
	
	imageCut->Initialization();
	
	imageCut->SetPicture(picCut, true);
	
	imageCut->SetFrameRect(CGRectMake((sizeBagLeftBg.width-sizeCut.width)/2, 194, sizeCut.width, sizeCut.height));
	
	imageCut->EnableEvent(false);
	
	this->AddChild(imageCut);
	
	
	NDPicture *picClose = pool.AddPicture(GetImgPathNew("bag_left_close.png"));
	
	CGSize sizeClose = picClose->GetSize();
	
	m_btnClose = new NDUIButton;
	
	m_btnClose->Initialization();
	
	m_btnClose->SetFrameRect(CGRectMake(0, 206, sizeClose.width, sizeClose.height));
	
	//m_btnClose->SetTitle("关闭");
	
	m_btnClose->SetImage(picClose, false, CGRectZero, true);
	
	m_btnClose->SetDelegate(this);
	
	this->AddChild(m_btnClose);
}

void BagItemInfo::ChangItem(Item* item, bool onlylook/*=false*/)
{
	m_btnItem->ChangeItem(item);
	
	if (item == NULL) 
	{
		this->SetVisible(false);
		
		return;
	}
	
	refreshLabel(*item);
	
	refreshOperate(item, onlylook);
}

void BagItemInfo::OnButtonClick(NDUIButton* button)
{
	if (button == m_btnItem) 
	{
		return;
	}
	else if (button == m_btnClose) 
	{
		if (this->GetParent() && this->GetParent()->IsKindOfClass(RUNTIME_CLASS(NewPlayerBagLayer))) 
		{ 
			NewPlayerBagLayer *parent = (NewPlayerBagLayer*)(this->GetParent());
			parent->ShowBagInfo(false);
		}
	}
	else if (m_btnItem->GetItem() != NULL)
	{
		int op = button->GetTag();
		
		if (op < BagItemOperate_Begin || op >= BagItemOperate_End) 
		{
			return;
		}
		
		BagItemInfoDelegate *delegate = dynamic_cast<BagItemInfoDelegate*> (this->GetDelegate());
		
		if (delegate)
			delegate->OnBagItemInfoOperate(this, m_btnItem->GetItem(), BagItemOperate(op));
	}
}

void BagItemInfo::refreshLabel(Item& item)
{
	m_lbItemName->SetText(item.getItemNameWithAdd().c_str());
	
	std::stringstream ss;
	ss << NDCommonCString("LevelRequire") << " : " << int(item.getReq_level()) << NDCommonCString("Ji");
	
	m_lbItemLvl->SetText(ss.str().c_str());
	
	
	std::string desc;// = "描述 : \n\n";
	
	desc += item.makeItemDes(false, true);
	
	if (m_lslText) 
		m_lslText->SetText(desc.c_str());
}

void BagItemInfo::refreshOperate(Item* item, bool onlylook/*=false*/)
{
	if (!item) return;
	
	std::vector<std::string> vec_str;
	std::vector<BagItemOperate> vec_op;
	std::string temp;
	BagItemOperate tempOp;

	if (!onlylook)
	{
		if ((!item->isEquip() || item->isItemPet()) && item->isItemCanUse() && !(item->IsPetUseItem())) {
			temp = NDCommonCString("use");
			tempOp = BagItemOperate_Use;
		}
		// 技能书或配方
		if (item->isSkillBook()
			|| (item->isFormulaExt() && temp == NDCommonCString("use"))) {
			
			if (!item->IsPetUseItem())
			{
				temp = NDCommonCString("learn");
				tempOp = BagItemOperate_Learn;
			}
		}
		
		if (item->isFormula() || item->isItemPet() || item->isSkillBook())
		{
			vec_str.push_back(std::string(NDCommonCString("ChaKang")));
			vec_op.push_back(BagItemOperate_ChaKang);
		} 
		
		if (item->canInlay()) {
			vec_str.push_back(std::string(NDCommonCString("XiangQian")));
			vec_op.push_back(BagItemOperate_Inlay);
		}
		if (item->iItemType == Item::REVERT && item->active == false) {
			vec_str.push_back(std::string(NDCommonCString("JiHuo")));
			vec_op.push_back(BagItemOperate_Active);
		}
		if (!temp.empty()) {
			vec_str.push_back(temp);
			vec_op.push_back(tempOp);
		}
		// 装备
		//if (isCampMark(item.itemType)) {
		//			opsA.addElement(zhuangBei);
		//		} else
		{
			if (item->isEquip() && this->GetParent() && this->GetParent()->IsKindOfClass(RUNTIME_CLASS(NewPlayerBagLayer))) { // 装备
				NewPlayerBagLayer *parent = (NewPlayerBagLayer*)(this->GetParent());
				if (parent->HasCompareEquipPosition(item))
				{
					vec_str.push_back(std::string(NDCommonCString("compare"))); // 与身上装备比较
					vec_op.push_back(BagItemOperate_Compare);
				}
			}
		}
		
		if(item->byBindState != BIND_STATE_BIND && 
		   (item->isEquip()
			|| item->isRidePet()
			||item->isItemPet())
		   )
		{
			vec_str.push_back(std::string(NDCommonCString("bind"))); // 永久绑定
			vec_op.push_back(BagItemOperate_Bind);
		}
		
		//opsA.addElement(yidongT);
		vec_str.push_back(std::string(NDCommonCString("drop")));
		vec_op.push_back(BagItemOperate_Drop);
		
		// 可叠加物品
		if (item->canChaiFen() && !item->isRidePet())
		{
			vec_str.push_back(std::string(NDCommonCString("caifeng")));
			vec_op.push_back(BagItemOperate_CaiFeng);
		}
		
		// 可出售
		if (item->getEmoney()<=0 && item->getPrice()>0 && item->isItemCanSale()) {
			vec_str.push_back(std::string(NDCommonCString("RemoteSale")));
			vec_op.push_back(BagItemOperate_chuShou);
		}
	}
	else
	{
		if (item->isFormula() || item->isItemPet() || item->isSkillBook())
		{
			vec_str.push_back(std::string(NDCommonCString("ChaKang")));
			vec_op.push_back(BagItemOperate_ChaKang);
		} 
	}
	
	size_t sizeOperate = vec_op.size();
	
	if (sizeOperate != vec_str.size()) 
	{
		return;
	}
	
	size_t sizeBtns = m_vOpBtn.size();
	
	size_t max = sizeBtns;
	
	if (sizeOperate > sizeBtns) 
	{
		m_vOpBtn.resize(sizeOperate, NULL);
		
		max = sizeOperate;
	}
	
	int startx = 36, starty = 201, btnw = 48, btnh = 24, interval = 5;
	
	for (size_t i = 0; i < max; i++) 
	{
		NDUIButton*& btn = m_vOpBtn[i];
		if (!btn) 
		{
			NDPicturePool& pool = *(NDPicturePool::DefaultPool());
			btn = new NDUIButton;
			
			btn->Initialization();
			
			btn->SetFrameRect(CGRectMake(startx+(btnw+interval)*(i%m_uiOpMaxCols),
										 starty+(btnh+interval)*(i/m_uiOpMaxCols), 
										 btnw, 
										 btnh));
			btn->SetFontColor(ccc4(255, 255, 255, 255));
			
			btn->SetFontSize(12);
			
			btn->CloseFrame();
			
			btn->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("bag_btn_normal.png")),
									  pool.AddPicture(GetImgPathNew("bag_btn_click.png")),
									  false, CGRectZero, true);
			btn->SetDelegate(this);							 
			
			this->AddChild(btn);
		}
		
		if (i >= sizeOperate) 
		{
			btn->SetTitle("");
			
			btn->SetTag(BagItemOperate_End);
			
			if (btn->GetParent() != NULL) 
			{
				btn->RemoveFromParent(false);
			}
			
			continue;
		}
		
		if (btn->GetParent() == NULL) 
		{
			this->AddChild(btn);
		}
		
		//NDLog(@"%@", [NSString stringWithUTF8String:vec_str[i].c_str()]);
		
		btn->SetTag(vec_op[i]);
		
		btn->SetTitle(vec_str[i].c_str());
	}
}
