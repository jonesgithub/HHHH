/*
 *  NewPaiHangScene.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-8-31.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "NewPaiHangScene.h"
#include "NDDirector.h"
#include "CGPointExtension.h"
#include "NDUtility.h"
#include "NDMsgDefine.h"
#include "NDUISynLayer.h"
#include "NDCommonControl.h"


IMPLEMENT_CLASS(NewPaiHangScene, NDCommonScene)

NewPaiHangScene* NewPaiHangScene::Scene(const std::vector<std::string>& vec_str, const std::vector<int>& vec_id)
{
	NewPaiHangScene *scene = new NewPaiHangScene;
	
	scene->Initialization(vec_str, vec_id);
	
	return scene;
}

NewPaiHangScene::NewPaiHangScene()
{
}

NewPaiHangScene::~NewPaiHangScene()
{
	s_PaiHangTitle.clear();
	values.clear();
}

void NewPaiHangScene::Initialization(const std::vector<std::string>& vec_str, const std::vector<int>& vec_id)
{
	CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
	
	unsigned int size = vec_str.size();
	
	float maxTitleLen = 0.0f;
	for(unsigned int i = 0; i < size; i++) 
	{
		CGSize textSize = getStringSize(vec_str[i].c_str(), 18);
		
		if (textSize.width > maxTitleLen)
			maxTitleLen = textSize.width;
	}
	
	maxTitleLen += 36;
	
	int iW = winsize.width-(7+42+m_uiTabInterval)-(7+42);
	
	m_tabNodeSize = CGSizeMake(maxTitleLen, 34);

	NDCommonScene::Initialization(true, iW / (maxTitleLen+m_uiTabInterval));
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	NDUILayer* commonLayer = this->CetGernalLayer(false);
	
	NDFuncTab *tab = new NDFuncTab;
	tab->Initialization(1, ccp(0.0f, 2.0f), CGSizeMake(25, 63), 0, 0, true);
	TabNode* tabnode = tab->GetTabNode(0);
	
	NDPicture *pic = NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("newui_text.png"));
	NDPicture *picFocus = NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("newui_text.png"));
	
	int startX = 18*16;;
	
	pic->Cut(CGRectMake(startX, 36, 18, 36));
	picFocus->Cut(CGRectMake(startX, 0, 18, 36));
	
	tabnode->SetTextPicture(pic, picFocus);
	commonLayer->AddChild(tab);
	
	for (unsigned int i = 0; i < size; i++) 
	{
		TabNode* tabnode = this->AddTabNode();
		
		tabnode->SetImage(pool.AddPicture(GetImgPathNew("newui_tab_unsel.png"), maxTitleLen, 31), 
						  pool.AddPicture(GetImgPathNew("newui_tab_sel.png"), maxTitleLen, 34),
						  pool.AddPicture(GetImgPathNew("newui_tab_selarrow.png")));
		
		tabnode->SetText(vec_str[i].c_str());
		
		tabnode->SetTextColor(ccc4(245, 226, 169, 255));
		
		tabnode->SetFocusColor(ccc4(173, 70, 25, 255));
		
		tabnode->SetTextFontSize(18);
		
		tabnode->SetTag(vec_id[i]);
		
		NDUIClientLayer *client = this->GetClientLayer(i);
		
		m_vLabels.push_back(VEC_LABEL());
		
		VEC_LABEL& vLabel = m_vLabels.back();
		
		for (int i = 0; i < MAX_LABEL_COUNT; i++) 
		{
			NDUILabel *lb = new NDUILabel;
			lb->Initialization();
			lb->SetTextAlignment(LabelTextAlignmentCenter);
			lb->SetFontSize(18);
			lb->SetFontColor(ccc4(255, 0, 0, 255));
			client->AddChild(lb);
			vLabel.push_back(lb);
		}
		
		NDUITableLayer *tl = new NDUITableLayer;
		
		tl->Initialization();
		tl->SetBackgroundColor(ccc4(0, 0, 0, 0));
		tl->VisibleSectionTitles(false);
		tl->SetFrameRect(CGRectMake(7, 56-37+20, 439-7, 264-(56-37)-20));
		tl->VisibleScrollBar(false);
		tl->SetCellsInterval(4);
		tl->SetCellsRightDistance(0);
		tl->SetCellsLeftDistance(0);
		tl->SetDelegate(this);
		tl->SetTag(vec_id[i]);
		
		NDDataSource *dataSource = new NDDataSource;
		NDSection *section = new NDSection;
		section->UseCellHeight(true);
		
		dataSource->AddSection(section);
		tl->SetDataSource(dataSource);
		
		client->AddChild(tl);
		
		m_vTable.push_back(tl);
	}
	
	this->SetTabFocusOnIndex(0, true);
}

void NewPaiHangScene::OnButtonClick(NDUIButton* button)
{
	if (OnBaseButtonClick(button)) return;
}

void NewPaiHangScene::OnTabLayerSelect(TabLayer* tab, unsigned int lastIndex, unsigned int curIndex)
{
	NDCommonScene::OnTabLayerSelect(tab, lastIndex, curIndex);
	
	GetTabData(tab, curIndex);
}

void NewPaiHangScene::OnTabLayerNextPage(TabLayer* tab, unsigned int lastPage, unsigned int nextPage)
{
	NDCommonScene::OnTabLayerNextPage(tab, lastPage, nextPage);
}

void NewPaiHangScene::GetTabData(TabLayer* tab, unsigned int index)
{
	if (!tab) return;
	
	TabNode* tabnode = tab->GetTabNode(index);

	if (!tabnode) return;
	
	int tag = tabnode->GetTag();
	
	std::map<int,std::vector<std::string> >::iterator it = values.find(tag);
	
	if (it != values.end())
	{ 
		refreshCurTable();
		return;
	}
	
	NDTransData bao(_MSG_BILLBOARD);
	bao << tag << int(-1);
	SEND_DATA(bao);
}

void NewPaiHangScene::refreshTable(NDUITableLayer* tl)
{
	if (!tl
		|| !tl->GetDataSource()
		|| tl->GetDataSource()->Count() != 1)
		return;
		
	int tag = tl->GetTag();
	
	std::vector<int>& fildTypes = s_PaiHangTitle[tag].fildTypes;
	
	std::map<int,std::vector<std::string> >::iterator it = values.find(tag);
	
	if (it == values.end()) return;
	
	std::vector<std::string> vec_str = it->second;
	
	if (vec_str.size()%fildTypes.size() != size_t(0)) return;
	
	unsigned int columnCount = fildTypes.size();
	
	if (columnCount == 0) return;
	
	unsigned int recordCount = vec_str.size()/columnCount;
	
	NDSection* section = tl->GetDataSource()->Section(0);
	
	size_t maxCount = section->Count() > recordCount ? section->Count() : recordCount;
	
	unsigned int infoCount = 0;
	
	for (size_t i = 0; i < maxCount; i++) 
	{
		size_t indexStr = i * columnCount;
		
		std::string strKey = indexStr < vec_str.size() ? vec_str[indexStr] : "";
		std::string strValue = (indexStr+1) < vec_str.size() ? vec_str[indexStr+1] : "";
		
		if (!(strKey == "" || strValue == ""))
		{
			PaiHangCell *cell = NULL;
			if (infoCount < section->Count())
				cell = (PaiHangCell *)section->Cell(infoCount);
			else
			{
				cell = new PaiHangCell;
				cell->Initialization();
				section->AddCell(cell);
			}
			
			if (cell->GetKeyText())
				cell->GetKeyText()->SetText(strKey.c_str());
				
			if (cell->GetValueText())
				cell->GetValueText()->SetText(strValue.c_str());
			
			cell->SetOrder(infoCount+1);
			
			infoCount++;
		}
		else
		{
			if (infoCount < section->Count() && section->Count() > 0)
			{
				section->RemoveCell(section->Count()-1);
			}
		}
	}
	
	tl->ReflashData();
}

void NewPaiHangScene::refreshTitle(VEC_LABEL& vLabel, int iPaiHangId)
{
	std::vector<std::string>& fildNames = s_PaiHangTitle[iPaiHangId].fildNames;
	
	size_t sizefield = fildNames.size();
	
	if (sizefield <= 0)
	{
		for (VEC_LABEL::iterator it = vLabel.begin(); 
			 it != vLabel.end();
			 it++) 
		{
			(*it)->SetText("");
		}
		return;
	}
	
	unsigned int lbStartX	= 10;
	unsigned int lbStartY	= 56-37+20 - 25;
	unsigned int lbW		= (439-13) / sizefield;
	unsigned int lbH		= 20;

	size_t sizelabel = vLabel.size();
	
	for (size_t i = 0; i < sizefield; i++) 
	{
		std::string name;
		
		if (i < MAX_LABEL_COUNT)
		{
			name = fildNames[i];
		}
		
		if (i < sizelabel)
		{
			NDUILabel*& lb = vLabel[i];
			lb->SetText(name.c_str());
			lb->SetFrameRect(CGRectMake(lbStartX + lbW * i, 
										lbStartY, 
										lbW, lbH));
		}
	}
}

void NewPaiHangScene::refreshCurTable()
{
	if (!m_tab) return;
	
	unsigned int focusIndex = m_tab->GetFocusIndex();
	
	if (focusIndex > m_vTable.size())
		return;
	
	refreshTable(m_vTable[focusIndex]);
	
	if (focusIndex < m_vLabels.size())
		refreshTitle(m_vLabels[focusIndex], m_vTable[focusIndex]->GetTag());
}

void NewPaiHangScene::refresh()
{
	NDScene* scene = NDDirector::DefaultDirector()->GetRunningScene();
	
	if (!scene->IsKindOfClass(RUNTIME_CLASS(NewPaiHangScene))) return;
	
	((NewPaiHangScene*)scene)->refreshCurTable();
}

//std::vector<int> NewPaiHangScene::fildTypes;
//std::vector<std::string> NewPaiHangScene::fildNames;
std::map<int, PaiHangTitle> NewPaiHangScene::s_PaiHangTitle;
int NewPaiHangScene::curPaiHangType = 0;
int NewPaiHangScene::itype = 0;
int NewPaiHangScene::totalPages = 0;
std::map<int,std::vector<std::string> > NewPaiHangScene::values;

