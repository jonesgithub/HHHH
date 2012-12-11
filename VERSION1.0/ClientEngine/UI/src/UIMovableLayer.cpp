/*
 *  UIMovableLayer.mm
 *  SMYS
 *
 *  Created by jhzheng on 12-2-10.
 *  Copyright 2012 (网龙)DeNA. All rights reserved.
 *
 */

#include "UIMovableLayer.h"

IMPLEMENT_CLASS(CUIMovableLayer, NDUILayer)

CUIMovableLayer::CUIMovableLayer()
{
}

CUIMovableLayer::~CUIMovableLayer()
{
}

void CUIMovableLayer::Initialization()
{
	NDUILayer::Initialization();
	
	this->SetDelegate(this);
	
	this->SetScrollEnabled(true);
	
	this->SetMoveOutListener(true);
}

bool CUIMovableLayer::TouchEnd(NDTouch* touch)
{
	if (!this->IsVisibled()) return false;

	bool bRet = NDUILayer::TouchEnd(touch);
	
	if (!bRet)
	{
		OnMoveStop();
	}
	
	return bRet;
}

void CUIMovableLayer::SetMovableViewer(NDCommonProtocol* viewer)
{
	this->AddViewer(viewer);
}

bool CUIMovableLayer::CanHorizontalMove(float& hDistance)
{
	bool bCanHorizontalMove = true;
	
	// 设置的观察者过滤一次
	LIST_COMMON_VIEWER_IT it = m_listCommonViewer.begin();
	for (; it != m_listCommonViewer.end(); it++) 
	{
		if ( !(*it).IsValid() )
		{
			continue;
		}
		
		if (bCanHorizontalMove)
		{
			bCanHorizontalMove	= (*it)->CanHorizontalMove(this, hDistance);
		}
	}
	
	return bCanHorizontalMove;
}

bool CUIMovableLayer::CanVerticalMove(float& vDistance)
{
	bool bCanVerticalMove = true;
	
	// 设置的观察者过滤一次
	LIST_COMMON_VIEWER_IT it = m_listCommonViewer.begin();
	for (; it != m_listCommonViewer.end(); it++) 
	{
		if ( !(*it).IsValid() )
		{
			continue;
		}
		
		if (bCanVerticalMove)
		{
			bCanVerticalMove	= (*it)->CanVerticalMove(this, vDistance);
		}
	}
	
	return bCanVerticalMove;
}

bool CUIMovableLayer::OnLayerMoveOfDistance(NDUILayer* uiLayer, float hDistance, float vDistance)
{
	if (uiLayer != this)
	{
		return false;
	}
	
	bool bCanHorizontalMove = CanHorizontalMove(hDistance);
	bool bCanVerticalMove	= CanVerticalMove(vDistance);
	
	if (!bCanHorizontalMove && !bCanVerticalMove)
	{
		return true;
	}
	
	CCRect rect = this->GetFrameRect();
	
	bool modify = false;
	
	if (bCanHorizontalMove)
	{
		if (OnHorizontalMove(hDistance))
		{
			rect.origin.x += hDistance;
			modify = true;
		}
	}
	
	if (bCanVerticalMove)
	{
		if (OnVerticalMove(vDistance))
		{
			rect.origin.y += vDistance;
			modify = true;
		}
	}
	
	if (bCanHorizontalMove || bCanVerticalMove)
	{
		if (modify)
		{
			this->SetFrameRect(rect);
		}
	}
	
	return true;
}