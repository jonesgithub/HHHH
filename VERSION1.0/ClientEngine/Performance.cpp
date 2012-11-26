/*
 *  Performance.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-10-11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "Performance.h"

using namespace NDPerformance;

#define CHECK_KEY(key)					\
		do{								\
		if (key == invalid_key)			\
		return false;					\
		}while(0)

#define CHECK_START						\
		do{								\
		if (!IsStart())					\
		return false;					\
		}while(0)

CPerformanceTest::CPerformanceTest()
{
	m_bStartFrameTest = false;
	m_spKeyMain = CREATE_CLASS(NDBaseGlobalDialog,"CIDFactory");
	m_spKeyHelp = CREATE_CLASS(NDBaseGlobalDialog,"CIDFactory");
	m_bStart = false;
}

CPerformanceTest::~CPerformanceTest()
{

}

/** ��ʱͳ�ƽӿڿ�ʼ*/
bool CPerformanceTest::StartFrame()
{
	CHECK_START;

	m_cacl.clear();
	m_bStartFrameTest = true;

	return true;
}

bool CPerformanceTest::EndFrame()
{
	CHECK_START;

	m_cacl.clear();
	m_bStartFrameTest = false;

	dealPerFrame();

	return true;
}

void CPerformanceTest::LogOutConsole()
{

}

bool CPerformanceTest::Save()
{
	CHECK_START;

	Output();

	Clear();

	return true;
}

bool CPerformanceTest::BeginTestModule(const char *name, key64& key,
		bool flagFrame/*=false*/)
{
	CHECK_START;

	if (!name)
		return false;

	KEY mainKey = GetMainKey(name);

	CHECK_KEY(mainKey);

	KEY helpKey = GetHelpKey();

	CHECK_KEY(helpKey);

	key = key64(mainKey, helpKey);

	NDAsssert(m_mapData.find(key) == m_mapData.end());

	NDAsssert(m_cacl.find(key) == m_cacl.end());

	m_mapData[key].consume = 0;

	m_mapData[key].perframe = flagFrame;

	m_cacl[key].start = time(0);

	return true;
}

bool CPerformanceTest::EndTestModule(key64& key)
{
	CHECK_START;

	if (!key.valid())
		return false;

	std::map<key64, performance_data>::iterator it = m_mapData.find(key);

	if (it == m_mapData.end())
		return false;

	std::map<key64, time_cacl>::iterator itCacl = m_cacl.find(key);

	if (itCacl == m_cacl.end())
		return false;

	double tmp = time(0) - m_cacl[key].start;
	m_mapData[key].consume = tmp;

	m_mapData[key].finish = true;

	return true;
}

/** ��ʱͳ�ƽӿڽ��**/

void CPerformanceTest::Output()
{
// 	NSError *outError;
// 	
// 	NSFileManager *fm = [NSFileManager defaultManager];
// 	
// 	/* Set up reasonable directory attributes */
//     NSDictionary *attributes = [NSDictionary dictionaryWithObject: [NSNumber numberWithUnsignedLong: 0755] forKey: NSFilePosixPermissions];
// 	
// 	NSString *path = [NSString stringWithFormat:@"%@%s", DataFilePath, "Performance"];
//     /* Create the top-level path */
//     if (![fm fileExistsAtPath: path] &&
//         ![fm createDirectoryAtPath: path withIntermediateDirectories: YES attributes: attributes error: &outError])
//     {
//         return;
//     }
// 	
// 	char filename[256];
// 	memset(filename, 0, sizeof(filename));
// 	snprintf(filename, sizeof(filename), "%s/%ld%s", 
// 			 [path UTF8String],
// 			 time(NULL),
// 			 "performance.txt");
// 	
// 	FILE* f = fopen(filename, "a");
// 	
// 	if (f) {
// 		AverageOutput(f);
// 		fclose(f);
// 	}
}

void CPerformanceTest::Output(FILE* f)
{
}

void CPerformanceTest::AverageOutput(FILE* f)
{
	std::map<VALUE, KEY>::iterator it = m_keyCache.begin();

	for (; it != m_keyCache.end(); it++)
	{
		std::map<key64, performance_data>::iterator data_it = m_mapData.begin();

		double total = 0.0f;
		unsigned int count = 0;

		for (; data_it != m_mapData.end(); data_it++)
		{
			key64 key = data_it->first;
			if (key.keyHigh != it->second && data_it->second.finish)
				continue;

			count++;
			total += data_it->second.consume;
		}

		if (count > 0)
		{
			unsigned int milSecond = (unsigned int) ((total * 1000) / count);
			unsigned int uSecond = (unsigned int) ((total * 1000000) / count);
			if (milSecond > 5)
				fprintf(f, "%s average consume: %u���, call time=%u\n",
						it->first.c_str(), milSecond, count);
			else
				fprintf(f, "%s average consume: %u�΢�, call time=%u\n",
						it->first.c_str(), uSecond, count);
		}
	}
}

KEY CPerformanceTest::GetMainKey(VALUE name)
{
	std::map<VALUE, KEY>::iterator it = m_keyCache.find(name);

	if (it == m_keyCache.end())
	{
		KEY key = m_spKeyMain->GetID();
		m_keyCache.insert(std::pair<VALUE, KEY>(name, key));
		return key;
	}

	return it->second;
}

KEY CPerformanceTest::GetHelpKey()
{
	return m_spKeyHelp->GetID();
}

void CPerformanceTest::Clear()
{
	std::map<VALUE, KEY>::iterator it = m_keyCache.begin();

	for (; it != m_keyCache.end(); it++)
	{
		m_spKeyMain->ReturnID(it->second);
	}

	std::map<key64, performance_data>::iterator data_it = m_mapData.begin();
	for (; data_it != m_mapData.end(); data_it++)
	{
		m_spKeyHelp->ReturnID(data_it->first.keyLow);
	}

	m_keyCache.clear();

	m_mapData.clear();
	m_cacl.clear();
}

bool CPerformanceTest::StartPerformanceTest()
{
	m_bStart = true;

	return true;
}

bool CPerformanceTest::EndPerformanceTest()
{
	m_bStart = false;

	return true;
}

bool CPerformanceTest::IsStart()
{
	return m_bStart;
}

bool CPerformanceTest::dealPerFrame()
{
	std::map<VALUE, KEY>::iterator it = m_keyCache.begin();

	std::map < key64, performance_data > dataCache;

	bool hasDataClear = false;

	for (; it != m_keyCache.end(); it++)
	{
		std::map<key64, performance_data>::iterator data_it = m_mapData.begin();

		bool allocKey = false;
		key64 frameKey;

		for (; data_it != m_mapData.end(); data_it++)
		{
			key64 key = data_it->first;
			performance_data& data = data_it->second;
			if (key.keyHigh != it->second && data.finish)
				continue;
			if (!data.perframe)
				continue;

			data.clear = true;
			m_spKeyHelp->ReturnID(key.keyLow);

			if (!allocKey)
			{
				KEY helpKey = GetHelpKey();
				CHECK_KEY(helpKey);
				frameKey = key64(key.keyHigh, helpKey);
				NDAsssert(dataCache.find(frameKey) == dataCache.end());
				dataCache[frameKey].consume = data.consume;
				hasDataClear = true;
				allocKey = true;

				dataCache[frameKey].finish = true;
			}
			else
			{
				NDAsssert(dataCache.find(frameKey) != dataCache.end());
				dataCache[frameKey].consume += data.consume;
			}
		}
	}

	std::map<key64, performance_data>::iterator data_it = m_mapData.begin();

	if (hasDataClear)
	{
		while (data_it != m_mapData.end())
		{
			performance_data& data = data_it->second;
			if (data.clear)
				m_mapData.erase(data_it++);
			else
				data_it++;
		};
	}

	data_it = dataCache.begin();

	for (; data_it != dataCache.end(); data_it++)
	{
		key64 key = data_it->first;
		performance_data& data = data_it->second;
		NDAsssert(m_mapData.find(key) == m_mapData.end());
		m_mapData[key] = data;
	}

	return true;
}

//--------------------------------------------------------------

CPerformanceTestHelper::CPerformanceTestHelper(const char* arg)
{
	if (arg)
	{
		CPerformanceTest::GetSingleton().BeginTestModule(arg, m_key);
	}
}

CPerformanceTestHelper::~CPerformanceTestHelper()
{
	if (m_key.valid())
	{
		CPerformanceTest::GetSingleton().EndTestModule(m_key);
	}

}

//--------------------------------------------------------------

CPerformanceTestFrameHelper::CPerformanceTestFrameHelper(const char* arg)
{
	if (arg)
	{
		std::string str = arg;
		str += " per frame";
		CPerformanceTest::GetSingleton().BeginTestModule(str.c_str(), m_key,
				true);
	}
}

CPerformanceTestFrameHelper::~CPerformanceTestFrameHelper()
{
	if (m_key.valid())
	{
		CPerformanceTest::GetSingleton().EndTestModule(m_key);
	}

}