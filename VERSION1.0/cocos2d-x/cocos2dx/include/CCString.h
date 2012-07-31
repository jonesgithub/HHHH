/****************************************************************************
Copyright (c) 2010 cocos2d-x.org

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
#ifndef __CCSTRING_H__
#define __CCSTRING_H__
#include <string>
#include <stdlib.h>
#include "CCObject.h"
#include "CCFileUtils.h"
#include "..\platform\third_party\win32\iconv\iconv.h"

namespace cocos2d {

	class CC_DLL CCString : public CCObject
	{
	public:
		std::string m_sString;
	public:
		CCString()
			:m_sString("")
		{}
		CCString(const char * str)
		{
			m_sString = str;
		}
		virtual ~CCString(){ m_sString.clear(); }

		/***
		* @brief 返回转换成UTF8格式的字符
		*
		* @return const unsigned char* 返回UTF8指针
		* @retval 0 空指针即为无法转换
		* @author (DeNA)郭浩
		* @date 20120731
		*/
		const char* UTF8String()
		{
			iconv_t pConvert = 0;
			const char* pszInbuffer = m_sString.c_str();
			char* pszOutBuffer = new char[2048];

			memset(pszOutBuffer,0,sizeof(char) * 2048);

			int nStatus = 0;
			size_t sizOutBuffer = 2048;
			size_t sizInBuffer = m_sString.length();
			const char* pszInPtr = pszInbuffer;
			size_t sizInSize = sizInBuffer;
			char* pszOutPtr = pszOutBuffer;
			size_t sizOutSize = sizOutBuffer;

			pConvert = iconv_open("UTF-8","GB2312");

			iconv(pConvert,0,0,0,0);

			while (0 < sizInSize)
			{
				size_t sizRes = iconv(pConvert,(const char**)&pszInPtr,
					&sizInSize,&pszOutPtr,&sizOutSize);

				if (pszOutPtr != pszOutBuffer)
				{
					strncpy(pszOutBuffer,pszOutBuffer,sizOutSize);
				}

				if ((size_t)-1 == sizRes)
				{
					int nOne = 1;
					iconvctl(pConvert,ICONV_SET_DISCARD_ILSEQ,&nOne);
				}
			}

			iconv_close(pConvert);

			return pszOutBuffer;
		}
		
		int toInt()
		{
			return atoi(m_sString.c_str());
		}
		unsigned int toUInt()
		{
			return (unsigned int)atoi(m_sString.c_str());
		}
		float toFloat()
		{
			return (float)atof(m_sString.c_str());
		}
		std::string toStdString()
		{
			return m_sString;
		}

		bool isEmpty()
		{
			return m_sString.empty();
		}

        virtual bool isEqual(const CCObject* pObject)
        {
            bool bRet = false;
            const CCString* pStr = dynamic_cast<const CCString*>(pObject);
            if (pStr != NULL)
            {
                if (0 == m_sString.compare(pStr->m_sString))
                {
                    bRet = true;
                }
            }
            return bRet;
        }

        /** @brief: Get string from a file.
        *   @return: a pointer which needs to be deleted manually by 'delete[]' .
        */
        static char* stringWithContentsOfFile(const char* pszFileName)
        {
            unsigned long size = 0;
            unsigned char* pData = 0;
            char* pszRet = 0;
            pData = CCFileUtils::getFileData(pszFileName, "rb", &size);
            do 
            {
                CC_BREAK_IF(!pData || size <= 0);
                pszRet = new char[size+1];
                pszRet[size] = '\0';
                memcpy(pszRet, pData, size);
                CC_SAFE_DELETE_ARRAY(pData);
            } while (false);
            return pszRet;
        }

		/***
		* @brief 根据UTF-8字符，转换成GB2312进行存储。
		*
		* @param pszUTF8 要传入的UTF8字符。
		* @return CCString* 返回CCString类的指针
		* @retval 0 空指针即为pszUTF8这个参数是有问题
		* @author (DeNA)郭浩
		* @date 20120731
		*/
		static CCString* stringWithUTF8String(const char* pszUTF8)
		{
			if (0 == pszUTF8 || !*pszUTF8)
			{
				return 0;
			}

			iconv_t pConvert = 0;
			const char* pszInbuffer = pszUTF8;
			char* pszOutBuffer = new char[2048];

			memset(pszOutBuffer,0,sizeof(char) * 2048);

			int nStatus = 0;
			size_t sizOutBuffer = 2048;
			size_t sizInBuffer = strlen(pszUTF8);
			const char* pszInPtr = pszInbuffer;
			size_t sizInSize = sizInBuffer;
			char* pszOutPtr = pszOutBuffer;
			size_t sizOutSize = sizOutBuffer;

			pConvert = iconv_open("GB2312","UTF-8");

			iconv(pConvert,0,0,0,0);

			while (0 < sizInSize)
			{
				size_t sizRes = iconv(pConvert,(const char**)&pszInPtr,
					&sizInSize,&pszOutPtr,&sizOutSize);

				if (pszOutPtr != pszOutBuffer)
				{
					strncpy(pszOutBuffer,pszOutBuffer,sizOutSize);
				}

				if ((size_t)-1 == sizRes)
				{
					int nOne = 1;
					iconvctl(pConvert,ICONV_SET_DISCARD_ILSEQ,&nOne);
				}
			}

			iconv_close(pConvert);

			return new CCString(pszOutBuffer);
		}

		/***
		* @brief 为了符合Objective-C语言上NSString的一些结构，所以对CCString
		*		 进行类NSString化扩展。
		*
		* @param pszFormat 动态参数。
		* @return CCString* 返回CCString类的指针
		* @retval 0 空指针即为动态参数中有空值
		* @author (DeNA)郭浩
		* @date 20120731
		* @warning 一定要析构掉获得的指针，否则会造成内存泄露
		*/
		static CCString* stringWithFormat(const char* pszFormat,...)
		{
			char szBuf[255] = {0};
			va_list kAp = 0;

			va_start(kAp, pszFormat);
			vsnprintf_s(szBuf, 255, 255, pszFormat, kAp);
			va_end(kAp);

			if (!*szBuf)
			{
				return 0;
			}

			CCString* pstrString = new CCString(szBuf);

			return pstrString;
		}
	};
}// namespace cocos2d
#endif //__CCSTRING_H__